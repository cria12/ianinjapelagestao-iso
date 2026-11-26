# Gerado de LFS 12.4 chapter08/gmp.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: exemplo "ABI=32 ./configure ..." só para CPUs de 32 bits (não é um comando)]
#   ABI=32 ./configure ...

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sed -i '/long long t1;/,+1s/()/(...)/' configure

# --- bloco 3 (userinput)
echo '>>> bloco 3'
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make
make html

# --- bloco 5 [teste]
echo '>>> bloco 5 (teste)'
if ! (
make check 2>&1 | tee gmp-check-log
); then echo '[AVISO-TESTE] bloco 5 terminou com falhas'; fi

# --- bloco 6 (userinput)
echo '>>> bloco 6'
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log

# --- bloco 7 (userinput)
echo '>>> bloco 7'
make install
make install-html

