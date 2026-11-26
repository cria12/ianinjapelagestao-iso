# Gerado de BLFS 12.4 x/x7driver@libinput.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup ..              \
      --prefix=$XORG_PREFIX \
      --buildtype=release   \
      -D debug-gui=false    \
      -D tests=false        \
      -D libwacom=false     \
      -D udev-dir=/usr/lib/udev &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

# --- bloco 3 [omitido: documentação HTML só existe com -D documentation=true (precisa de Sphinx)]
#   install -v -dm755      /usr/share/doc/libinput-1.29.0/html &&
#   cp -rv Documentation/* /usr/share/doc/libinput-1.29.0/html

