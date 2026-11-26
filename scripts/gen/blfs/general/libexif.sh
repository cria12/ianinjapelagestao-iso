# Gerado de BLFS 12.4 general/libexif.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr    \
            --disable-static \
            --with-doc-dir=/usr/share/doc/libexif-0.6.25 &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

