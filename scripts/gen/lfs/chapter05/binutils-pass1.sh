# Gerado de LFS 12.4 chapter05/binutils-pass1.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir -v build
cd       build

# --- bloco 2 (userinput)
echo '>>> bloco 2'
../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make install

