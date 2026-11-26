#!/bin/bash
# F2 — Cross-toolchain (LFS Cap. 5), executado como utilizador lfs
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F2)" = ok ] && exit 0
montar_lfs
etapa_inicio F2
preparar_runner
mapfile -t pages < <(grep '^chapter05/' $P/scripts/lfs-pages.txt)
corre_paginas F2 lfs 05 "${pages[@]}"

# Sanity check do Glibc (Cap. 5.5): se falhar, não avançar
if ! grep -q 'Requesting program interpreter: /lib64/ld-linux-x86-64.so.2' $P/logs/05-glibc.log; then
  etapa_fim F2 falhou "sanity check do Glibc falhou (logs/05-glibc.log)"
  exit 1
fi
registo "Sanity check do Glibc (Cap. 5) OK: interpretador /lib64/ld-linux-x86-64.so.2"
etapa_fim F2 ok "${#pages[@]} pacotes; sanity check Glibc OK"
