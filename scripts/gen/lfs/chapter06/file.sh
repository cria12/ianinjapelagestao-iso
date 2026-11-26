# Gerado de LFS 12.4 chapter06/file.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make FILE_COMPILE=$(pwd)/build/src/file

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make DESTDIR=$LFS install

# --- bloco 5 (userinput)
echo '>>> bloco 5'
rm -v $LFS/usr/lib/libmagic.la

