# Gerado de BLFS 12.4 general/llvm.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
tar -xf ../llvm-cmake-20.1.8.src.tar.xz                              &&
tar -xf ../llvm-third-party-20.1.8.src.tar.xz                        &&
sed '/LLVM_COMMON_CMAKE_UTILS/s@../cmake@cmake-20.1.8.src@'          \
    -i CMakeLists.txt                                                &&
sed '/LLVM_THIRD_PARTY_DIR/s@../third-party@third-party-20.1.8.src@' \
    -i cmake/modules/HandleLLVMOptions.cmake

# --- bloco 2 (userinput)
echo '>>> bloco 2'
tar -xf ../clang-20.1.8.src.tar.xz -C tools &&
mv tools/clang-20.1.8.src tools/clang

# --- bloco 3 [omitido: compiler-rt (download opcional: sanitizers/profiling) — não é preciso ao Mesa nem ao Rust]
#   tar -xf ../compiler-rt-20.1.8.src.tar.xz -C projects    &&
#   mv projects/compiler-rt-20.1.8.src projects/compiler-rt

# --- bloco 4 (userinput)
echo '>>> bloco 4'
grep -rl '#!.*python' | xargs sed -i '1s/python$/python3/'

# --- bloco 5 (userinput)
echo '>>> bloco 5'
sed 's/utility/tool/' -i utils/FileCheck/CMakeLists.txt

# --- bloco 6 [substituído: cmake do livro com LLVM_PARALLEL_LINK_JOBS=2 e ninja -j10 (11 GB de RAM: compilar+ligar clang com -j14 arrisca OOM)]
mkdir -v build &&
cd       build &&

CC=gcc CXX=g++                               \
cmake -D CMAKE_INSTALL_PREFIX=/usr           \
      -D CMAKE_SKIP_INSTALL_RPATH=ON         \
      -D LLVM_ENABLE_FFI=ON                  \
      -D CMAKE_BUILD_TYPE=Release            \
      -D LLVM_BUILD_LLVM_DYLIB=ON            \
      -D LLVM_LINK_LLVM_DYLIB=ON             \
      -D LLVM_ENABLE_RTTI=ON                 \
      -D LLVM_TARGETS_TO_BUILD="host;AMDGPU" \
      -D LLVM_BINUTILS_INCDIR=/usr/include   \
      -D LLVM_INCLUDE_BENCHMARKS=OFF         \
      -D LLVM_PARALLEL_LINK_JOBS=2           \
      -D CLANG_DEFAULT_PIE_ON_LINUX=ON       \
      -D CLANG_CONFIG_FILE_SYSTEM_DIR=/etc/clang \
      -W no-dev -G Ninja ..                  &&
ninja -j10

# --- bloco 7 [omitido: suite de testes (ninja check-all: muito longa) e correção dos testes do compiler-rt (não instalado)]
#   sed -e 's/config.has_no_default_config_flag/True/' \
#       -e 's/"-fuse-ld=gold"//'                       \
#       -i ../projects/compiler-rt/test/lit.common.cfg.py

# --- bloco 8 [omitido: suite de testes (ninja check-all: muito longa) e correção dos testes do compiler-rt (não instalado)]
#   sh -c 'ulimit -c 0 && ninja check-all'

# --- bloco 9 (root)
echo '>>> bloco 9'
ninja install

# --- bloco 10 (root)
echo '>>> bloco 10'
mkdir -pv /etc/clang &&
for i in clang clang++; do
  echo -fstack-protector-strong > /etc/clang/$i.cfg
done

