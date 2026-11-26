# Gerado de BLFS 12.4 x/x7driver@libevdev.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup ..                  \
      --prefix=$XORG_PREFIX     \
      --buildtype=release       \
      -D documentation=disabled \
      -D tests=disabled         &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

