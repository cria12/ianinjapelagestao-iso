# Gerado de BLFS 12.4 general/fontconfig.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --localstatedir=/var \
            --disable-docs       \
            --docdir=/usr/share/doc/fontconfig-2.17.1 &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

# --- bloco 3 (root)
echo '>>> bloco 3'
install -v -dm755 \
        /usr/share/{man/man{1,3,5},doc/fontconfig-2.17.1} &&
install -v -m644 fc-*/*.1         /usr/share/man/man1 &&
install -v -m644 doc/*.3          /usr/share/man/man3 &&
install -v -m644 doc/fonts-conf.5 /usr/share/man/man5 &&
install -v -m644 doc/*.{pdf,sgml,txt,html} \
                                  /usr/share/doc/fontconfig-2.17.1

