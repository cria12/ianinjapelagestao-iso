# Gerado de BLFS 12.4 general/spirv-headers.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr -G Ninja .. &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

