#!/bin/bash
# F7 — Kernel e boot (LFS Cap. 10), adaptado a sistema live
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F7)" = ok ] && exit 0
montar_lfs
montar_kernfs > /dev/null
etapa_inicio F7
KV=6.16.1

# 10.2 fstab para live: a raiz é o overlay montado pelo initramfs (sem entrada para /)
cat > $LFS/etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point    type     options             dump  fsck
#                                                                order
# (sistema live: / é OverlayFS montado pelo initramfs — sem entrada aqui)

proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
EOF
# checkfs não tem sentido num overlay em RAM
find $LFS/etc/rc.d -name 'S*checkfs' -print -delete > $P/logs/10-checkfs.log 2>&1 || true
decisao "fstab e bootscripts para sistema live" \
"O /etc/fstab não tem entrada para / (a raiz é OverlayFS: SquashFS só-leitura + tmpfs, montado pelo initramfs). Foram removidos os links S*checkfs (fsck numa raiz overlay/squashfs não se aplica). O mountfs do LFS faz 'mount -o remount,rw /' — no overlay isso é inofensivo — e 'mount -a -O no_netdev' monta o resto do fstab, por isso não foi alterado."

# Configuração base: a do pacote "linux" do Arch Linux para 6.16.1 (quase todos os drivers em
# módulos), fixada pelo commit da tag 6.16.1.arch1-1 do repositório de empacotamento e por SHA-256.
ARCH_TAG=6.16.1.arch1-1
ARCH_COMMIT=30d51b4fa29e1a76b33d0f563271c016a6c296ae
ARCH_URL=https://gitlab.archlinux.org/archlinux/packaging/packages/linux/-/raw/$ARCH_COMMIT/config
ARCH_SHA256=ae8836206f1518de5c9204d58d74565be8978bb2eda93731373a839e77555433
ARCH_CFG=config-arch-$KV
if ! { [ -f $LFS/sources/$ARCH_CFG ] && echo "$ARCH_SHA256  $LFS/sources/$ARCH_CFG" | sha256sum -c --status; }; then
  rm -f $LFS/sources/$ARCH_CFG
  wget -nv --tries=3 -O $LFS/sources/$ARCH_CFG.part "$ARCH_URL"
  echo "$ARCH_SHA256  $LFS/sources/$ARCH_CFG.part" | sha256sum -c
  mv $LFS/sources/$ARCH_CFG.part $LFS/sources/$ARCH_CFG
fi

# Opções forçadas por cima da base: livro (Cap. 10.3, 3 blocos) + live + drivers + IA
{
  python3 $P/scripts/kconfig-from-book.py $P/book/lfs/12.4/chapter10/kernel.html
  for o in BLK_DEV_INITRD RD_GZIP RD_XZ DEVTMPFS DEVTMPFS_MOUNT TMPFS SQUASHFS SQUASHFS_XZ SQUASHFS_ZSTD \
           OVERLAY_FS ISO9660_FS JOLIET ZISOFS BLK_DEV_LOOP BLK_DEV_SR SCSI BLK_DEV_SD ATA SATA_AHCI ATA_PIIX \
           USB_SUPPORT USB_XHCI_HCD USB_EHCI_HCD USB_OHCI_HCD USB_UHCI_HCD USB_STORAGE USB_HID HID_GENERIC \
           VFAT_FS MSDOS_FS FAT_FS NLS_CODEPAGE_437 NLS_ISO8859_1 NLS_UTF8 EFI EFI_STUB EFI_PARTITION EFIVAR_FS \
           FB_EFI DRM_SIMPLEDRM SYSFB_SIMPLEFB FRAMEBUFFER_CONSOLE \
           SERIAL_8250 SERIAL_8250_CONSOLE VIRTIO VIRTIO_PCI VIRTIO_BLK VIRTIO_NET VIRTIO_CONSOLE SCSI_VIRTIO \
           NETDEVICES ETHERNET E1000 E1000E R8169 PACKET UNIX INET IPV6 EXT4_FS; do
    echo "$o=y"
  done
  # drivers: tudo o que o arranque live precisa embutido, depuração pesada desligada, módulos zstd
  grep -Ev '^[[:space:]]*(#|$)' $P/scripts/sistema/kernel-opcoes-drivers.txt
  # afinação para IA (memória/zram/THP, cpufreq) e suporte a persistência em USB/SD/NVMe
  grep -Ev '^[[:space:]]*(#|$)' $P/scripts/sistema/kernel-opcoes-ia.txt
} > $P/logs/10-kernel-opcoes.txt
# o id do passo depende da lista de opções e da configuração base: se mudarem, o kernel é recompilado
OPC_HASH=$( { cat $P/logs/10-kernel-opcoes.txt; echo "base $ARCH_SHA256"; } | md5sum | cut -c1-8)

