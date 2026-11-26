# Gerado de BLFS 12.4 x/vulkan-loader.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr   \
      -D CMAKE_BUILD_TYPE=Release    \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -G Ninja .. &&
ninja

# --- bloco 2 [omitido: testes: o update_deps.py clona repositórios com git (o chroot não tem rede)]
#   sed "s/'git', 'clone'/&, '--depth=1', '-b', self.commit/" \
#       -i ../scripts/update_deps.py &&
#   cmake -D BUILD_TESTS=ON -D UPDATE_DEPS=ON .. &&
#   ninja &&
#   ninja test

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install

