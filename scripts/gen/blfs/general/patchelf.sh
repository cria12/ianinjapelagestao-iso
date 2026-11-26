# Gerado de BLFS 12.4 general/patchelf.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr \
            --docdir=/usr/share/doc/patchelf-0.18.0 &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

