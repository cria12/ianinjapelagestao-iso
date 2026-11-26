# Gerado de LFS 12.4 chapter08/sed.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make
make html

# --- bloco 3 [teste]
echo '>>> bloco 3 (teste)'
if ! (
chown -R tester .
su tester -c "PATH=$PATH make check"
); then echo '[AVISO-TESTE] bloco 3 terminou com falhas'; fi

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9

