# Gerado de BLFS 12.4 xfce/xfce4-notifyd.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-systemd &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

# --- bloco 3 [omitido: notify-send de teste precisa de uma sessão gráfica e D-Bus a correr]
#   notify-send -i info Information "Hi ${USER}, This is a Test"

