# Gerado de BLFS 12.4 x/x7driver@xorg-libinput-driver.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure $XORG_CONFIG &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

