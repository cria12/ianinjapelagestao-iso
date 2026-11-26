# Gerado de BLFS 12.4 basicnet/iw.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i "/INSTALL.*gz/s/.gz//" Makefile &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

