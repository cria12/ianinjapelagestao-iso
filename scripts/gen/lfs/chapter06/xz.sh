# Gerado de LFS 12.4 chapter06/xz.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.8.1

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make DESTDIR=$LFS install

# --- bloco 4 (userinput)
echo '>>> bloco 4'
rm -v $LFS/usr/lib/liblzma.la

