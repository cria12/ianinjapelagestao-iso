# Gerado de BLFS 12.4 x/xinit.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure $XORG_CONFIG --with-xinitdir=/etc/X11/app-defaults &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install &&
ldconfig

# --- bloco 3 [omitido: Xorg setuid root: desnecessário (o LightDM arranca o X como root; startx sem root via elogind)]
#   chmod u+s $XORG_PREFIX/bin/Xorg

# --- bloco 4 [omitido: startx no 1.º VT livre: só faz sentido com o Xorg setuid (bloco 3)]
#   sed -i '/$serverargs $vtarg/ s/serverargs/: #&/' $XORG_PREFIX/bin/startx

