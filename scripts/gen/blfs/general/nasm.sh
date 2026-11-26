# Gerado de BLFS 12.4 general/nasm.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: documentação opcional (nasm-*-xdoc.tar.xz) não descarregada]
#   tar -xf ../nasm-2.16.03-xdoc.tar.xz --strip-components=1

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr &&
make

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

# --- bloco 4 [omitido: documentação opcional (nasm-*-xdoc.tar.xz) não descarregada]
#   install -m755 -d         /usr/share/doc/nasm-2.16.03/html  &&
#   cp -v doc/html/*.html    /usr/share/doc/nasm-2.16.03/html  &&
#   cp -v doc/*.{txt,ps,pdf} /usr/share/doc/nasm-2.16.03

