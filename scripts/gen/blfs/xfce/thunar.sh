# Gerado de BLFS 12.4 xfce/thunar.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i 's/\tinstall-systemd_userDATA/\t/' Makefile.in

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/thunar-4.20.4 &&
make

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

