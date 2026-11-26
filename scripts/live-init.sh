#!/bin/bash
# /init do initramfs live do ianinjapelagestao
# Baseado no init.in do BLFS "About initramfs", estendido para: ISO -> SquashFS -> OverlayFS em tmpfs,
# ou, se existir um disco de dados IANINJA-DADOS, OverlayFS persistente nesse disco. O disco de dados
# é um ext4 com o rótulo IANINJA-DADOS (partição noutra pen/disco, ou criada a seguir à imagem na
# própria pen) ou o ficheiro /ianinja/ianinja-dados.img (ext4 lá dentro) numa partição NTFS, exFAT,
# FAT ou ext4 já existente (ex.: o disco do Windows). Ver scripts/apps/persistencia/CONTRATO.md.
PATH=/usr/bin:/usr/sbin
export PATH
LABEL=IANINJAPELAGESTAO
DADOS=IANINJA-DADOS
IMG=ianinja/ianinja-dados.img

mount -n -t proc     proc     /proc
mount -n -t sysfs    sysfs    /sys
mount -n -t devtmpfs devtmpfs /dev
mount -n -t tmpfs -o mode=0755,nosuid,nodev tmpfs /run

quiet=0
grep -qw quiet /proc/cmdline && quiet=1
[ $quiet = 1 ] && echo 3 > /proc/sys/kernel/printk
# Consolas: o /dev/console do kernel é a ÚLTIMA console= da linha do kernel (no GRUB: tty0, o
# ecrã). As mensagens do /init vão para o /dev/console e também para as outras consolas indicadas
# (ex.: ttyS0, lida pelos testes F11), para não haver falhas invisíveis num PC real nem nos testes.
ultima=""; outras=""
for a in $(cat /proc/cmdline); do
  case $a in
    console=*) c=${a#console=}; c=${c%%,*}; [ -n "$ultima" ] && outras="$outras $ultima"; ultima=$c ;;
  esac
done
consolas=""
for c in $outras; do
  [ "$c" = "$ultima" ] && continue
  [ -c "/dev/$c" ] || continue
  # o stty -F abre com O_NONBLOCK: uma porta série inexistente falha logo (EIO) e é ignorada;
  # clocal faz as escritas seguintes não esperarem pela portadora (DCD)
  stty -F "/dev/$c" clocal 2>/dev/null || continue
  consolas="$consolas /dev/$c"
done
diz() {
  echo "$*"
  for c in $consolas; do echo "$*" > "$c" 2>/dev/null; done
}
msg() { diz "[ianinja-live] $*"; }

emergencia() {
  diz ""
  diz "################################################################"
  diz "  ianinjapelagestao: FALHA NO ARRANQUE LIVE"
  diz "  Motivo: $*"
  diz "  Dispositivos de blocos vistos pelo kernel (blkid):"
  blkid 2>/dev/null | while read -r l; do diz "    $l"; done
  diz "  Sugestões: use outra porta USB (de preferência na traseira do PC),"
  diz "  confirme que a pen foi gravada em modo imagem (dd, ou Rufus em modo DD)"
  diz "  ou escolha no menu do GRUB o modo seguro/verbose."
  diz "  A abrir shell de emergência (bash) neste ecrã. Ver: ls /dev ; blkid ; dmesg"
  diz "################################################################"
  # sem exec: se a shell sair abre-se outra (o /init é o PID 1; sair seria um kernel panic)
  while true; do
    /usr/bin/bash -i < /dev/console > /dev/console 2>&1
    echo "(a reabrir a shell de emergência)" > /dev/console
  done
}

# Módulos do kernel que não estão embutidos e que a persistência pode precisar (NTFS: ntfs3; exFAT).
# Copiados pela F9 (scripts/f09-live.sh) já descomprimidos; se faltarem, só esses tipos ficam de fora.
for m in /lib/modules/*.ko; do
  [ -f "$m" ] || continue
  insmod "$m" 2>/dev/null || msg "AVISO: o módulo ${m##*/} não carregou"
done

