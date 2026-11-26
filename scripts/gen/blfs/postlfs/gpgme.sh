# Gerado de BLFS 12.4 postlfs/gpgme.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

../configure --prefix=/usr       \
             --disable-static    &&
make

# --- bloco 2 [teste]
echo '>>> bloco 2 (teste)'
if ! (
make -k check
); then echo '[AVISO-TESTE] bloco 2 terminou com falhas'; fi

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

