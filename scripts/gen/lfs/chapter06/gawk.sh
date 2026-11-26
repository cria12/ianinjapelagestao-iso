# Gerado de LFS 12.4 chapter06/gawk.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i 's/extras//' Makefile.in

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make DESTDIR=$LFS install

