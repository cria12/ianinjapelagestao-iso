# Gerado de BLFS 12.4 x/xorgproto.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup --prefix=$XORG_PREFIX .. &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install &&
mv -v $XORG_PREFIX/share/doc/xorgproto{,-2024.1}

