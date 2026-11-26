# Gerado de LFS 12.4 chapter06/binutils-pass2.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed '6031s/$add_dir//' -i ltmain.sh

# --- bloco 2 (userinput)
echo '>>> bloco 2'
mkdir -v build
cd       build

# --- bloco 3 (userinput)
echo '>>> bloco 3'
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make

# --- bloco 5 (userinput)
echo '>>> bloco 5'
make DESTDIR=$LFS install

# --- bloco 6 (userinput)
echo '>>> bloco 6'
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

