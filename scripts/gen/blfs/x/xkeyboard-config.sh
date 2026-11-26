# Gerado de BLFS 12.4 x/xkeyboard-config.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup --prefix=$XORG_PREFIX --buildtype=release .. &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
if [ -d $XORG_PREFIX/share/X11/xkb ]; then
  rm -rf $XORG_PREFIX/share/X11/xkb
  rm -f  $XORG_PREFIX/share/man/man7/xkeyboard-config.7
  rm -f  $XORG_PREFIX/share/pkgconfig/xkeyboard-config.pc
fi

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install

