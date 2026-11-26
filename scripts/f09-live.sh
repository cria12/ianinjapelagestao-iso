#!/bin/bash
# F9 — Sistema live: initramfs (BLFS "About initramfs", estendido) + rootfs SquashFS
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F9)" = ok ] && exit 0
montar_lfs
montar_kernfs > /dev/null
etapa_inicio F9
mkdir -p $P/iso-root/boot/grub $P/iso-root/live

# Documentação dentro da distro (referida no /etc/motd)
mkdir -p $LFS/usr/share/doc/ianinjapelagestao
cat > $LFS/usr/share/doc/ianinjapelagestao/README << "EOF"
ianinjapelagestao 12.4 — distribuição Linux From Scratch 12.4 (System V) + BLFS 12.4

Sistema live: a raiz é um SquashFS só-leitura com uma camada de escrita em RAM
(OverlayFS). Sem disco de dados, tudo o que alterar perde-se ao desligar.

Persistência:  o assistente de 1.º arranque pergunta onde guardar os dados: partição
               nova na própria pen, ficheiro \ianinja\ianinja-dados.img no disco do
               Windows (NTFS/exFAT/FAT/ext4) ou uma partição formatada. O arranque
               usa-o como camada de escrita e tudo fica guardado (incluindo os
               modelos em /var/lib/ia/modelos). Visível em /mnt/dados (o disco que
               guarda o ficheiro: /mnt/dados-disco).
               Na consola: ianinja-persistencia estado | listar | criar <id>
               (partição inteira: sudo ia-criar-persistencia /dev/sdX1).
               Arrancar sem ela: entrada "sem persistência" do GRUB.
Memória/CPU:   swap zram (50 % da RAM, zstd): /etc/rc.d/init.d/zram status
               governador performance + THP madvise: /etc/rc.d/init.d/desempenho status
               memlock ilimitado (llama.cpp --mlock): /etc/security/limits.d/

Utilizadores:  root / ianinja      ninja / ninja (sudo sem senha)
Interface:     Xfce 4.20 + LightDM (nível 5, vt7). Entrar como ninja / ninja no ecrã de
               início de sessão (o root não aparece na lista). Consolas de texto:
               Ctrl+Alt+F1..F6; voltar ao ambiente gráfico: Ctrl+Alt+F7.
               Pesquisa rápida: Super+Espaço. Modo texto: entrada do GRUB "modo texto"
               (ou acrescentar 3 à linha do kernel); já arrancado: sudo telinit 3 / telinit 5.
               Problemas do X: /var/log/Xorg.0.log e /var/log/lightdm/
               Ecrã preto ou sem interface gráfica: entrada do GRUB "modo gráfico de
               compatibilidade" (nomodeset: imagem do firmware, sem aceleração). Se o X
               falhar 3 vezes o sistema volta à consola tty1 com um aviso
               (/var/log/ianinja-dm.log; tentar outra vez: sudo ianinja-dm repor).
Rede:          NetworkManager (cabo automático; Wi-Fi pelo ícone de rede na barra superior)
Wi-Fi (consola): nmtui   ou   ligar-wifi <SSID>   (procurar: ligar-wifi -l; estado: -e)
Som:           alsamixer, aplay -l, speaker-test -c2 (ALSA)
Drivers:       módulos carregados pelo udev (lsmod); firmware em /usr/lib/firmware
               ver o que falta: dmesg | grep -i firmware ; lspci -k ; lsusb
Teclado:       pt-latin1 (mudar: loadkeys us)
Serviços:      /etc/rc.d/init.d/  (ex.: /etc/rc.d/init.d/sshd start)
Editor:        nano
EOF

