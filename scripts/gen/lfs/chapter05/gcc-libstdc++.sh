# Gerado de LFS 12.4 chapter05/gcc-libstdc++.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir -v build
cd       build

# --- bloco 2 (userinput)
echo '>>> bloco 2'
../libstdc++-v3/configure      \
    --host=$LFS_TGT            \
    --build=$(../config.guess) \
    --prefix=/usr              \
    --disable-multilib         \
    --disable-nls              \
    --disable-libstdcxx-pch    \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/15.2.0

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make DESTDIR=$LFS install

# --- bloco 5 (userinput)
echo '>>> bloco 5'
rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la