kernel() {
  cp $P/logs/10-kernel-opcoes.txt $LFS/root/kernel-opcoes.txt
  in_chroot 'set -e
cd /sources; rm -rf linux-'$KV'; tar -xf linux-'$KV'.tar.xz; cd linux-'$KV'
make mrproper
# base: configuração do Arch Linux (drivers em módulos); opções do Kconfig sem resposta -> omissão
cp -v /sources/'$ARCH_CFG' .config
make olddefconfig
while IFS== read -r o v; do
  case $v in y) scripts/config --enable "$o" ;; n) scripts/config --disable "$o" ;; m) scripts/config --module "$o" ;; esac
done < /root/kernel-opcoes.txt
make olddefconfig
# segunda passagem: opções cujas dependências só ficaram visíveis depois da 1.ª
while IFS== read -r o v; do
  case $v in y) scripts/config --enable "$o" ;; n) scripts/config --disable "$o" ;; esac
done < /root/kernel-opcoes.txt
make olddefconfig
falta=""
while IFS== read -r o v; do
  cur=$(grep -E "^CONFIG_$o=|^# CONFIG_$o is not set" .config || true)
  case $v in
    y) [ "$cur" = "CONFIG_$o=y" ] || falta="$falta $o" ;;
    n) [ -z "$cur" ] || [ "$cur" = "# CONFIG_$o is not set" ] || falta="$falta $o(n)" ;;
  esac
