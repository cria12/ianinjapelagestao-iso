# Gerado de BLFS 12.4 postlfs/gnupg.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: --disable-ldap: sem OpenLDAP (e Cyrus SASL/LMDB); o Flatpak/OSTree só verifica assinaturas]
mkdir build &&
cd    build &&
../configure --prefix=/usr        \
             --localstatedir=/var \
             --sysconfdir=/etc    \
             --disable-ldap       \
             --docdir=/usr/share/doc/gnupg-2.4.8 &&
make &&
makeinfo --html --no-split -I doc -o doc/gnupg_nochunks.html ../doc/gnupg.texi &&
makeinfo --plaintext       -I doc -o doc/gnupg.txt           ../doc/gnupg.texi &&
make -C doc html

# --- bloco 2 [omitido: manual em PDF (precisa de texlive)]
#   make -C doc pdf

# --- bloco 3 (root)
echo '>>> bloco 3'
make install &&

install -v -m755 -d /usr/share/doc/gnupg-2.4.8/html            &&
install -v -m644    doc/gnupg_nochunks.html \
                    /usr/share/doc/gnupg-2.4.8/html/gnupg.html &&
install -v -m644    ../doc/*.texi doc/gnupg.txt \
                    /usr/share/doc/gnupg-2.4.8 &&
install -v -m644    doc/gnupg.html/* \
                    /usr/share/doc/gnupg-2.4.8/html

# --- bloco 4 [omitido: manual em PDF (precisa de texlive)]
#   install -v -m644 doc/gnupg.pdf \
#                    /usr/share/doc/gnupg-2.4.8