# Afinação para IA e persistência (scripts/sistema/): instalado no $LFS antes do SquashFS.
# Idempotente: pode correr várias vezes (ficheiros substituídos, blocos marcados, links -sfn).
instalar_sistema() {
  local S=$P/scripts/sistema f s
  install -v -m755 $S/zram       $LFS/etc/rc.d/init.d/zram
  install -v -m755 $S/desempenho $LFS/etc/rc.d/init.d/desempenho
  # rcS: zram depois de mountvirtfs/modules/udev/swap; desempenho depois do sysctl (S90)
  ln -sfnv ../init.d/zram       $LFS/etc/rc.d/rcS.d/S21zram
  ln -sfnv ../init.d/desempenho $LFS/etc/rc.d/rcS.d/S91desempenho
  # paragem/reinício: desligar a zram depois do sendsignals (K92) e antes do swap (K94)
  for s in 0 6; do ln -sfnv ../init.d/zram $LFS/etc/rc.d/rc$s.d/K93zram; done
  [ -f $LFS/etc/sysconfig/zram ] || cat > $LFS/etc/sysconfig/zram << "EOF"
# Configuração da swap zram (/etc/rc.d/init.d/zram)
#ZRAM_PERCENTAGEM=50      # % da RAM
#ZRAM_MAX_MIB=16384       # máximo em MiB
#ZRAM_ALGORITMO=zstd      # lz4 é mais rápido, zstd comprime mais
#ZRAM_PRIORIDADE=100
EOF
  # /etc/sysctl.conf (aplicado pelo S90sysctl do LFS): substitui só o nosso bloco marcado
  f=$LFS/etc/sysctl.conf
  touch $f
  sed -i '/^# >>> ianinjapelagestao-sistema/,/^# <<< ianinjapelagestao-sistema/d' $f
  cat $S/sysctl-ia.conf >> $f
  # limites (memlock para llama.cpp --mlock, nofile/nproc para o ninja)
  install -v -d $LFS/etc/security/limits.d
  install -v -m644 $S/limits-ia.conf $LFS/etc/security/limits.d/90-ianinja-ia.conf
  # pam_limits: login e sshd já o têm; su e sudo não
  for s in login sshd su sudo; do
    f=$LFS/etc/pam.d/$s
    [ -f $f ] || continue
    grep -q 'pam_limits\.so' $f && continue
    if grep -q '^session[[:space:]]*include[[:space:]]*system-session' $f; then
      sed -i -e '/^session[[:space:]]*include[[:space:]]*system-session/i # Set resource limits for the user (ianinjapelagestao: limits.d/90-ianinja-ia.conf)' \
             -e '/^session[[:space:]]*include[[:space:]]*system-session/i session   required    pam_limits.so' \
             -e '/^session[[:space:]]*include[[:space:]]*system-session/i \\' $f
    else
      printf '\n# Set resource limits for the user\nsession   required    pam_limits.so\n' >> $f
    fi
    echo "pam_limits acrescentado a /etc/pam.d/$s"
  done
  install -v -m755 $S/ia-criar-persistencia $LFS/usr/sbin/ia-criar-persistencia
  # gestor de sessões vigiado: se o X/LightDM falhar 3 vezes, volta à tty1 com um aviso
  if [ -f $LFS/etc/inittab ] && grep -q '^dm:5:respawn:' $LFS/etc/inittab; then
    install -v -m755 $S/ianinja-dm $LFS/usr/sbin/ianinja-dm
    sed -i 's|^dm:5:respawn:.*|dm:5:respawn:/usr/sbin/ianinja-dm|' $LFS/etc/inittab
    grep -x 'dm:5:respawn:/usr/sbin/ianinja-dm' $LFS/etc/inittab
  fi
  # diretórios: modelos de IA (persistem sozinhos com IANINJA-DADOS) e ponto de montagem
  mkdir -pv $LFS/var/lib/ia/modelos $LFS/mnt/dados
}
# corre num bash à parte com -e (uma função à esquerda de || correria sem errexit)
P=$P LFS=$LFS bash -euo pipefail -c "$(declare -f instalar_sistema); instalar_sistema" > $P/logs/f9-sistema.log 2>&1 || { etapa_fim F9 falhou "instalação de scripts/sistema (ver logs/f9-sistema.log)"; exit 1; }
decisao "Afinação de memória e CPU em tempo de execução (IA)" \
"Instalado por F9 a partir de scripts/sistema/ (antes do SquashFS, idempotente):
- /etc/rc.d/init.d/zram, ligado como rcS.d/S21zram (depois de mountvirtfs, modules, udev e swap; antes do mountfs) e rc0.d/rc6.d/K93zram (após o sendsignals, antes do swapoff geral): /dev/zram0 com 50 % da RAM até 16 GiB, compressor zstd, swap com prioridade 100. Configurável em /etc/sysconfig/zram. Numa live sem disco é a única swap; mesmo com disco é preferida pela prioridade.
- /etc/sysctl.conf (bloco marcado, aplicado pelo S90sysctl do LFS): vm.swappiness=100 (com zram trocar páginas anónimas frias custa pouco e preserva a page cache onde vive o modelo GGUF lido por mmap); vm.page-cluster=0 (zram não tem custo de procura, read-ahead de swap só gasta CPU); vm.overcommit_memory=1 (o ggml reserva buffers grandes que só usa em parte; com a heurística por omissão podiam falhar com ENOMEM numa máquina com pouca RAM, e o OOM killer continua a proteger o sistema); vm.max_map_count=1048576 (como as distribuições recentes); vm.min_free_kbytes=65536 (reserva para a zram comprimir em picos). kernel.numa_balancing não é definido porque o kernel é compilado sem NUMA_BALANCING (o llama.cpp recomenda-o desligado) e uma chave inexistente faria o sysctl falhar.
- /etc/rc.d/init.d/desempenho (rcS.d/S91, depois do sysctl): governador cpufreq 'performance' em todos os CPUs e EPP 'performance' se o driver for intel_pstate/amd-pstate; THP 'enabled=madvise'. Sem cpufreq (QEMU) não faz nada e não falha.
- /etc/security/limits.d/90-ianinja-ia.conf: memlock ilimitado (llama.cpp --mlock), nofile 65536 e nproc 65536 para o ninja (compilações paralelas); linhas próprias para root porque '*' não se aplica ao root. O pam_limits já estava em /etc/pam.d/login e sshd; foi acrescentado a su e sudo (antes do 'session include system-session').
- /var/lib/ia/modelos existe na imagem; com persistência ligada vive na camada de escrita do disco IANINJA-DADOS e por isso persiste sem mais nada."

