# Gerado de BLFS 12.4 general/libclc.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -G Ninja ..                  &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

