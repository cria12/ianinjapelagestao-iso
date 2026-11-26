#!/bin/bash
# F8c — Drivers e firmware: linux-firmware (comprimido em .xz, deduplicado), base de dados
# regulamentar do Wi-Fi (wireless-regdb), microcódigo Intel/AMD para carregamento precoce,
# e o espaço de utilizador para os drivers: libnl + wpa_supplicant + iw (Wi-Fi), alsa-lib +
# alsa-utils (som) — páginas do BLFS 12.4 — mais o comando ligar-wifi.
# Os módulos do kernel são compilados e instalados na F7 (configuração base do Arch Linux).
# Downloads fora do livro: no host, para $LFS/sources, verificados por SHA-256 fixado aqui.
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
estado_init
[ "$(etapa_estado F8c)" = ok ] && exit 0
montar_lfs
montar_kernfs > /dev/null
etapa_inicio F8c

S=$P/scripts
BLFS=$P/book/blfs
FETCH="python3 $S/blfs-fetch.py"
KV=6.16.1

# --- versões fixadas (SHA-256 dos sha256sums.asc assinados do kernel.org / calculado no download)
FW_VER=20261019
FW_TB=linux-firmware-$FW_VER.tar.xz
FW_URL=https://cdn.kernel.org/pub/linux/kernel/firmware/$FW_TB
FW_SHA256=a10d1ab5baf2c74ba92e8c7cf313e691696c26bddfa6df00db795e48d70cd4ca
REGDB_VER=2026.09.03
REGDB_TB=wireless-regdb-$REGDB_VER.tar.xz
REGDB_URL=https://cdn.kernel.org/pub/software/network/wireless-regdb/$REGDB_TB
REGDB_SHA256=b22e0901227b820cd1c280abe681a15b773a5103a5e10dc442e94ebb34cbf58d
UCODE_VER=20260925
UCODE_TB=intel-microcode-$UCODE_VER.tar.gz
UCODE_URL=https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/archive/refs/tags/microcode-$UCODE_VER.tar.gz
UCODE_SHA256=0ec19023dad1e6dd0c5909174b8dff2555b91cf01671e36271a1ef36655c0cfc
# alsa-ucm-conf: "Additional download" da página alsa-lib, sem MD5 no livro
UCM_TB=alsa-ucm-conf-1.2.14.tar.bz2
UCM_URL=https://www.alsa-project.org/files/pub/lib/$UCM_TB
UCM_SHA256=32e9809f592d92b978aa1032e35293c33b8d0f1ec475f937022c3ee9a3069c21

BS_DIR=blfs-bootscripts-20250225
TMPFW=$P/tmp-firmware          # árvore extraída do linux-firmware (no disco do host, fora do $LFS)

PAGINAS=(basicnet/libnl basicnet/wpa_supplicant basicnet/iw multimedia/alsa-lib multimedia/alsa-utils)
python3 $S/gen-scripts.py blfs $BLFS "${PAGINAS[@]}" > /dev/null
for p in "${PAGINAS[@]}"; do
  mkdir -p $LFS/sources/ianinja/gen/blfs/$(dirname $p)
  cp $S/gen/blfs/$p.sh $LFS/sources/ianinja/gen/blfs/$p.sh
done
cp $S/run-blfs.sh $LFS/sources/ianinja/
chmod -R a+rX $LFS/sources/ianinja

# --- funções (correm dentro de corre_passo: errexit não se aplica, por isso || return 1)

pacote() {
  local page=$1 tb; shift
  $FETCH fetch $BLFS $LFS/sources "$page" "$@" || return 1
  tb=$($FETCH tarball $BLFS "$page") || return 1
  in_chroot "bash /sources/ianinja/run-blfs.sh $page $tb"
}

