# Gerado de LFS 12.4 chapter08/procps-ng.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.5 \
            --disable-static                        \
            --disable-kill                          \
            --enable-watch8bit

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make

# --- bloco 3 [teste]
echo '>>> bloco 3 (teste)'
if ! (
chown -R tester .
su tester -c "PATH=$PATH make check"
); then echo '[AVISO-TESTE] bloco 3 terminou com falhas'; fi

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make install

