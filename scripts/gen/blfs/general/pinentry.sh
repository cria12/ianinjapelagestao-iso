# Gerado de BLFS 12.4 general/pinentry.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i "/FLTK 1/s/3/4/" configure   &&
sed -i '14456 s/1.3/1.4/' configure

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr          \
            --enable-pinentry-tty  &&
make

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

