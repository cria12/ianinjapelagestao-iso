# Gerado de LFS 12.4 chapter08/readline.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf

# --- bloco 3 (userinput)
echo '>>> bloco 3'
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.3

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make SHLIB_LIBS="-lncursesw"

# --- bloco 5 (userinput)
echo '>>> bloco 5'
make install

# --- bloco 6 (userinput)
echo '>>> bloco 6'
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.3

