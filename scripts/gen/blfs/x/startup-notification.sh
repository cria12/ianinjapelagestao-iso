# Gerado de BLFS 12.4 x/startup-notification.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr --disable-static &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install &&
install -v -m644 -D doc/startup-notification.txt \
    /usr/share/doc/startup-notification-0.12/startup-notification.txt

