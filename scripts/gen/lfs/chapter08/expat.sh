# Gerado de LFS 12.4 chapter08/expat.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.7.1

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make

# --- bloco 3 [teste]
echo '>>> bloco 3 (teste)'
if ! (
make check
); then echo '[AVISO-TESTE] bloco 3 terminou com falhas'; fi

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make install

# --- bloco 5 (userinput)
echo '>>> bloco 5'
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.7.1