# initramfs: construído dentro do chroot para usar os binários/bibliotecas do próprio LFS
cp $P/scripts/live-init.sh $LFS/root/live-init.sh
cat > $LFS/root/mkinitramfs-live.sh << "SCRIPT"
set -e
W=/tmp/initramfs-live
rm -rf $W; mkdir -p $W/usr/{bin,lib} $W/{dev,proc,sys,run,newroot,etc} $W/lib64
ln -s usr/bin $W/bin; ln -s usr/bin $W/sbin; ln -s bin $W/usr/sbin; ln -s usr/lib $W/lib
bins="bash sh mount umount blkid losetup switch_root mkdir sleep seq cat ls grep echo dmesg mknod readlink stty insmod"
for b in $bins; do
  p=$(type -P $b) || { echo "falta $b"; exit 1; }   # type -P: ficheiro no PATH (command -v devolve builtins como echo)
  p=$(readlink -f $p)
  cp -a $p $W/usr/bin/$b
done
# bibliotecas (ldd), incluindo o interpretador dinâmico
for b in $W/usr/bin/*; do
  ldd $b 2>/dev/null | grep -oE '/[^ ]+' | while read -r l; do
    [ -e "$l" ] || continue
    cp -nL "$l" $W/usr/lib/ 2>/dev/null || true
  done
done
ln -sf ../usr/lib/ld-linux-x86-64.so.2 $W/lib64/ld-linux-x86-64.so.2
mknod -m 600 $W/dev/console c 5 1
mknod -m 666 $W/dev/null c 1 3
install -m755 /root/live-init.sh $W/init
touch $W/etc/fstab
# módulos que a persistência pode precisar e que não estão embutidos no kernel (=m): NTFS (ntfs3)
# e exFAT, descomprimidos (os .ko.zst do kmod) para /lib/modules/<nome>.ko; o /init faz insmod
KV=$(ls /lib/modules | head -1)
mkdir -p $W/usr/lib/modules
for m in fs/ntfs3/ntfs3 fs/exfat/exfat; do
  n=${m##*/}
  if grep -q "^CONFIG_${n^^}_FS=y" /boot/config-$KV; then echo "módulo $n embutido no kernel"; continue; fi
  f=/lib/modules/$KV/kernel/$m.ko
  if [ -f $f.zst ]; then zstd -dc $f.zst > $W/usr/lib/modules/$n.ko
  elif [ -f $f.xz ]; then xz -dc $f.xz > $W/usr/lib/modules/$n.ko
  elif [ -f $f ]; then cp $f $W/usr/lib/modules/$n.ko
  else echo "falta o módulo $m (kernel sem $n?)"; exit 1; fi
  echo "módulo $n: $(du -h $W/usr/lib/modules/$n.ko | cut -f1)"
done
( cd $W && find . | cpio -o -H newc --quiet ) | gzip -9 > /boot/initrd.img-live
rm -rf $W
ls -la /boot/initrd.img-live
SCRIPT
# o id do passo depende do /init: se o live-init.sh mudar, o initramfs é refeito
corre_passo f9-initramfs-$(md5sum $P/scripts/live-init.sh | cut -c1-8) $P/logs/f9-initramfs.log in_chroot "bash /root/mkinitramfs-live.sh"
rm -f $LFS/root/mkinitramfs-live.sh

cp -v $LFS/boot/vmlinuz-6.16.1-lfs-12.4 $P/iso-root/boot/vmlinuz
# microcódigo precoce (F8c): cpio não comprimido À FRENTE do initramfs comprimido
if [ -s $LFS/boot/microcode.img ]; then
  cat $LFS/boot/microcode.img $LFS/boot/initrd.img-live > $P/iso-root/boot/initrd.img
  echo "initrd.img = microcode.img ($(du -h $LFS/boot/microcode.img | cut -f1)) + initrd.img-live"
else
  cp -v $LFS/boot/initrd.img-live $P/iso-root/boot/initrd.img
