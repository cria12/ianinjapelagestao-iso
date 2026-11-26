# Gerado de BLFS 12.4 multimedia/alsa-lib.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed 's/playmidi1//' -i test/Makefile.am &&
autoreconf -fi

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure &&
make

# --- bloco 3 [omitido: documentação API precisa de Doxygen (não instalado)]
#   make doc

# --- bloco 4 (root)
echo '>>> bloco 4'
make install &&
tar -C /usr/share/alsa --strip-components=1 -xf ../alsa-ucm-conf-1.2.14.tar.bz2

# --- bloco 5 [omitido: documentação API precisa de Doxygen (não instalado)]
#   install -v -d -m755 /usr/share/doc/alsa-lib-1.2.14/html/search &&
#   install -v -m644 doc/doxygen/html/*.* \
#                   /usr/share/doc/alsa-lib-1.2.14/html &&
#   install -v -m644 doc/doxygen/html/search/* \
#                   /usr/share/doc/alsa-lib-1.2.14/html/search

