# Gerado de BLFS 12.4 x/xdg-desktop-portal-gtk.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: -D wallpaper=disabled explícito (precisa do gnome-desktop, que arrastaria o GTK4); settings/appchooser/lockdown ativos]
mkdir build &&
cd    build &&
meson setup --prefix=/usr --buildtype=release \
            -D wallpaper=disabled             \
            -D settings=enabled               \
            -D appchooser=enabled             \
            -D lockdown=enabled .. &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

# --- bloco 3 [substituído: apagar só as unidades systemd deste pacote (idem)]
rm -vf /usr/lib/systemd/user/xdg-desktop-portal-gtk.service