fi
decisao "initramfs live" \
"Baseado no /init do BLFS 'About initramfs' (mkinitramfs), mas com lógica própria para live (scripts/live-init.sh): procura o volume com LABEL=IANINJAPELAGESTAO até 30 s (tentando cada dispositivo devolvido pelo blkid, útil em pens USB onde o disco e a partição têm o mesmo rótulo), monta o ISO9660, o live/rootfs.squashfs por loop e um OverlayFS com camada de escrita em tmpfs; move /run, /dev, /proc e /sys para a nova raiz (o mountvirtfs do LFS deteta-os já montados) e faz switch_root para /sbin/init. Em falha abre um bash de emergência com o motivo. Contém bash, mount, umount, blkid, losetup, switch_root, mkdir, sleep e utilitários mínimos, com as bibliotecas obtidas por ldd dentro do chroot. Todos os drivers necessários estão embutidos no kernel, por isso não leva módulos."

decisao "initramfs: persistência em ficheiro (NTFS/exFAT/FAT/ext4) e na própria pen" \
"Para o assistente de 1.º arranque poder guardar os dados sem formatar nada (scripts/apps/persistencia/CONTRATO.md, bloco 11 da F8e), o /init (scripts/live-init.sh) procura agora, depois do ext4 com o rótulo IANINJA-DADOS, o ficheiro /ianinja/ianinja-dados.img em cada partição NTFS (driver ntfs3), exFAT, FAT ou ext4: monta-a só-leitura para procurar (uma NTFS que o Windows deixou marcada como em uso — hibernação ou arranque rápido — é procurada com ro,force, que é seguro para ler), e se o ficheiro existir monta-a para escrita (nunca com force), liga o ficheiro a um dispositivo loop e monta o ext4 interior como camada de escrita; se a escrita for recusada avisa ('NTFS marcado como em uso: desligue o Windows por completo') e segue em tmpfs. O ntfs3 e o exfat são módulos no kernel 6.16.1 (base Arch: CONFIG_NTFS3_FS=m, CONFIG_EXFAT_FS=m; vfat, ext4 e loop são =y): em vez de recompilar o kernel (F7 e tudo o que se segue), o initramfs passou a levar o insmod (kmod) e os dois módulos descomprimidos (ntfs3 ~0,5 MB, exfat ~0,2 MB), carregados logo no início. Uma pen gravada em modo imagem passa a ser montada através de um dispositivo loop só-leitura sobre o disco inteiro (losetup -r /dev/sda): a montagem direta reclamava o disco em exclusivo e o kernel recusava depois montar qualquer partição do mesmo disco (bd_may_claim), o que impedia a partição IANINJA-DADOS criada a seguir à imagem na própria pen (tipo 'pen' do assistente). A mensagem 'volume encontrado em /dev/sda' continua a indicar o disco real (os testes F11 leem-na); o dispositivo real fica em /run/live/iso-dev e o tipo/dispositivo do disco de dados em /run/live/dados-info (lidos pelo ianinja-persistencia estado). Mensagens: 'persistência: IANINJA-DADOS (/dev/sdb1)' para partições (iguais às de antes) e 'persistência: IANINJA-DADOS (ficheiro ianinja/ianinja-dados.img em /dev/nvme0n1p3)' para o ficheiro; a partição hospedeira fica em /mnt/dados-disco."

decisao "Persistência em pen USB (IANINJA-DADOS)" \
"O /init (scripts/live-init.sh), depois de encontrar a ISO, procura durante até mais 5 s (blkid -t LABEL=IANINJA-DADOS, sem cache) um sistema ext4 com o rótulo IANINJA-DADOS — pode estar noutra pen USB, num cartão SD, num NVMe ou numa partição criada depois do fim da ISO na mesma pen. Se existir, monta-o rw (noatime) e usa <disco>/overlay/upper e <disco>/overlay/work (criados se faltarem) como camada de escrita do OverlayFS em vez do tmpfs; o disco é depois movido para /mnt/dados dentro do sistema. Se não montar (ou o OverlayFS falhar) volta ao tmpfs com um AVISO no ecrã. Escreve sempre 'persistência: IANINJA-DADOS (/dev/xxx)' ou 'persistência: desligada (tmpfs)', antes da mensagem 'raiz overlay pronta'. Desliga-se com persistencia=nao ou semdados na linha do kernel (entrada própria do GRUB). Escolhas: um sistema de ficheiros inteiro com rótulo (e não um ficheiro-imagem dentro da partição FAT/ISO) porque é o mais simples de criar, de reparar (e2fsck) e de montar sem módulos; ext4 porque tem journal (um corte de energia não corrompe a camada de escrita) e suporta tudo o que o OverlayFS exige como upper (xattrs trusted.*, whiteouts). Limitação: a camada de escrita está ligada à versão da ISO; ao trocar de ISO, ficheiros alterados em / continuam a sobrepor-se aos novos. O comando /usr/sbin/ia-criar-persistencia <partição> (só no sistema live, como root) recusa a partição da ISO em execução, o disco inteiro, partições sobrepostas à imagem ISO na mesma pen, partições montadas ou em swap; mostra o lsblk e só formata depois de se escrever SIM."

