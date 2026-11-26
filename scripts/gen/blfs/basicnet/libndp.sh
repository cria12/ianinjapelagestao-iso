# Gerado de BLFS 12.4 basicnet/libndp.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --localstatedir=/var \
            --disable-static     &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

