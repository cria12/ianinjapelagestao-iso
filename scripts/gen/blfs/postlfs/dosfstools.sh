# Gerado de BLFS 12.4 postlfs/dosfstools.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr            \
            --enable-compat-symlinks \
            --mandir=/usr/share/man  \
            --docdir=/usr/share/doc/dosfstools-4.2 &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

