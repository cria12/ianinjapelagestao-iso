# Gerado de LFS 12.4 chapter08/binutils.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir -v build
cd       build

# --- bloco 2 (userinput)
echo '>>> bloco 2'
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --enable-new-dtags  \
             --with-system-zlib  \
             --enable-default-hash-style=gnu

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make tooldir=/usr

# --- bloco 4 [teste]
echo '>>> bloco 4 (teste)'
if ! (
make -k check
); then echo '[AVISO-TESTE] bloco 4 terminou com falhas'; fi

# --- bloco 5 [substituído: grep "^FAIL:" devolve 1 quando não há falhas -> "|| true" (lista as falhas sem parar a build)]
grep '^FAIL:' $(find -name '*.log') || true

# --- bloco 6 (userinput)
echo '>>> bloco 6'
make tooldir=/usr install

# --- bloco 7 (userinput)
echo '>>> bloco 7'
rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
        /usr/share/doc/gprofng/