# Otimizações (bloco 10 da F8e, scripts/apps/decisoes-10.txt): o que não serve num sistema live
# fica fora do SquashFS (só da imagem; o $LFS não muda). exclusoes_live <raiz> <ficheiro> escreve
# um caminho relativo por linha, com os carateres especiais das wildcards escapados, para o -ef.
exclusoes_live() {
  ( cd "$1" && {
    # documentação: fica a da distro (motd), a do lynx (a ajuda do próprio lynx) e as licenças
    find usr/share/doc -mindepth 1 ! -type d ! -path 'usr/share/doc/ianinjapelagestao/*' \
      ! -path 'usr/share/doc/lynx-*' ! -iname 'copying*' ! -iname 'licen[cs]e*' \
      ! -iname 'copyright*' ! -iname 'notice*'
    for d in usr/share/gtk-doc usr/share/info usr/share/clc; do [ -e $d ] && echo $d; done
    # traduções: só pt, pt_PT, pt_BR, en e en_US (mensagens .mo e páginas man traduzidas)
    find usr/share/locale -mindepth 1 -maxdepth 1 -type d ! -name pt ! -name 'pt_*' ! -name en ! -name en_US
    find usr/share/man -mindepth 1 -maxdepth 1 -type d ! -name 'man*' ! -name pt ! -name 'pt_*' ! -name 'pt.*'
    # testes do Python (biblioteca padrão e pacotes)
    find usr/lib -maxdepth 2 -type d -path 'usr/lib/python3.*/test'
    find usr/lib/python3.* -type d \( -path '*/idlelib/idle_test' -o -path '*/site-packages/*' -name tests \) -prune
    # bibliotecas estáticas do LLVM/Clang (o clang, o Mesa e o llvm-config usam a libLLVM.so e
    # a libclang-cpp.so) e do Valgrind (só para compilar ferramentas novas); os .la do libtool
    find usr/lib -maxdepth 1 -type f \( -name 'libLLVM*.a' -o -name 'libclang*.a' -o -name 'liblld*.a' \
      -o -name 'libMLIR*.a' -o -name 'libPolly*.a' \)
    find usr/lib/valgrind -maxdepth 1 -type f -name '*.a' 2>/dev/null
    find usr/lib -name '*.la' \( -type f -o -type l \)
    # cargo-c: só serve com o cargo do /opt/rustc, que já não vai na imagem
    for f in usr/bin/cargo-cbuild usr/bin/cargo-cinstall usr/bin/cargo-ctest usr/bin/cargo-capi; do
      [ -e $f ] && echo $f
    done
    # firmware de hardware que não existe num PC x86-64: SoC ARM da Qualcomm (ficam aic100,
    # qdu100 e sdx*, placas PCIe/M.2), ASIC de switches de rede (Mellanox Spectrum, Marvell
    # Prestera) e NXP DPAA2 (Layerscape ARM). Já vem em .xz: na ISO conta o tamanho inteiro.
    find usr/lib/firmware/qcom -mindepth 1 -maxdepth 1 ! -name aic100 ! -name qdu100 ! -name 'sdx*' 2>/dev/null
    find usr/lib/firmware/mellanox -maxdepth 1 -name 'mlxsw_spectrum*' 2>/dev/null
    for d in usr/lib/firmware/mrvl/prestera usr/lib/firmware/dpaa2; do [ -e $d ] && echo $d; done
    true
  } ) | sed 's/[][\\*? ]/\\&/g' > "$2"
}

