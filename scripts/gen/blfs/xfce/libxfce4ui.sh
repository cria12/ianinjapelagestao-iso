# Gerado de BLFS 12.4 xfce/libxfce4ui.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr --sysconfdir=/etc &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