# baixar <url> <ficheiro em $LFS/sources> <sha256> — reutiliza se já existir com a soma certa
baixar() {
  local url=$1 f=$LFS/sources/$2 sha=$3
  if [ -f "$f" ] && echo "$sha  $f" | sha256sum -c --status; then
    echo "já descarregado e verificado: $f"; return 0
  fi
  rm -f "$f"
  wget -nv --tries=3 -c -O "$f.part" "$url" || return 1
  echo "$sha  $f.part" | sha256sum -c || { echo "SHA-256 errado em $f.part (apagado)"; rm -f "$f.part"; return 1; }
  mv -v "$f.part" "$f"
}

fontes() {
  baixar $FW_URL $FW_TB $FW_SHA256 || return 1
  baixar $REGDB_URL $REGDB_TB $REGDB_SHA256 || return 1
  baixar $UCODE_URL $UCODE_TB $UCODE_SHA256 || return 1
  baixar $UCM_URL $UCM_TB $UCM_SHA256 || return 1
}

# Ferramentas do host usadas pelo "make install-xz"/"make dedup" do linux-firmware:
# rdfind (deduplicação, não existe no LFS/BLFS) e GNU parallel (compressão em paralelo).
host_ferramentas() {
  if ! type -P rdfind > /dev/null || ! type -P parallel > /dev/null || ! type -P cpio > /dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q rdfind parallel cpio || return 1
  fi
  rdfind -h > /dev/null 2>&1 || true
  type -P rdfind && type -P parallel && type -P xz && type -P cpio
}

# linux-firmware -> $LFS/usr/lib/firmware: ficheiros comprimidos com xz (o kernel tem
# FW_LOADER_COMPRESS_XZ), links do WHENCE e duplicados substituídos por links (make dedup).
# Executado no host (o rdfind não existe no LFS); a árvore extraída fica para o microcódigo AMD.
firmware() {
  local D=$LFS/usr/lib/firmware
  rm -rf $TMPFW && mkdir -p $TMPFW || return 1
  tar -C $TMPFW -xf $LFS/sources/$FW_TB || return 1
  rm -rf $D && install -d -m755 $D || return 1
  ( cd $TMPFW/linux-firmware-$FW_VER &&
    make -j$(nproc) DESTDIR=$LFS FIRMWAREDIR=/usr/lib/firmware install-xz &&
    make DESTDIR=$LFS FIRMWAREDIR=/usr/lib/firmware dedup ) || return 1
  # base de dados regulamentar do Wi-Fi (o cfg80211 do kernel valida a assinatura .p7s)
  tar -C $TMPFW -xf $LFS/sources/$REGDB_TB || return 1
  install -v -m644 $TMPFW/wireless-regdb-$REGDB_VER/regulatory.db \
                   $TMPFW/wireless-regdb-$REGDB_VER/regulatory.db.p7s $D/ || return 1
  install -v -d -m755 $LFS/usr/share/doc/linux-firmware-$FW_VER || return 1
  install -v -m644 $TMPFW/linux-firmware-$FW_VER/WHENCE $LFS/usr/share/doc/linux-firmware-$FW_VER/ || return 1
  cp -rv $TMPFW/linux-firmware-$FW_VER/LICEN[CS]E* $LFS/usr/share/doc/linux-firmware-$FW_VER/ || return 1
  chown -R root:root $D || return 1
  echo "FIRMWARE_FICHEIROS:$(find $D -type f | wc -l)"
  echo "FIRMWARE_LINKS:$(find $D -type l | wc -l)"
  echo "FIRMWARE_TAMANHO:$(du -sh $D | cut -f1)"
}

