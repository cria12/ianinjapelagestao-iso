# Gerado de LFS 12.4 chapter08/mpfr.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.2

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make
make html

# --- bloco 3 [teste]
echo '>>> bloco 3 (teste)'
if ! (
make check
); then echo '[AVISO-TESTE] bloco 3 terminou com falhas'; fi

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make install
make install-html

