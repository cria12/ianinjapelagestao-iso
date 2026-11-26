# Gerado de BLFS 12.4 general/libunistring.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libunistring-1.3 &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

