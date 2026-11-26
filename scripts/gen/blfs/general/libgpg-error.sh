# Gerado de BLFS 12.4 general/libgpg-error.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install &&
install -v -m644 -D README /usr/share/doc/libgpg-error-1.55/README

