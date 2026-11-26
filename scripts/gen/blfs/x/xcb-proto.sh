# Gerado de BLFS 12.4 x/xcb-proto.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
PYTHON=python3 ./configure $XORG_CONFIG

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

# --- bloco 3 (userinput)
echo '>>> bloco 3'
rm -f $XORG_PREFIX/lib/pkgconfig/xcb-proto.pc