# rootfs.squashfs (sem kernfs montados)
squash() {
  desmontar_kernfs
  rm -f $P/iso-root/live/rootfs.squashfs
  rm -f $LFS/root/live-init.sh $LFS/root/.bash_history
  # D-Bus (F8d): o machine-id é gerado em cada arranque pelo bootscript dbus; nunca vai na imagem
  # (seria igual em todas as cópias da ISO). /etc/machine-id deve ser só o symlink para ele.
  rm -fv $LFS/var/lib/dbus/machine-id
  if [ -f $LFS/etc/machine-id ] && [ ! -L $LFS/etc/machine-id ]; then
    rm -fv $LFS/etc/machine-id && ln -sv /var/lib/dbus/machine-id $LFS/etc/machine-id
  fi
  # bloco 10 (otimizações): exclusões só da imagem, numa lista que fica no log
  exclusoes_live $LFS $P/logs/f9-exclusoes.txt || return 1
  echo "exclusões do bloco 10: $(wc -l < $P/logs/f9-exclusoes.txt) caminhos (logs/f9-exclusoes.txt)"
  # restos de execuções do X/LightDM (não deviam existir: nada gráfico corre no chroot)
  # compressão (bloco 10): zstd nível 19 com blocos de 1 MiB em vez de xz com 128 KiB — medido
  # (2026-11-12, mesmo conteúdo): xz 2,31 GB, xz+BCJ x86+1 MiB 2,22 GB, zstd-19+1 MiB 2,29 GB, mas
  # a descompressão do zstd é ~10x mais rápida (914 MiB num núcleo: xz 14-16 s, zstd 1,5 s); o
  # kernel 6.16.1 tem SQUASHFS_ZSTD=y (decisoes-10.txt)
  mksquashfs $LFS $P/iso-root/live/rootfs.squashfs -comp zstd -Xcompression-level 19 -b 1M \
    -noappend -wildcards -ef $P/logs/f9-exclusoes.txt \
    -e sources tools lost+found opt/rustc opt/rustc-* root/.cargo home/*/.cargo 'proc/*' 'sys/*' 'dev/*' 'run/*' 'tmp/*' 'boot/*' \
       'var/lib/dbus/machine-id' 'var/log/Xorg.*' 'var/log/lightdm/*' 'var/lib/xkb/*.xkm' \
       'root/.cache' 'home/*/.cache'
}
# refeito sempre que F9 corre (o conteúdo do $LFS pode ter mudado noutras etapas, ex. F8b)
corre_passo f9-squashfs-$(date +%s) $P/logs/f9-squashfs.log squash
# Interface gráfica (F8d): confirma que a imagem leva o essencial e não leva o machine-id
if [ -x $LFS/usr/bin/lightdm ]; then
  # unsquashfs -l escreve cada caminho com o prefixo squashfs-root
  lista=$(unsquashfs -l $P/iso-root/live/rootfs.squashfs 2>/dev/null | sed -n 's|^squashfs-root/|/|p' || true)
  [ -n "$lista" ] || { etapa_fim F9 falhou "unsquashfs -l de rootfs.squashfs falhou"; exit 1; }
  # LightDM e greeter com --sbindir=/usr/bin (BLFS)
  for f in /usr/bin/lightdm /usr/bin/Xorg /usr/bin/lightdm-gtk-greeter /usr/bin/startxfce4 \
           /usr/share/xsessions/xfce.desktop /usr/share/themes/WhiteSur-Light \
           /var/lib/lightdm/.config/gtk-3.0/gtk.css /etc/lightdm/lightdm-gtk-greeter.conf \
           /etc/rc.d/init.d/xdm /etc/rc.d/init.d/dbus /usr/sbin/ianinja-dm; do
    grep -qxF "$f" <<< "$lista" || { etapa_fim F9 falhou "rootfs.squashfs sem $f (interface gráfica)"; exit 1; }
  done
  if grep -qx '/var/lib/dbus/machine-id' <<< "$lista"; then
    etapa_fim F9 falhou "rootfs.squashfs contém /var/lib/dbus/machine-id"; exit 1
  fi
  unset lista
  registo "F9: rootfs.squashfs com a interface gráfica (LightDM, Xorg, Xfce, WhiteSur) e sem machine-id"
