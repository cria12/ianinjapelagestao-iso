# Gerado de BLFS 12.4 general/duktape.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i 's/-Os/-O2/' Makefile.sharedlibrary
make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr

# --- bloco 2 (root)
echo '>>> bloco 2'
make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr install