# Microcódigo para carregamento precoce (early): um cpio NÃO comprimido com
# kernel/x86/microcode/{GenuineIntel,AuthenticAMD}.bin, posto à frente do initramfs pela F9
# (BLFS "About Firmware" > Microcode updates). Fica em /boot (fora do SquashFS).
microcodigo() {
  local W=$TMPFW/ucode-cpio U
  rm -rf $W $TMPFW/intel && mkdir -p $W/kernel/x86/microcode $TMPFW/intel || return 1
  tar -C $TMPFW/intel -xf $LFS/sources/$UCODE_TB || return 1
  U=$(ls -d $TMPFW/intel/*/intel-ucode | head -1)
  [ -d "$U" ] || return 1
  cat $U/* > $W/kernel/x86/microcode/GenuineIntel.bin || return 1
  [ -d $TMPFW/linux-firmware-$FW_VER/amd-ucode ] || tar -C $TMPFW -xf $LFS/sources/$FW_TB linux-firmware-$FW_VER/amd-ucode || return 1
  cat $TMPFW/linux-firmware-$FW_VER/amd-ucode/microcode_amd*.bin > $W/kernel/x86/microcode/AuthenticAMD.bin || return 1
  ls -la $W/kernel/x86/microcode
  ( cd $W && find . | LC_ALL=C sort | cpio -o -H newc -R 0:0 --quiet ) > $LFS/boot/microcode.img || return 1
  ls -la $LFS/boot/microcode.img
  rm -rf $W $TMPFW/intel
}

limpar_tmp() { rm -rf $TMPFW; }

bootscripts() {
  in_chroot "set -e; cd /sources; rm -rf $BS_DIR; tar -xf $BS_DIR.tar.xz; test -f $BS_DIR/Makefile"
}

ligar_wifi() {
  install -v -m755 $S/sistema/ligar-wifi $LFS/usr/bin/ligar-wifi || return 1
  in_chroot "bash -n /usr/bin/ligar-wifi"
}

limpeza() {
  in_chroot "rm -rf /sources/$BS_DIR"
}

verificacao() {
  in_chroot 'set -e
falha() { echo "FALTA: $*"; exit 1; }
for c in wpa_supplicant wpa_cli wpa_passphrase iw aplay arecord amixer alsamixer alsactl speaker-test ligar-wifi lspci lsusb modprobe modinfo; do
  p=$(type -P $c) || falha "programa $c"
  printf "%-15s %s\n" "$c" "$p"
done
for f in /lib/services/wpa /etc/sysconfig/ifconfig.wlan0 /etc/rc.d/init.d/alsa /etc/rc.d/rcS.d/S60alsa \
         /usr/lib/libnl-3.so /usr/lib/libasound.so /usr/share/alsa/ucm2 \
         /usr/lib/firmware/regulatory.db /usr/lib/firmware/regulatory.db.p7s /boot/microcode.img \
         /lib/modules/'$KV'/modules.dep /lib/modules/'$KV'/modules.alias; do
  test -e $f || falha "$f"
  echo "ok $f"
done
grep -q "^ONBOOT=\"no\"" /etc/sysconfig/ifconfig.wlan0 || falha "ifconfig.wlan0 devia ter ONBOOT=no"
grep -q "^SERVICE=\"wpa\"" /etc/sysconfig/ifconfig.wlan0 || falha "ifconfig.wlan0 com SERVICE=wpa"
wpa_passphrase teste senha-de-teste | grep -q "psk=" || falha "wpa_passphrase"
iw --version
aplay --version
echo "módulos: $(find /lib/modules/'$KV'/kernel -name "*.ko.zst" | wc -l) (.ko.zst)"
for m in snd_hda_intel iwlwifi e1000e ath9k rtw88_pci amdgpu i915 nouveau btusb vboxguest vboxsf vmwgfx virtio_gpu hv_netvsc; do
  modinfo -k '$KV' -F filename $m > /dev/null 2>&1 || falha "módulo $m"
done
echo "modinfo: snd_hda_intel iwlwifi e1000e ath9k rtw88_pci amdgpu i915 nouveau btusb vboxguest vboxsf vmwgfx virtio_gpu hv_netvsc ok"
# o firmware pedido por alguns módulos existe (comprimido .xz)
for m in iwlwifi amdgpu i915; do
  fw=$(modinfo -k '$KV' -F firmware $m | head -50)
  n=0; ok=0
  for f in $fw; do n=$((n+1)); { [ -e /usr/lib/firmware/$f.xz ] || [ -e /usr/lib/firmware/$f ]; } && ok=$((ok+1)); done
  echo "firmware $m: $ok/$n dos primeiros ficheiros presentes"
  [ $ok -gt 0 ] || falha "firmware de $m"
done
echo "firmware: $(find /usr/lib/firmware -type f | wc -l) ficheiros, $(du -sh /usr/lib/firmware | cut -f1)"
modprobe -n -v -S '$KV' snd_hda_intel | tail -3'
}

# nome|sufixo do id (versão/soma: muda -> passo refeito)|comando ; log: logs/f8c-<nome>.log
PASSOS=(
  "fontes||fontes"
  "host-ferramentas||host_ferramentas"
  "firmware|$FW_VER-$REGDB_VER|firmware"
  "microcodigo|$UCODE_VER|microcodigo"
  "limpar-tmp||limpar_tmp"
  "bootscripts||bootscripts"
  "libnl||pacote basicnet/libnl"
  "wpa_supplicant||pacote basicnet/wpa_supplicant"
  "iw||pacote basicnet/iw"
  "alsa-lib||pacote multimedia/alsa-lib"
  "alsa-utils||pacote multimedia/alsa-utils"
  "ligar-wifi|$(md5sum $S/sistema/ligar-wifi | cut -c1-8)|ligar_wifi"
  "limpeza||limpeza"
  "verificacao|$(date +%s)|verificacao"
)
TOTAL=${#PASSOS[@]}
n=0
for linha in "${PASSOS[@]}"; do
  n=$((n+1))
  IFS='|' read -r nome suf resto <<< "$linha"
  read -r -a cmd <<< "$resto"
  corre_passo "f8c-$nome${suf:+-$suf}" "$P/logs/f8c-$nome.log" "${cmd[@]}" \
    || { etapa_fim F8c falhou "falhou em $nome ($n/$TOTAL) — ver logs/f8c-$nome.log"; exit 1; }
  etapa_nota F8c "$n/$TOTAL — último: $nome"
done

fwn=$(grep '^FIRMWARE_FICHEIROS:' $P/logs/f8c-firmware.log | tail -1 | cut -d: -f2 || true)
fwt=$(grep '^FIRMWARE_TAMANHO:' $P/logs/f8c-firmware.log | tail -1 | cut -d: -f2 || true)
uct=$(du -h $LFS/boot/microcode.img | cut -f1)

# --- Decisões
decisao "Drivers: nova etapa F8c (firmware e espaço de utilizador)" \
"O firmware e os programas que tornam os drivers utilizáveis ficaram numa etapa própria, F8c 'Drivers e firmware' (scripts/f08c-drivers.sh, a seguir à F8b e antes da F9), em vez de irem para a F7: assim mudar o firmware ou os pacotes não obriga a recompilar o kernel (cerca de uma hora) e vice-versa. Os módulos do kernel continuam a ser compilados e instalados na F7. A etapa foi acrescentada a ETAPA_IDS em scripts/lib.sh com o mesmo mecanismo da F8b (script_etapa: F8c -> f08c-*.sh). Como nas outras etapas, os passos são idempotentes (progresso.json); os ids dos passos de firmware e microcódigo incluem a versão, para serem refeitos quando a versão fixada mudar."
decisao "Firmware: linux-firmware $FW_VER em .xz, deduplicado" \
"Instalado o linux-firmware $FW_VER completo (tarball oficial $FW_URL, SHA-256 $FW_SHA256 tirado do sha256sums.asc assinado do kernel.org e verificado pelo script) em /usr/lib/firmware, com o próprio Makefile do pacote: 'make install-xz' (copy-firmware.sh segundo o WHENCE, cada ficheiro comprimido com xz --check=crc32, links do WHENCE criados) seguido de 'make dedup' (ficheiros iguais substituídos por links simbólicos). A instalação corre no host com DESTDIR=\$LFS e FIRMWAREDIR=/usr/lib/firmware porque o dedup exige o rdfind, que não existe no LFS nem no BLFS (instalado no host Ubuntu por apt, com o GNU parallel para comprimir em paralelo); o resultado são só ficheiros de dados, sem binários do host. Compressão: o kernel tem FW_LOADER_COMPRESS_XZ e _ZSTD; escolheu-se xz porque o firmware é lido raramente (uma vez por dispositivo) e o xz dá ficheiros mais pequenos do que o zstd, o que reduz a ISO; o SquashFS (também xz) quase não volta a comprimir ficheiros já comprimidos. Instala-se tudo, como as distribuições generalistas, porque não se sabe em que hardware a ISO vai arrancar (Wi-Fi Intel/Realtek/MediaTek/Atheros/Broadcom, GPUs AMD/Intel/NVIDIA, Bluetooth, áudio SOF, etc.). Resultado: ${fwn:-?} ficheiros, ${fwt:-?}. WHENCE e licenças em /usr/share/doc/linux-firmware-$FW_VER. A página 'About Firmware' do BLFS sugere instalar só os ficheiros necessários a uma máquina concreta — desvio justificado por ser uma ISO para qualquer máquina."
decisao "Firmware: wireless-regdb $REGDB_VER" \
"Os drivers Wi-Fi (cfg80211) leem a base de dados regulamentar (canais e potências permitidos por país) de /usr/lib/firmware/regulatory.db; sem ela o kernel fica no domínio 'world' (00), mais restritivo, e regista erros. O BLFS 12.4 não tem página para o wireless-regdb, por isso usou-se o tarball oficial $REGDB_URL (SHA-256 $REGDB_SHA256, do sha256sums.asc do kernel.org) e instalaram-se só regulatory.db e regulatory.db.p7s (a assinatura que o kernel valida com a chave embutida, CFG80211_REQUIRE_SIGNED_REGDB + CFG80211_USE_KERNEL_REGDB_KEYS da configuração do Arch). O país define-se em tempo de execução com 'iw reg set PT'."
decisao "Firmware: microcódigo Intel e AMD (carregamento precoce)" \
"Incluído microcódigo de CPU para carregamento precoce, como descrito no BLFS ('About Firmware' > Microcode updates): GenuineIntel.bin = concatenação de intel-ucode/* do microcode-$UCODE_VER da Intel ($UCODE_URL, SHA-256 $UCODE_SHA256 calculado no download, o GitHub não publica somas) e AuthenticAMD.bin = concatenação de amd-ucode/microcode_amd*.bin do linux-firmware $FW_VER, num cpio não comprimido (kernel/x86/microcode/) em /boot/microcode.img ($uct). A F9 põe esse cpio à frente do initramfs (o kernel lê-o antes de descomprimir o resto), por isso o grub.cfg não muda. O carregamento tardio (depois do arranque) está desativado no kernel 6.16 por omissão e não é usado. Em máquinas virtuais o kernel ignora o microcódigo. Os ficheiros intel-ucode/ não são copiados para /usr/lib/firmware (só serviriam ao carregamento tardio)."
decisao "Drivers: carregamento automático de módulos pelo udev" \
"Confirmado que não é preciso nada de novo para os módulos serem carregados: o bootscript udev do LFS (rcS.d/S10udev) arranca o udevd e faz 'udevadm trigger --action=add' (subsistemas e dispositivos) + 'udevadm settle'; as regras 80-drivers.rules do udev do LFS correm 'kmod load' com o MODALIAS de cada dispositivo, e o modules.alias é gerado pelo depmod na F7. O S50udev_retry repete os eventos que falharam antes de o / estar montado. O bootscript network (rc3.d) só corre depois disto, por isso placas de rede cujo driver é módulo já existem quando o ifup corre (de qualquer modo, E1000/E1000E/R8169/VIRTIO_NET estão embutidos). O /etc/sysconfig/modules (S05modules) fica vazio: não há módulos a forçar. O firmware é pedido pelos drivers através do carregador do kernel diretamente de /usr/lib/firmware (não é preciso udev para isso)."
decisao "Wi-Fi: libnl, wpa_supplicant, iw e ligar-wifi" \
"Do BLFS 12.4: libnl-3.11.0 (dependência obrigatória do iw e recomendada do wpa_supplicant, para o driver nl80211), wpa_supplicant-2.11 e iw-6.9 (URLs e MD5 do livro). O wpa_supplicant usa o .config do livro (nl80211 + wext, WPA/WPA2/WPA3-pessoal, EAP, WPS, readline) sem a interface D-Bus (bloco 2 e ficheiros D-Bus omitidos: não há D-Bus nem NetworkManager). A documentação da libnl (download adicional) foi omitida. O serviço 'wpa' do blfs-bootscripts (make install-service-wpa) foi instalado e criado /etc/sysconfig/ifconfig.wlan0 segundo o modelo do livro (SERVICE=\"wpa\", WPA_SERVICE=\"dhcpcd\", DHCP_START=\"-b -q -h \$HOSTNAME\", DHCP_STOP=\"-k\"), mas com ONBOOT=\"no\": a ISO não conhece nenhuma rede e um ifup falhado no arranque só atrasaria e mostraria FAIL. Novo comando /usr/bin/ligar-wifi <SSID> [interface] (pt-PT, passa a root com sudo): pede a senha sem eco (Enter vazio = rede aberta), escreve com wpa_passphrase o ficheiro que o serviço 'wpa' do BLFS lê — /etc/sysconfig/wpa_supplicant-wlan0.conf (modo 600, sem a senha em claro) — e faz ifdown/ifup wlan0 (wpa_supplicant + dhcpcd), esperando até 30 s pelo IP; 'ligar-wifi -l' procura redes (iw scan) e 'ligar-wifi -d' desliga. Nota: pedia-se /etc/wpa_supplicant-wlan0.conf, mas o serviço do BLFS procura /etc/sysconfig/wpa_supplicant-<ifconfig>.conf; usou-se esse caminho para 'ifup wlan0' (e ONBOOT=yes) funcionarem sem alterar o serviço. Antes de ligar faz 'rfkill unblock wifi' (rfkill do util-linux). Com persistência (IANINJA-DADOS) a configuração fica guardada; pondo ONBOOT=\"yes\" em ifconfig.wlan0 liga-se sozinho no arranque."
decisao "Som: alsa-lib e alsa-utils" \
"Do BLFS 12.4: alsa-lib-1.2.14 (com o alsa-ucm-conf-1.2.14, download adicional da página sem MD5 no livro — SHA-256 $UCM_SHA256 fixado no script —, necessário às placas modernas, p. ex. SOF em portáteis Intel) e alsa-utils-1.2.14 (aplay, arecord, amixer, alsamixer, alsactl, speaker-test). Dependências opcionais não instaladas (Doxygen: blocos de documentação omitidos; libsamplerate, fftw, xmlto). 'alsactl init/store' do livro não podem correr no chroot (não há placa de som). Instalado o bootscript alsa do blfs-bootscripts (rcS.d/S60alsa; K35alsa em 0/1/6) com uma alteração: como numa live o 1.º arranque nunca tem /var/lib/alsa/asound.state, sem estado gravado faz 'alsactl init' (volumes por omissão) em vez de 'restore' (que falharia e mostraria FAIL), e ao desligar só grava o estado se houver placa de som. Os drivers de som são módulos (snd_hda_intel, snd_sof_*, snd_usb_audio, ...) carregados pelo udev."
decisao "Bluetooth: só drivers do kernel" \
"Os drivers de Bluetooth (BT, btusb, btintel, btrtl, ...) existem como módulos e o firmware respetivo está no linux-firmware, mas o espaço de utilizador (BlueZ) não foi instalado: o BlueZ exige D-Bus, GLib e, na prática, um ambiente com serviço de sessão, nada disso existe nesta ISO de consola, e não era um requisito. Os adaptadores são reconhecidos (aparecem em dmesg/lsusb e em /sys/class/bluetooth), mas não há bluetoothctl."

etapa_fim F8c ok "firmware $FW_VER (${fwn:-?} ficheiros, ${fwt:-?}, .xz), regdb $REGDB_VER, microcódigo $uct; libnl, wpa_supplicant, iw, alsa-lib, alsa-utils, ligar-wifi"
