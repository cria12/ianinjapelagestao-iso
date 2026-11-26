# Gerado de BLFS 12.4 xfce/xfce4-session.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr       \
            --sysconfdir=/etc   \
            --disable-legacy-sm &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

# --- bloco 3 (root)
echo '>>> bloco 3'
update-desktop-database &&
update-mime-database /usr/share/mime

# --- bloco 4 [omitido: ~/.xinitrc + startx: a sessão é lançada pelo LightDM (/usr/share/xsessions/xfce.desktop); interativo]
#   cat > ~/.xinitrc << "EOF"
#   dbus-launch --exit-with-x11 startxfce4
#   EOF
#   
#   startx

# --- bloco 5 [omitido: ~/.xinitrc + startx: a sessão é lançada pelo LightDM (/usr/share/xsessions/xfce.desktop); interativo]
#   startx &> ~/.x-session-errors

