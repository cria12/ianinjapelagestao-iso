# Gerado de LFS 12.4 chapter08/dejagnu.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir -v build
cd       build

# --- bloco 2 (userinput)
echo '>>> bloco 2'
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

# --- bloco 3 [teste]
echo '>>> bloco 3 (teste)'
if ! (
make check
); then echo '[AVISO-TESTE] bloco 3 terminou com falhas'; fi

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

