# Gerado de LFS 12.4 chapter08/sysvinit.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
patch -Np1 -i ../sysvinit-3.14-consolidated-1.patch

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make install

