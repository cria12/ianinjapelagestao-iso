# Gerado de BLFS 12.4 general/libassuan.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr &&
make                      &&

make -C doc html                                                       &&
makeinfo --html --no-split -o doc/assuan_nochunks.html doc/assuan.texi &&
makeinfo --plaintext       -o doc/assuan.txt           doc/assuan.texi

# --- bloco 2 [omitido: manual em PDF/PostScript (precisa de texlive)]
#   make -C doc pdf ps

# --- bloco 3 (root)
echo '>>> bloco 3'
make install &&

install -v -dm755   /usr/share/doc/libassuan-3.0.2/html &&
install -v -m644 doc/assuan.html/* \
                    /usr/share/doc/libassuan-3.0.2/html &&
install -v -m644 doc/assuan_nochunks.html \
                    /usr/share/doc/libassuan-3.0.2      &&
install -v -m644 doc/assuan.{txt,texi} \
                    /usr/share/doc/libassuan-3.0.2

# --- bloco 4 [omitido: manual em PDF/PostScript (precisa de texlive)]
#   install -v -m644  doc/assuan.{pdf,ps,dvi} \
#                     /usr/share/doc/libassuan-3.0.2

