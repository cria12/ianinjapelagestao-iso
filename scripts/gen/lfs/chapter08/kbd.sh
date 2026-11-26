# Gerado de LFS 12.4 chapter08/kbd.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
patch -Np1 -i ../kbd-2.8.0-backspace-1.patch

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

# --- bloco 3 (userinput)
echo '>>> bloco 3'
./configure --prefix=/usr --disable-vlock

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make

# --- bloco 5 (userinput)
echo '>>> bloco 5'
make install

# --- bloco 6 (userinput)
echo '>>> bloco 6'
cp -R -v docs/doc -T /usr/share/doc/kbd-2.8.0

