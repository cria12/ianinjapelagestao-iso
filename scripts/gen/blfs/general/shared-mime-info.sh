# Gerado de BLFS 12.4 general/shared-mime-info.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: xdgmime (download opcional) só serve para a test suite]
#   tar -xf ../xdgmime.tar.xz &&
#   make -C xdgmime

# --- bloco 2 (userinput)
echo '>>> bloco 2'
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D update-mimedb=true .. &&
ninja

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install

