#!/bin/bash
# F4 — Chroot e ferramentas adicionais (LFS Cap. 7)
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F4)" = ok ] && exit 0
montar_lfs
etapa_inicio F4
preparar_runner

# 7.2 Changing Ownership (root no host)
corre_paginas F4 host 07 chapter07/changingowner
# 7.3 Virtual Kernel File Systems
montar_kernfs > $P/logs/07-kernfs.log 2>&1
# 7.5/7.6 + pacotes (dentro do chroot)
corre_paginas F4 chroot 07 chapter07/creatingdirs chapter07/createfiles \
  chapter07/gettext chapter07/bison chapter07/perl chapter07/Python chapter07/texinfo chapter07/util-linux

# 7.13 Cleaning up and Saving the Temporary System
limpeza() {
  in_chroot 'rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools'
}
corre_passo f4-limpeza $P/logs/07-cleanup.log limpeza

backup() {
  desmontar_kernfs
  cd $LFS
  XZ_OPT=-T0 tar --exclude=./sources -cJpf $P/backup-cap7.tar.xz .
}
corre_passo f4-backup $P/logs/07-backup.log backup
decisao "Backup do Cap. 7 sem /sources" \
"O backup obrigatório (backup-cap7.tar.xz) segue o Cap. 7.13.2 mas exclui ./sources (≈600 MB de tarballs já validados por MD5 e reprodutíveis), para reduzir tempo e espaço. Para restaurar: montar lfs.img, apagar o conteúdo exceto sources e extrair o tar em /mnt/lfs."
montar_kernfs >> $P/logs/07-kernfs.log 2>&1
etapa_fim F4 ok "8 pacotes/secções; backup em backup-cap7.tar.xz ($(du -h $P/backup-cap7.tar.xz | cut -f1))"
