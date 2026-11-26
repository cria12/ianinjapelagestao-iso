# Gerado de BLFS 12.4 x/adwaita-icon-theme.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup --prefix=/usr .. &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
rm -rf /usr/share/icons/Adwaita/ &&
ninja install

