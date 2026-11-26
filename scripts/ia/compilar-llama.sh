#!/bin/bash
# Compila e instala o llama.cpp em /usr (corre DENTRO do chroot, a partir de /sources).
# Uso: compilar-llama.sh <tarball> <tag>     (ex.: llama.cpp-b12121.tar.gz b12121)
#
# Configuração portátil: GGML_NATIVE=OFF + GGML_BACKEND_DL=ON + GGML_CPU_ALL_VARIANTS=ON — são
# compiladas todas as variantes x86_64 do backend CPU (x64, SSE4.2, AVX, AVX2, AVX-512, AMX...)
# como bibliotecas separadas em /usr/lib/ggml; no arranque o ggml escolhe a melhor para o CPU.
# Se essa combinação falhar, recorre-se a uma compilação única com a linha de base x86-64
# (SSE2, funciona em qualquer CPU de 64 bits, mais lenta) e isso fica registado.
set -e
tb=$1 tag=$2
[ -n "$tb" ] && [ -n "$tag" ] || { echo "uso: $0 <tarball> <tag>"; exit 1; }
num=${tag#b}
cd /sources
dir=$(tar -tf "$tb" | head -1 | cut -d/ -f1)
rm -rf "/sources/$dir"
tar -xf "$tb"
cd "$dir"

# /sair (pt-PT) como sinónimo de /exit no chat interativo do llama-cli
f=tools/cli/cli-context.cpp
grep -q 'string_starts_with(buffer, "/exit")' $f || { echo "llama-cli: comando /exit não encontrado em $f"; exit 1; }
sed -i 's@string_starts_with(buffer, "/exit")@(string_starts_with(buffer, "/exit") || string_starts_with(buffer, "/sair"))@' $f
grep -q '"/sair"' $f

# OpenMP: o GCC do LFS traz a libgomp
OMP=OFF
[ -e /usr/lib/libgomp.so ] && OMP=ON

comum=(
  -G Ninja
  -D CMAKE_BUILD_TYPE=Release
  -D CMAKE_INSTALL_PREFIX=/usr
  -D CMAKE_INSTALL_LIBDIR=lib
  -D BUILD_SHARED_LIBS=ON
  -D GGML_NATIVE=OFF
  -D GGML_OPENMP=$OMP
  -D LLAMA_OPENSSL=ON
  -D LLAMA_BUILD_TESTS=OFF
  -D LLAMA_BUILD_EXAMPLES=OFF
  -D LLAMA_BUILD_TOOLS=ON
  -D LLAMA_BUILD_SERVER=ON
  -D LLAMA_BUILD_UI=OFF
  -D LLAMA_USE_PREBUILT_UI=OFF
  -D LLAMA_BUILD_NUMBER=$num
  -D LLAMA_BUILD_COMMIT=$tag
)
variante=todas
if ! { cmake -B build "${comum[@]}" -D GGML_BACKEND_DL=ON -D GGML_CPU_ALL_VARIANTS=ON \
         -D GGML_BACKEND_DIR=/usr/lib/ggml && ninja -C build; }; then
  echo "[AVISO] GGML_BACKEND_DL + GGML_CPU_ALL_VARIANTS falhou — a compilar a versão portátil x86-64"
  variante=x86-64
  rm -rf build
  cmake -B build "${comum[@]}" -D GGML_BACKEND_DL=OFF -D GGML_CPU_ALL_VARIANTS=OFF
  ninja -C build
fi
ninja -C build install

install -v -d -m755 /usr/share/ia /usr/share/doc/llama.cpp-$tag
install -v -m644 LICENSE /usr/share/doc/llama.cpp-$tag/
cat > /usr/share/ia/compilacao.txt << EOF
llama.cpp $tag
variantes CPU: $variante
OpenMP: $OMP
GGML_NATIVE=OFF GGML_BACKEND_DL=$([ $variante = todas ] && echo ON || echo OFF) GGML_CPU_ALL_VARIANTS=$([ $variante = todas ] && echo ON || echo OFF)
EOF
cat /usr/share/ia/compilacao.txt
ls -la /usr/lib/ggml 2>/dev/null || true
cd /sources
rm -rf "/sources/$dir"
