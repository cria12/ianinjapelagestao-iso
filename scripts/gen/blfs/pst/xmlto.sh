# Gerado de BLFS 12.4 pst/xmlto.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
autoreconf -fiv                                  &&
LINKS="/usr/bin/links" ./configure --prefix=/usr &&

make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

