#!/bin/bash
# Executa uma página do BLFS dentro do chroot segundo as regras do livro:
# extrair o tarball em /sources, cd para o diretório de topo, correr os comandos transcritos
# (scripts/gen/blfs/<pagina>.sh), voltar e apagar o diretório extraído.
# Páginas sem tarball (só configuração) usam "-" e correm a partir de /sources.
# Uso: run-blfs.sh <capitulo/pagina> <tarball|->
set -e
page=$1 tarball=${2:--}
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$(dirname "$HERE")
gen=$HERE/gen/blfs/$page.sh
[ -f "$gen" ] || { echo "script $gen inexistente"; exit 1; }

# variáveis e funções que as páginas pressupõem (XORG_PREFIX, as_root, pathappend...)
[ -r "$HERE/blfs-env.sh" ] && . "$HERE/blfs-env.sh"

echo "=== BLFS $page ($tarball) — $(date)"
cd "$SRC"
if [ "$tarball" = "-" ]; then
  bash -e "$gen"
  echo "=== OK $page — $(date)"
  exit 0
fi
[ -f "$tarball" ] || { echo "tarball $SRC/$tarball inexistente"; exit 1; }
dir=$(tar -tf "$tarball" | head -1 | sed 's@^\./@@' | cut -d/ -f1)
[ -n "$dir" ] || { echo "não foi possível determinar o diretório de topo de $tarball"; exit 1; }
rm -rf "${SRC:?}/$dir"
tar -xf "$tarball"
cd "$dir"
bash -e "$gen"
cd "$SRC"
rm -rf "${SRC:?}/$dir"
echo "=== OK $page — $(date)"
