# Gerado de BLFS 12.4 multimedia/sbc.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr --disable-static --disable-tester &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

