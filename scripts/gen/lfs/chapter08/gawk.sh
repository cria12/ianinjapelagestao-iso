# Gerado de LFS 12.4 chapter08/gawk.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i 's/extras//' Makefile.in

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make

# --- bloco 4 [teste]
echo '>>> bloco 4 (teste)'
if ! (
chown -R tester .
su tester -c "PATH=$PATH make check"
); then echo '[AVISO-TESTE] bloco 4 terminou com falhas'; fi

# --- bloco 5 (userinput)
echo '>>> bloco 5'
rm -f /usr/bin/gawk-5.3.2
make install

# --- bloco 6 (userinput)
echo '>>> bloco 6'
ln -sv gawk.1 /usr/share/man/man1/awk.1

# --- bloco 7 (userinput)
echo '>>> bloco 7'
install -vDm644 doc/{awkforai.txt,*.{eps,pdf,jpg}} -t /usr/share/doc/gawk-5.3.2

