# Gerado de BLFS 12.4 general/slang.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr       \
            --sysconfdir=/etc   \
            --with-readline=gnu &&
make -j1 RPATH=

# --- bloco 2 (root)
echo '>>> bloco 2'
make install_doc_dir=/usr/share/doc/slang-2.3.3   \
     SLSH_DOC_DIR=/usr/share/doc/slang-2.3.3/slsh \
     RPATH= install

