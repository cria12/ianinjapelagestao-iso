# Gerado de BLFS 12.4 postlfs/nettle.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr --disable-static &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install &&
chmod   -v   755 /usr/lib/lib{hogweed,nettle}.so &&
install -v -m755 -d /usr/share/doc/nettle-3.10.2 &&
install -v -m644 nettle.{html,pdf} /usr/share/doc/nettle-3.10.2

