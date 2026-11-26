# Gerado de BLFS 12.4 multimedia/libva.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
cd build &&

meson setup --prefix=$XORG_PREFIX --buildtype=release &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

