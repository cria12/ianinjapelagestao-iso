#!/bin/bash
# Executa uma página do livro (pacote ou secção) segundo as regras do LFS:
# extrair o tarball em sources, cd, correr os comandos transcritos, voltar e apagar o diretório.
# Funciona no host (utilizador lfs, SRC=$LFS/sources) e no chroot (SRC=/sources).
# Uso: run-pkg.sh <capitulo/pagina>
set -e
page=$1
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$(dirname "$HERE")
gen=$HERE/gen/lfs/$page.sh
tarball=$(awk -v p="$page" '$1==p{print $2}' "$HERE/tarballs.txt")
[ -f "$gen" ] || { echo "script $gen inexistente"; exit 1; }
[ -n "$tarball" ] && [ "$tarball" != ERRO ] || { echo "tarball desconhecido para $page"; exit 1; }

echo "=== $page ($tarball) — $(date)"
if [ "$tarball" = "-" ]; then
  cd "$SRC"
  bash -e "$gen"
  exit $?
fi
cd "$SRC"
dir=$(tar -tf "$tarball" | head -1 | cut -d/ -f1)
rm -rf "$SRC/$dir"
tar -xf "$tarball"
cd "$dir"
bash -e "$gen"
cd "$SRC"
rm -rf "$SRC/$dir"
echo "=== OK $page — $(date)"
