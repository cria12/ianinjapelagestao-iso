# Gerado de LFS 12.4 chapter08/openssl.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make

# --- bloco 3 [teste]
echo '>>> bloco 3 (teste)'
if ! (
HARNESS_JOBS=$(nproc) make test
); then echo '[AVISO-TESTE] bloco 3 terminou com falhas'; fi

# --- bloco 4 (userinput)
echo '>>> bloco 4'
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install

# --- bloco 5 (userinput)
echo '>>> bloco 5'
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.5.2

# --- bloco 6 (userinput)
echo '>>> bloco 6'
cp -vfr doc/* /usr/share/doc/openssl-3.5.2

