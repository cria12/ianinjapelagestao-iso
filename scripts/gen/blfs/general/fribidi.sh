# Gerado de BLFS 12.4 general/fribidi.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

