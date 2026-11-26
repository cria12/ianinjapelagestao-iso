# Gerado de BLFS 12.4 general/desktop-file-utils.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (root)
echo '>>> bloco 1'
rm -fv /usr/bin/desktop-file-edit

# --- bloco 2 (userinput)
echo '>>> bloco 2'
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install

# --- bloco 4 (root)
echo '>>> bloco 4'
install -vdm755 /usr/share/applications &&
update-desktop-database /usr/share/applications

