#!/bin/bash
# F3 — Ferramentas temporárias (LFS Cap. 6), executado como utilizador lfs
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F3)" = ok ] && exit 0
montar_lfs
etapa_inicio F3
preparar_runner
mapfile -t pages < <(grep '^chapter06/' $P/scripts/lfs-pages.txt)
corre_paginas F3 lfs 06 "${pages[@]}"
etapa_fim F3 ok "${#pages[@]} pacotes"
