# Gerado de BLFS 12.4 basicnet/links.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr --mandir=/usr/share/man &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install &&
install -v -d -m755 /usr/share/doc/links-2.30 &&
install -v -m644 doc/links_cal/* KEYS BRAILLE_HOWTO \
    /usr/share/doc/links-2.30

