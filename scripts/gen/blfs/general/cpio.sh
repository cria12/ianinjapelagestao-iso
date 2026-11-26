# Gerado de BLFS 12.4 general/cpio.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -e "/^extern int (\*xstat)/s/()/(const char * restrict,  struct stat * restrict)/" \
    -i src/extern.h
sed -e "/^int (\*xstat)/s/()/(const char * restrict,  struct stat * restrict)/" \
    -i src/global.c

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr \
            --enable-mt   \
            --with-rmt=/usr/libexec/rmt &&
make &&
makeinfo --html            -o doc/html      doc/cpio.texi &&
makeinfo --html --no-split -o doc/cpio.html doc/cpio.texi &&
makeinfo --plaintext       -o doc/cpio.txt  doc/cpio.texi

# --- bloco 3 [omitido: documentação PDF/PS precisa de texlive (não instalado)]
#   make -C doc pdf &&
#   make -C doc ps

# --- bloco 4 (root)
echo '>>> bloco 4'
make install &&
install -v -m755 -d /usr/share/doc/cpio-2.15/html &&
install -v -m644    doc/html/* \
                    /usr/share/doc/cpio-2.15/html &&
install -v -m644    doc/cpio.{html,txt} \
                    /usr/share/doc/cpio-2.15

# --- bloco 5 [omitido: documentação PDF/PS precisa de texlive (não instalado)]
#   install -v -m644 doc/cpio.{pdf,ps,dvi} \
#                    /usr/share/doc/cpio-2.15

