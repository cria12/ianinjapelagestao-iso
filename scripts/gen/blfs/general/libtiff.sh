# Gerado de BLFS 12.4 general/libtiff.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir -p libtiff-build &&
cd       libtiff-build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr ..     \
      -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -G Ninja                            \
      -D CMAKE_INSTALL_DOCDIR=/usr/share/doc/libtiff-4.7.0 &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

