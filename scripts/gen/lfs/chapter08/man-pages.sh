# Gerado de LFS 12.4 chapter08/man-pages.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
rm -v man3/crypt*

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make -R GIT=false prefix=/usr install

