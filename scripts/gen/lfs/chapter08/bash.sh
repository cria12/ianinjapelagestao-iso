# Gerado de LFS 12.4 chapter08/bash.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.3

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make

# --- bloco 3 (userinput)
echo '>>> bloco 3'
chown -R tester .

# --- bloco 4 [teste]
echo '>>> bloco 4 (teste)'
if ! (
LC_ALL=C.UTF-8 su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF
); then echo '[AVISO-TESTE] bloco 4 terminou com falhas'; fi

# --- bloco 5 (userinput)
echo '>>> bloco 5'
make install

# --- bloco 6 [omitido: exec /usr/bin/bash --login (interativo)]
#   exec /usr/bin/bash --login

