# Gerado de BLFS 12.4 general/tree.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make PREFIX=/usr MANDIR=/usr/share/man install