done < /root/kernel-opcoes.txt
echo "OPCOES_EM_FALTA:$falta"
echo "MODULOS_CONFIG:$(grep -c "=m$" .config)"
make
# módulos: despojados de símbolos (INSTALL_MOD_STRIP=1) e comprimidos com zstd (MODULE_COMPRESS_ZSTD)
rm -rf /lib/modules/'$KV'
make INSTALL_MOD_STRIP=1 modules_install
rm -f /lib/modules/'$KV'/build
depmod -a '$KV'
echo "MODULOS_INSTALADOS:$(find /lib/modules/'$KV' -name "*.ko*" | wc -l)"
echo "MODULOS_TAMANHO:$(du -sh /lib/modules/'$KV' | cut -f1)"
mkdir -p /boot
cp -v arch/x86/boot/bzImage /boot/vmlinuz-'$KV'-lfs-12.4
cp -v System.map /boot/System.map-'$KV'
cp -v .config /boot/config-'$KV'
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
cd /sources; rm -rf linux-'$KV'
rm -f /root/kernel-opcoes.txt'
}
corre_passo f7-kernel-$OPC_HASH $P/logs/10-kernel.log kernel
falta=$(grep '^OPCOES_EM_FALTA:' $P/logs/10-kernel.log | tail -1 | cut -d: -f2)
nmod=$(grep '^MODULOS_INSTALADOS:' $P/logs/10-kernel.log | tail -1 | cut -d: -f2)
tmod=$(grep '^MODULOS_TAMANHO:' $P/logs/10-kernel.log | tail -1 | cut -d: -f2)
decisao "Kernel: configuração base do Arch Linux e drivers em módulos" \
"Para a ISO arrancar e funcionar no máximo de hardware real (como a ISO live de uma distribuição generalista), a configuração deixou de partir do 'make defconfig' (que só traz meia dúzia de drivers e nenhum módulo útil) e passou a partir da configuração do pacote 'linux' do Arch Linux para a mesma versão: tag $ARCH_TAG do repositório gitlab.archlinux.org/archlinux/packaging/packages/linux, commit $ARCH_COMMIT, ficheiro 'config' com SHA-256 $ARCH_SHA256 (verificado por scripts/f07-kernel.sh; cópia em \$LFS/sources/$ARCH_CFG). Escolhido em vez de allmodconfig porque é uma configuração mantida e testada em milhões de máquinas x86_64, já sem as opções de teste/depuração que o allmodconfig ativa (KASAN, UBSAN, selftests, drivers de teste), o que daria um kernel mais lento, maior e mais demorado a compilar; e o Arch usa o kernel quase sem patches, pelo que a configuração serve tal e qual ao kernel vanilla 6.16.1 do LFS (as opções que dependem de ferramentas ausentes — Rust, pahole/BTF — são desligadas pelo próprio 'make olddefconfig'). Por cima aplicam-se, por esta ordem e com scripts/config + olddefconfig em duas passagens: as opções do livro (Cap. 10.3), a lista da live, scripts/sistema/kernel-opcoes-drivers.txt e scripts/sistema/kernel-opcoes-ia.txt. kernel-opcoes-drivers.txt: (1) embute (=y) tudo o que o arranque precisa, porque o initramfs não leva módulos — ISO9660/Joliet/zisofs, SquashFS (xz/zstd), OverlayFS, loop, ext4, vfat/msdos + NLS, devtmpfs, AHCI/SATA, PIIX/IDE genérico, disco e CD SCSI, NVMe, virtio (pci/blk/scsi/net/consola), Hyper-V (VMBus, disco storvsc, teclado), VMware PVSCSI, USB xHCI/EHCI/OHCI/UHCI incluindo a parte PCI (só USB_XHCI_HCD=y sem USB_XHCI_PCI=y não vê as portas), usb-storage + UAS, SD/MMC, HID/USB e PS/2, consola série 8250, efifb/simpledrm; (2) desliga a depuração pesada (DEBUG_INFO_NONE, sem DWARF5/BTF, sem IKHEADERS) — compilação muito mais rápida e /lib/modules dezenas de vezes menor; (3) MODULE_SIG=n: sem assinatura de módulos nem chave de assinatura (não há Secure Boot com chaves próprias nesta ISO; o lockdown do Arch continua inativo por omissão); (4) módulos comprimidos com zstd (MODULE_COMPRESS_ZSTD + MODULE_DECOMPRESS): o kmod 34.2 do LFS foi compilado com +ZSTD +XZ (kmod --version) e o zstd descomprime várias vezes mais depressa do que o xz, o que conta no arranque, quando o udev carrega dezenas de módulos; (5) LOCALVERSION_AUTO=n para a versão ser exatamente $KV; (6) PREEMPT/PREEMPT_NONE/PREEMPT_LAZY=n, porque o Arch escolhe PREEMPT (total) e a escolha do projeto é PREEMPT_VOLUNTARY (ver 'Kernel afinado para IA'). Mantêm-se como módulos os drivers convidados de VirtualBox (VBOXGUEST, VBOXSF_FS, DRM_VBOXVIDEO), VMware (DRM_VMWGFX, VMXNET3), virtio-gpu, bochs e Hyper-V (rede/DRM). Os drivers de rede E1000/E1000E/R8169/VIRTIO_NET continuam embutidos (lista da live). Instalação: 'make INSTALL_MOD_STRIP=1 modules_install' no chroot (módulos sem símbolos de depuração) e 'depmod -a $KV'; o link /lib/modules/$KV/build é removido (as fontes são apagadas a seguir). Resultado: ${nmod:-?} módulos, ${tmod:-?} em /lib/modules/$KV. Lista completa de opções forçadas: logs/10-kernel-opcoes.txt; .config final em /boot/config-$KV (fora do SquashFS) e em /proc/config.gz (IKCONFIG). Opções que o Kconfig recusou:${falta:- nenhuma}."
decisao "Configuração do kernel" \
"Em vez do menuconfig interativo do Cap. 10.3: make defconfig (x86_64) + as opções dos 3 blocos de configuração do livro (extraídas automaticamente por scripts/kconfig-from-book.py) + as opções da Secção F7 do prompt, todas embutidas (=y), aplicadas com scripts/config e make olddefconfig (duas passagens). Lista completa: logs/10-kernel-opcoes.txt. Opções que o Kconfig não permitiu ativar (dependências/arquitetura):${falta:- nenhuma}. A documentação do kernel (cp -r Documentation) não foi copiada para poupar espaço na ISO. GRUB não é instalado em disco: a ISO usa o GRUB do grub-mkrescue."
decisao "Kernel afinado para IA no CPU (llama.cpp) e persistência" "Às opções da live juntam-se as de scripts/sistema/kernel-opcoes-ia.txt, todas embutidas (=y):
- ZRAM + ZSMALLOC com backends LZ4 e ZSTD e compressor por omissão zstd (ZRAM_DEF_COMP_ZSTD), mais CRYPTO_LZ4/CRYPTO_ZSTD: swap comprimida em RAM. Um modelo de 1,5-8 B em Q4 ocupa 1-5 GiB; com zram o resto do sistema (e o KV cache em picos) pode ir para swap comprimida (~3:1 com zstd) em vez de o processo ser morto pelo OOM. zstd comprime melhor que lzo-rle/lz4 com custo de CPU aceitável para swap.
- TRANSPARENT_HUGEPAGE com omissão 'madvise' (não 'always'): só quem pede MADV_HUGEPAGE recebe páginas de 2 MiB, evitando o aumento de memória e as pausas de compactação do khugepaged em todo o sistema, que é o que mais pesa numa máquina com pouca RAM a correr um LLM. O llama.cpp/ggml beneficia quando pede huge pages para os buffers grandes; o modo pode ser mudado em /sys/kernel/mm/transparent_hugepage/enabled sem recompilar.
- NUMA=y (já vinha do defconfig) e NUMA_BALANCING=n: o balanceamento automático migra páginas entre nós e o próprio llama.cpp avisa para o desligar quando se usa --numa; em máquinas de 1 nó não faz nada.
- CPU_FREQ com governador por omissão 'performance' (o defconfig escolhia 'userspace'); schedutil, powersave e ondemand ficam disponíveis; drivers X86_INTEL_PSTATE, X86_AMD_PSTATE e X86_ACPI_CPUFREQ. A inferência é limitada pela largura de banda de memória e pela frequência sustentada: 'performance' evita a latência de subida de frequência entre tokens.
- Preempção: mantém-se PREEMPT_VOLUNTARY do defconfig (com PREEMPT_DYNAMIC pode mudar-se no arranque com preempt=full/none). É o compromisso de débito/latência usado pelas distribuições genéricas; o trabalho de um LLM é cálculo contínuo em vários threads e não ganha com preempção total.
- HZ=1000 (o do defconfig): o custo do tick em núcleos ocupados é desprezável (<0,1 %) e dá melhor granularidade ao escalonador numa máquina interativa (chat), como faz o Ubuntu desde 24.04.
- Persistência: EXT4_FS (já estava), USB_STORAGE + USB_UAS, MMC/SDHCI (PCI, ACPI) e leitores Realtek PCI (MISC_RTSX_PCI/MMC_REALTEK_PCI), NVMe (+ VMD da Intel, usado por portáteis recentes), VFAT com NLS_CODEPAGE_437/ISO8859_1/UTF8 — tudo embutido para o initramfs (sem módulos) encontrar a partição IANINJA-DADOS em pens USB, cartões SD ou discos NVMe.
- Correções: a opção pedida como NLS_CP437 chama-se NLS_CODEPAGE_437 no Kconfig; FB_EFI depende de FB=y, que o defconfig não ativa, por isso FB=y passou a constar da lista.
O id do passo F7 inclui o md5 da lista de opções, para o kernel ser recompilado sempre que a lista mudar.
Opções que o Kconfig recusou nesta compilação:${falta:- nenhuma}."
if [ -n "$falta" ]; then
  etapa_fim F7 aviso "kernel $KV (base Arch $ARCH_TAG), ${nmod:-?} módulos; opções não ativadas: $falta"
else
  etapa_fim F7 ok "kernel $KV (base Arch $ARCH_TAG) com todas as opções pedidas; ${nmod:-?} módulos (${tmod:-?}); fstab live"
fi