ESPERA=60          # segundos à espera do volume da ISO (pens USB lentas ou hubs demoram a aparecer)
msg "a procurar o volume $LABEL (até $ESPERA s)..."
mkdir -p /run/live/iso /run/live/lower /run/live/rw /newroot
encontrado=""
iso_src=""
# tentar <dispositivo> [tipo]: monta só-leitura e confirma live/rootfs.squashfs.
# Um disco inteiro com partições (pen gravada em modo imagem) é montado através de um dispositivo
# loop só-leitura: a montagem direta reclamava o disco inteiro em exclusivo e o kernel recusava
# depois montar qualquer partição desse disco (ex.: a IANINJA-DADOS criada a seguir à imagem na
# própria pen — mount: "Device or resource busy"). O loop abre o disco sem exclusividade.
tentar() {
  local dev=$1 src=$1
  [ -b "$dev" ] || return 1
  # todo o disco inteiro que não seja um leitor ótico vai pelo loop, mesmo que as partições ainda
  # não estejam em /sys: em UEFI a pen pode aparecer antes de o kernel ler a tabela de partições,
  # e a montagem direta bloqueava depois a IANINJA-DADOS dessa pen (ensaio F11 persistencia-pen)
  case ${dev##*/} in
    sr*) ;;
    *) [ -e /sys/class/block/${dev##*/}/partition ]          || src=$(losetup -f --show -r "$dev" 2>/dev/null) || src=$dev ;;
  esac
  if mount -n -o ro ${2:+-t $2} "$src" /run/live/iso 2>/dev/null; then
    [ -f /run/live/iso/live/rootfs.squashfs ] && { encontrado=$dev; iso_src=$src; return 0; }
    umount -n /run/live/iso
  fi
  [ "$src" != "$dev" ] && losetup -d "$src" 2>/dev/null
  return 1
}
# disco inteiro de uma partição (sda3 -> sda, nvme0n1p3 -> nvme0n1, mmcblk0p2 -> mmcblk0)
disco_de() {
  local n=${1##*/}
  [ -e /sys/class/block/$n/partition ] || return 1
  n=$(readlink -f /sys/class/block/$n/..); echo /dev/${n##*/}
}
# Numa pen USB gravada em modo imagem (dd) a ISO híbrida do grub-mkrescue tem uma tabela de
# partições: a partição com o rótulo é a HFS+ (para Macs) e a EFI é FAT; o ISO9660 com o
# live/rootfs.squashfs está no DISCO INTEIRO (/dev/sda), que o blkid não lista com o rótulo
# porque vê a tabela de partições. Por isso: 1) cada dispositivo com o rótulo; 2) o disco-pai
# de cada um, como iso9660; 3) todos os discos inteiros (incluindo sr*), como iso9660.
procurar() {
  local dev d n vistos=" "
  for dev in $(blkid -c /dev/null -o device -t LABEL=$LABEL 2>/dev/null); do
    tentar "$dev" && return 0
    vistos="$vistos$dev "
    d=$(disco_de "$dev") || continue
    case "$vistos" in *" $d "*) continue ;; esac
    tentar "$d" iso9660 && return 0
    vistos="$vistos$d "
  done
  for n in /sys/class/block/*; do
    [ -e "$n/partition" ] && continue
    d=/dev/${n##*/}
    case ${n##*/} in loop*|ram*|zram*|dm-*|md*) continue ;; esac
    case "$vistos" in *" $d "*) continue ;; esac
    tentar "$d" iso9660 && return 0
  done
  return 1
}
for i in $(seq 1 $((ESPERA * 2))); do        # ciclos de 0,5 s
  # progresso visível a cada 5 s, para o ecrã não parecer parado
  [ $i -gt 1 ] && [ $((i % 10)) = 1 ] && msg "ainda à procura de $LABEL... ($((i / 2)) s de $ESPERA s)"
  procurar && break
  sleep 0.5
done
[ -n "$encontrado" ] || emergencia "volume com LABEL=$LABEL e live/rootfs.squashfs não encontrado em $ESPERA s"
msg "volume encontrado em $encontrado"
[ "$iso_src" != "$encontrado" ] && msg "(montado através de $iso_src)"
# o dispositivo real da ISO fica registado para o sistema (ianinja-persistencia, ia-criar-persistencia)
echo "$encontrado" > /run/live/iso-dev

mount -n -t squashfs -o loop,ro /run/live/iso/live/rootfs.squashfs /run/live/lower \
  || emergencia "não foi possível montar rootfs.squashfs"

# montar_overlay <dir>: OverlayFS com lower=SquashFS e upper/work dentro de <dir>
montar_overlay() {
  mkdir -p "$1/upper" "$1/work" || return 1
  mount -n -t overlay overlay \
    -o lowerdir=/run/live/lower,upperdir="$1/upper",workdir="$1/work" /newroot
}

# Persistência. Procura, por esta ordem: 1) ext4 com o rótulo IANINJA-DADOS (pen USB, cartão SD,
# NVMe, ou partição criada a seguir à imagem na própria pen); 2) o ficheiro /ianinja/ianinja-dados.img
# em cada partição NTFS (ntfs3), exFAT, FAT ou ext4 legível (montada só-leitura para procurar).
# Desliga-se com "persistencia=nao" ou "semdados" na linha de comandos do kernel.
dados_dev=""      # partição com o ext4 (particao/pen) ou partição hospedeira do ficheiro (ficheiro)
dados_tipo=""     # particao | pen | ficheiro
dados_fs=""       # tipo do sistema de ficheiros hospedeiro (ficheiro)
dados_forca=""    # o hospedeiro só montou só-leitura com "force" (NTFS marcado como em uso)
modo=""
mkdir -p /run/live/procura
procurar_dados() {
  local dev tipo fs
  for dev in $(blkid -c /dev/null -o device -t LABEL=$DADOS 2>/dev/null); do
    [ "$dev" = "$encontrado" ] && continue
    dados_dev=$dev; dados_tipo=particao; return 0
  done
  for dev in $(blkid -c /dev/null -o device 2>/dev/null); do
    [ "$dev" = "$encontrado" ] && continue
    case $dev in /dev/loop*|/dev/ram*|/dev/zram*|/dev/dm-*|/dev/md*) continue ;; esac
    tipo=$(blkid -c /dev/null -o value -s TYPE "$dev" 2>/dev/null)
    case $tipo in ntfs) fs=ntfs3 ;; exfat|vfat|ext4) fs=$tipo ;; *) continue ;; esac
    dados_forca=""
    if ! mount -n -t $fs -o ro "$dev" /run/live/procura 2>/dev/null; then
      # NTFS deixado "em uso" pelo Windows (hibernação / arranque rápido): só-leitura com force
      # é seguro para procurar; a escrita será recusada mais abaixo, com aviso
      [ $fs = ntfs3 ] || continue
      mount -n -t ntfs3 -o ro,force "$dev" /run/live/procura 2>/dev/null || continue
      dados_forca=1
    fi
    if [ -f /run/live/procura/$IMG ]; then
      umount -n /run/live/procura
      dados_dev=$dev; dados_tipo=ficheiro; dados_fs=$fs; return 0
    fi
    umount -n /run/live/procura
  done
  return 1
}
case " $(cat /proc/cmdline) " in
  *" persistencia=nao "*|*" semdados "*)
    msg "persistência desativada na linha de comandos do kernel" ;;
  *)
    for i in $(seq 1 10); do      # até 5 s a mais (o disco de dados pode ser outra pen USB)
      procurar_dados && break
      sleep 0.5
    done ;;
