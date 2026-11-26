# Gerado de BLFS 12.4 x/libXdmcp.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure $XORG_CONFIG --docdir=/usr/share/doc/libXdmcp-1.1.5 &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

