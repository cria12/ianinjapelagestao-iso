# Gerado de BLFS 12.4 x/xdg-desktop-portal.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D tests=disabled .. &&
ninja

# --- bloco 2 [omitido: testes: precisam de pytest, dbusmock e umockdev (não instalados)]
#   meson configure -D tests=enabled &&
#   ninja test

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install

# --- bloco 4 [substituído: apagar só as unidades systemd deste pacote (o livro apaga /usr/lib/systemd inteiro, onde está o xfconfd.service)]
rm -vf /usr/lib/systemd/user/xdg-desktop-portal.service           \
       /usr/lib/systemd/user/xdg-desktop-portal-rewrite-launchers.service \
       /usr/lib/systemd/user/xdg-document-portal.service          \
       /usr/lib/systemd/user/xdg-permission-store.service

