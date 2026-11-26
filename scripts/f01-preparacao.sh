#!/bin/bash
# F1 — Preparação (LFS Cap. 2, 3, 4): imagem lfs.img, fontes, layout, utilizador lfs
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F1)" = ok ] && exit 0
etapa_inicio F1
umask 022

# Cap. 2 — "partição" = ficheiro de imagem montado via loop (nunca discos reais)
if [ ! -f $P/lfs.img ]; then
  truncate -s 40G $P/lfs.img
  mkfs.ext4 -F -L LFS $P/lfs.img > $P/logs/01-mkfs.log 2>&1
  registo "lfs.img (40 GB, ext4) criada"
fi
montar_lfs
chown root:root $LFS
chmod 755 $LFS
decisao "Partição LFS em ficheiro de imagem" \
"Conforme a Secção 3, o 'disco' LFS é o ficheiro esparso $P/lfs.img (40 GB, ext4, rótulo LFS) montado via loop em /mnt/lfs. Os blocos do Cap. 2.4–2.7 que referem /dev/<xxx> e swapon não se aplicam. A imagem ocupa apenas o espaço efetivamente usado."

# Cap. 3 — pacotes e patches
mkdir -pv $LFS/sources
chmod -v a+wt $LFS/sources
cp $P/book/wget-list-sysv $P/book/md5sums $LFS/sources/
baixar() {
  cd $LFS/sources
  wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources --tries=3 --timeout=60 -nv || true
  # repetir falhados via mirror alternativo do LFS
  local f url
  while read -r url; do
    f=${url##*/}
    [ -s "$f" ] && continue
    for m in https://www.linuxfromscratch.org/lfs/downloads/12.4 https://ftp.osuosl.org/pub/lfs/lfs-packages/12.4; do
      wget -nv --tries=3 --timeout=60 -O "$f" "$m/$f" && break || rm -f "$f"
    done
  done < wget-list-sysv
  pushd $LFS/sources
    md5sum -c md5sums
  popd
}
corre_passo f1-fontes $P/logs/01-fontes.log baixar
etapa_nota F1 "$(ls $LFS/sources | grep -vc 'wget-list\|md5sums') ficheiros baixados, MD5 OK"
chown root:root $LFS/sources/*

# Cap. 4.2 — layout limitado
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  [ -L $LFS/$i ] || ln -sv usr/$i $LFS/$i
done
case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac
mkdir -pv $LFS/tools

# Cap. 4.3 — utilizador lfs (passwd lfs omitido: o build corre via runuser, sem login)
getent group lfs >/dev/null || groupadd lfs
id lfs >/dev/null 2>&1 || useradd -s /bin/bash -g lfs -m -k /dev/null lfs
chown -v lfs $LFS/{usr{,/*},var,etc,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac
chown lfs $LFS/sources

# Cap. 4.4 — ambiente (ficheiros escritos tal como no livro)
runuser -u lfs -- bash -c '
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='"'"'\u:\w\$ '"'"' /bin/bash
EOF
cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF
cat >> ~/.bashrc << "EOF"
export MAKEFLAGS=-j$(nproc)
EOF
'
[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

etapa_fim F1 ok "lfs.img montada, $(ls $LFS/sources | grep -vc 'wget-list\|md5sums') pacotes/patches com MD5 OK, utilizador lfs criado"
