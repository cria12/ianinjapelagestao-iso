# Gerado de BLFS 12.4 general/libxslt.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libxslt-1.1.43 &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