esac
aviso_dados() {
  msg "AVISO: $* — a usar tmpfs (as alterações perdem-se ao desligar)"
}
dados_loop=""
if [ -n "$dados_dev" ]; then
  mkdir -p /run/live/dados
  if [ $dados_tipo = ficheiro ]; then
    mkdir -p /run/live/dados-disco
    if [ -n "$dados_forca" ] || ! mount -n -t $dados_fs -o rw,noatime "$dados_dev" /run/live/dados-disco 2>/dev/null; then
      aviso_dados "$dados_dev tem o ficheiro $IMG mas não pode ser montado para escrita (NTFS marcado como em uso: desligue o Windows por completo, sem hibernação nem arranque rápido)"
    elif ! dados_loop=$(losetup -f --show /run/live/dados-disco/$IMG 2>/dev/null); then
      aviso_dados "não foi possível ligar $IMG em $dados_dev a um dispositivo loop"
      umount -n /run/live/dados-disco
    elif ! mount -n -t ext4 -o rw,noatime "$dados_loop" /run/live/dados; then
      aviso_dados "não foi possível montar $IMG ($dados_dev) como ext4"
      losetup -d "$dados_loop"; umount -n /run/live/dados-disco
    elif montar_overlay /run/live/dados/overlay; then
      modo=dados
    else
      aviso_dados "não foi possível usar $IMG ($dados_dev) como camada de escrita"
      umount -n /run/live/dados; losetup -d "$dados_loop"; umount -n /run/live/dados-disco
    fi
  else
    # a partição está na mesma pen que a ISO? (criada a seguir à imagem: tipo "pen")
    d=$(disco_de "$dados_dev" 2>/dev/null)
    [ "$d" = "$encontrado" ] && dados_tipo=pen
    # segunda tentativa: logo após a deteção o udev/kernel ainda pode ter a partição ocupada
    if mount -n -t ext4 -o rw,noatime "$dados_dev" /run/live/dados 2>/run/live/dados-erro        || { sleep 1; mount -n -t ext4 -o rw,noatime "$dados_dev" /run/live/dados 2>/run/live/dados-erro; }; then
      if montar_overlay /run/live/dados/overlay; then
        modo=dados
      else
        aviso_dados "não foi possível usar $DADOS ($dados_dev) como camada de escrita"
        umount -n /run/live/dados
      fi
    else
      msg "mount: $(cat /run/live/dados-erro 2>/dev/null)"
      aviso_dados "não foi possível montar $dados_dev ($DADOS) como ext4"
    fi
  fi