fi
# um ficheiro de uma ISO9660 sem -iso-level 3 tem de ter < 4 GiB: a F10 passa a usar o nível 3
# nesse caso (o kernel monta ficheiros com vários extents); aqui só se regista
sq=$(stat -c %s $P/iso-root/live/rootfs.squashfs)
if [ "$sq" -ge 4294967296 ]; then registo "F9: AVISO rootfs.squashfs com $sq bytes (>= 4 GiB): a F10 usa ISO9660 nível 3"; fi
decisao "Live: Rust e caches do cargo fora do SquashFS" \
"O Rust (/opt/rustc, mais de 1 GB) e as caches do cargo (~/.cargo) só servem para compilar o librsvg e o cargo-c na F8d; nenhum programa da ISO precisa deles em execução (o librsvg é uma biblioteca nativa). Por isso são excluídos do rootfs.squashfs, reduzindo a ISO; o /etc/profile.d/rustc.sh fica, mas só acrescenta ao PATH um diretório inexistente. O LLVM fica, porque o Mesa (llvmpipe, radeonsi) usa a libLLVM em execução."
decisao "Sistema live com interface gráfica" \
"Depois da F8d a imagem live leva o Xorg, o Mesa, o GTK3, o Xfce, o LightDM e o tema, sem mudanças no initramfs: o X não precisa de nada no arranque precoce — os drivers DRM (bochs, virtio-gpu, vmwgfx, i915, amdgpu, nouveau) são módulos carregados pelo udev já na raiz final, o /dev é o devtmpfs movido do initramfs (o udev aplica as permissões de /dev/dri), o Xorg corre como root lançado pelo LightDM, e /run, /tmp (1777) e /var são graváveis no OverlayFS; /tmp/.X11-unix e /tmp/.ICE-unix são criados pelo createfiles. O '3' do GRUB (modo texto) chega ao SysVinit porque o /init passa os seus argumentos ao switch_root. O mksquashfs passa a excluir também var/lib/dbus/machine-id (e antes apaga-o, e troca um /etc/machine-id regular pelo symlink, se aparecer), registos do X/LightDM (var/log/Xorg.*, var/log/lightdm/*), mapas de teclado compilados (var/lib/xkb/*.xkm) e caches de utilizador (root/.cache, home/*/.cache); NÃO exclui /var/lib/lightdm (tem o gtk.css do greeter) nem /var/cache/fontconfig. Depois do mksquashfs, se o LightDM estiver instalado, confirma-se com unsquashfs -l que a imagem tem o LightDM, o Xorg, o greeter, o startxfce4, a sessão xfce.desktop, o tema WhiteSur-Light, o gtk.css do greeter e os bootscripts xdm e dbus, e que não tem o machine-id. Tamanho: o SquashFS não é copiado para a RAM (é lido da ISO por loop), por isso a RAM necessária não cresce com ele; só a camada de escrita vive em tmpfs (até 50 % da RAM, por omissão do tmpfs). O limite de 4 GiB por ficheiro da ISO9660 deixou de fazer falhar a F9: se o rootfs.squashfs chegar a 4 GiB, a F10 gera a ISO com -iso-level 3."
decisao "initramfs: mensagens no ecrã e espera de 60 s" \
"Num PC real o arranque ficava com o ecrã preto: com 'console=tty0 console=ttyS0,115200' a última console= (ttyS0) é o /dev/console, e todas as mensagens do /init (incluindo a FALHA NO ARRANQUE LIVE e a shell de emergência) e dos bootscripts iam para a porta série, invisíveis. A F10 passou a pôr 'console=ttyS0,115200 console=tty0' (o ecrã é o /dev/console). Para os testes F11, que leem a série, o /init (scripts/live-init.sh) escreve agora cada mensagem (função diz) no /dev/console e também nas outras consolas da linha do kernel (lidas de /proc/cmdline; cada uma é preparada com 'stty -F <dev> clocal', que abre com O_NONBLOCK — uma porta série que não exista no PC falha logo e é ignorada, e nunca se fica à espera da portadora; por isso o stty entrou no initramfs). A emergência mostra o motivo, a saída do blkid e sugestões em pt-PT e abre o bash no /dev/console (o ecrã); se a shell sair abre-se outra, em vez de o PID 1 sair (kernel panic). A espera pelo volume IANINJAPELAGESTAO passou de 30 s para 60 s (pens USB lentas, hubs, controladores USB 3 que demoram), com uma mensagem de progresso a cada 5 s. Os drivers de armazenamento não precisam de ir no initramfs: xhci/ehci/ohci/uhci (PCI), usb-storage, uas, sd_mod, sr_mod, nvme, ahci, mmc/sdhci-pci, virtio-blk, loop, isofs, squashfs (xz), overlay, ext4 e vfat estão todos embutidos (=y) no kernel 6.16.1 (confirmado em /boot/config-6.16.1)."

decisao "Interface gráfica vigiada (ianinja-dm)" \
"O inittab passou de 'dm:5:respawn:/etc/rc.d/init.d/xdm' para 'dm:5:respawn:/usr/sbin/ianinja-dm' (scripts/sistema/ianinja-dm, instalado pela F9). Lê o mesmo /etc/sysconfig/xdm e lança o LightDM como processo filho (o pidof lightdm continua a funcionar). Sem logind o LightDM dá ao seat0 exit-on-failure=true e sai quando o X ou o greeter não arrancam; antes, o init relançava-o em ciclo e o ecrã podia ficar preto no vt7. Agora cada saída antes de existirem um servidor X e um greeter (ou uma sessão Xfce) conta como falha (também um 'Fatal server error' no registo do X sem o LightDM sair em 20 s); à 3.ª falha no mesmo arranque o ianinja-dm faz chvt 1, escreve na tty1 um aviso em pt-PT a sugerir a entrada do GRUB 'modo gráfico de compatibilidade', reinicia o agetty da tty1 (--noclear: o pedido de login aparece por baixo do aviso) e fica a dormir para o init não voltar a lançar o LightDM. 'sudo ianinja-dm repor' apaga as falhas e volta a tentar. Registo em /var/log/ianinja-dm.log; estado em /run/ianinja-dm (só dura um arranque). Não há limite de tempo para o X aparecer (em máquinas lentas demora), para nunca matar um arranque lento mas válido. O /etc/rc.d/init.d/xdm do BLFS continua instalado (e verificado na imagem), mas já não é usado pelo inittab."

