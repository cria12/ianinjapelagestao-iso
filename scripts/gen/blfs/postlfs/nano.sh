# Gerado de BLFS 12.4 postlfs/nano.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --enable-utf8     \
            --docdir=/usr/share/doc/nano-8.6 &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install &&
install -v -m644 doc/{nano.html,sample.nanorc} /usr/share/doc/nano-8.6