fi
if [ -z "$modo" ]; then
  mount -n -t tmpfs -o mode=0755 tmpfs /run/live/rw || emergencia "tmpfs para a camada de escrita"
  montar_overlay /run/live/rw || emergencia "não foi possível montar o OverlayFS"
  modo=tmpfs
fi
[ -x /newroot/sbin/init ] || emergencia "/sbin/init não existe na raiz"
if [ $modo = dados ]; then
  if [ $dados_tipo = ficheiro ]; then
    msg "persistência: $DADOS (ficheiro $IMG em $dados_dev)"
  else
    msg "persistência: $DADOS ($dados_dev)"
  fi
  # o que o sistema precisa de saber (ianinja-persistencia estado): tipo, dispositivo, loop
  {
    echo "tipo=$dados_tipo"; echo "dispositivo=$dados_dev"
    [ $dados_tipo = ficheiro ] && { echo "ficheiro=/$IMG"; echo "loop=$dados_loop"; echo "fs=$dados_fs"; }
  } > /run/live/dados-info
  # o disco de dados fica visível no sistema em /mnt/dados (a camada de escrita está em overlay/);
  # a partição que guarda o ficheiro-imagem fica em /mnt/dados-disco
  mkdir -p /newroot/mnt/dados && mount -n --move /run/live/dados /newroot/mnt/dados \
    || msg "AVISO: não foi possível mover $DADOS para /mnt/dados (continua em /run/live/dados)"
  if [ $dados_tipo = ficheiro ]; then
    mkdir -p /newroot/mnt/dados-disco && mount -n --move /run/live/dados-disco /newroot/mnt/dados-disco \
      || msg "AVISO: não foi possível mover $dados_dev para /mnt/dados-disco"
  fi
  msg "raiz overlay pronta (SquashFS + $DADOS)"
else
  msg "persistência: desligada (tmpfs)"
  msg "raiz overlay pronta (SquashFS + tmpfs)"
fi

# Leva /run (com /run/live/*), /dev, /proc e /sys para a nova raiz
mount -n --move /run  /newroot/run
mount -n --move /dev  /newroot/dev
mount -n --move /sys  /newroot/sys
mount -n --move /proc /newroot/proc

exec switch_root /newroot /sbin/init "$@"
emergencia "switch_root falhou"
