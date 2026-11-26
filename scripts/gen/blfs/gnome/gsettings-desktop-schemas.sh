# Gerado de BLFS 12.4 gnome/gsettings-desktop-schemas.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i -r 's:"(/system):"/org/gnome\1:g' schemas/*.in &&

mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

# --- bloco 3 (root)
echo '>>> bloco 3'
glib-compile-schemas /usr/share/glib-2.0/schemas

