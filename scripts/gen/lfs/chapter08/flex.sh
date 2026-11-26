# Gerado de LFS 12.4 chapter08/flex.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static

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
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1

