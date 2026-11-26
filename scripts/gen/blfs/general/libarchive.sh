# Gerado de BLFS 12.4 general/libarchive.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr --disable-static &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

# --- bloco 3 (root)
echo '>>> bloco 3'
ln -sfv bsdunzip /usr/bin/unzip

