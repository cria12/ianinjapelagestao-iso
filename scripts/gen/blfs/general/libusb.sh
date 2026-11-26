# Gerado de BLFS 12.4 general/libusb.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr --disable-static &&
make

# --- bloco 2 [omitido: documentação API precisa de Doxygen (não instalado)]
#   pushd doc                &&
#     doxygen -u doxygen.cfg &&
#     make docs              &&
#   popd

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

# --- bloco 4 [omitido: documentação API precisa de Doxygen (não instalado)]
#   install -v -d -m755 /usr/share/doc/libusb-1.0.29/apidocs &&
#   install -v -m644    doc/api-1.0/* \
#                       /usr/share/doc/libusb-1.0.29/apidocs

