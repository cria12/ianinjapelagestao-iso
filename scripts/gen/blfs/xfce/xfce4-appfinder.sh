# Gerado de BLFS 12.4 xfce/xfce4-appfinder.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

