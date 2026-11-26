# Gerado de BLFS 12.4 general/harfbuzz.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup ..             \
      --prefix=/usr        \
      --buildtype=release  \
      -D graphite2=enabled &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