decisao "initramfs: ISO9660 no disco inteiro (pen USB gravada em modo imagem)" \
"Causa real do arranque falhado num PC (foto do ecrã): numa pen USB gravada com a ISO em modo imagem o blkid via /dev/sda com a tabela de partições híbrida do grub-mkrescue (sda1/sda4 'Gap0/Gap1', sda2 EFI em FAT, sda3 HFS+ com LABEL=IANINJAPELAGESTAO) e não listava /dev/sda com o rótulo; o /init só tentava montar sda3 (HFS+, que o kernel nem suporta) e falhava ao fim de 60 s. O ISO9660 com live/rootfs.squashfs está no disco inteiro. O /init (scripts/live-init.sh, função procurar) tenta agora, em cada ciclo de 0,5 s: 1) cada dispositivo com o rótulo (blkid sem cache, -c /dev/null); 2) se não tiver live/rootfs.squashfs, o disco-pai dessa partição (por /sys/class/block/<part>/.., ex. sda3 -> sda, nvme0n1p3 -> nvme0n1, mmcblk0p2 -> mmcblk0) montado com -t iso9660; 3) por fim todos os discos inteiros (sem ficheiro partition no sysfs, incluindo sr*; excluindo loop, ram, zram, dm e md) com -t iso9660. Tudo só-leitura; um disco que não seja ISO9660 (ex. o NVMe com o Windows) falha logo a montagem e não é alterado. Os drivers precisos estão embutidos no kernel (ISO9660_FS, USB_XHCI_PCI, USB_EHCI_PCI, USB_OHCI_HCD, USB_UHCI_HCD, USB_STORAGE, USB_UAS, BLK_DEV_SD, BLK_DEV_SR, BLK_DEV_NVME, SATA_AHCI, MMC_BLOCK, VIRTIO_BLK, SQUASHFS_XZ, OVERLAY_FS = y), o initramfs não precisa de módulos. Não se mudou o grub-mkrescue para não gerar a partição HFS+: não tem opção para isso e mexer na estrutura híbrida arriscava o arranque BIOS/UEFI que já funciona; a correção no /init cobre todos os casos. A F11 passou a testar a ISO como pen USB e como disco (teste-pen.exp)."

decisao "ianinja-dm: níveis de recurso do Xorg antes de desistir" \
"Pedido: se o Xorg/LightDM falhar, passar sozinho para um modo compatível antes de cair na consola. Com o driver nativo da placa já carregado não é possível voltar ao framebuffer do firmware sem reiniciar (o driver DRM nativo remove o simpledrm ao carregar), por isso o ianinja-dm sobe de nível com configurações do Xorg cada vez mais simples, num ficheiro só seu (/etc/X11/xorg.conf.d/90-ianinja-recurso.conf, apagado no início de cada arranque e com 'ianinja-dm repor'): nível 0 automático (2 tentativas); nível 1 driver modesetting com AccelMethod none (sem glamor/OpenGL — a falha mais comum em placas recentes, ex. NVIDIA com nouveau sem aceleração, ou Mesa sem suporte para a GPU); nível 2+ uma placa de cada vez (Option kmsdev /dev/dri/cardN, primeiro as do firmware — simpledrm, se o driver nativo não chegou a tomar conta — depois as outras; útil em portáteis híbridos), só quando há mais do que uma placa. Antes de lançar o LightDM verifica-se que existe pelo menos uma placa com driver KMS e saídas (/sys/class/drm/cardN com cardN-*; o vgem não conta); se não existir nenhuma (ex. amdgpu que removeu o framebuffer do firmware e depois falhou) desiste logo. Se todos os níveis falharem: consola tty1 com o aviso a sugerir a entrada 'modo gráfico de compatibilidade' do GRUB (nomodeset: aí o simpledrm fica com a imagem do firmware e o Xorg modesetting funciona). 'ianinja-dm estado' mostra nível, placas e registo. Para testes: ianinja-dm.simular-falha=N na linha do kernel faz as N primeiras tentativas usarem um driver do Xorg inexistente (falha real do X). Não foi preciso o xf86-video-fbdev/vesa: o modesetting aceita o simpledrm. NVIDIA recentes: a entrada de compatibilidade é o caminho para chegar ao ambiente gráfico e correr instalar-driver-nvidia (o driver oficial fica ativo depois de reiniciar na entrada normal, o que exige persistência; o nouveau fica na lista negra)."

etapa_fim F9 ok "initrd $(du -h $P/iso-root/boot/initrd.img | cut -f1), rootfs.squashfs $(du -h $P/iso-root/live/rootfs.squashfs | cut -f1)"
