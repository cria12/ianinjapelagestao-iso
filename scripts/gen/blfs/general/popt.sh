# Gerado de BLFS 12.4 general/popt.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr --disable-static &&
make

# --- bloco 2 [omitido: documentação API precisa de Doxygen (não instalado)]
#   sed -i 's@\./@src/@' Doxyfile &&
#   doxygen

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

# --- bloco 4 [omitido: documentação API precisa de Doxygen (não instalado)]
#   install -v -m755 -d /usr/share/doc/popt-1.19 &&
#   install -v -m644 doxygen/html/* /usr/share/doc/popt-1.19

