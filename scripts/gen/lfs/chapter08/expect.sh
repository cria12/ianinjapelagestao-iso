# Gerado de LFS 12.4 chapter08/expect.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
python3 -c 'from pty import spawn; spawn(["echo", "ok"])'

# --- bloco 2 (userinput)
echo '>>> bloco 2'
patch -Np1 -i ../expect-5.45.4-gcc15-1.patch

# --- bloco 3 (userinput)
echo '>>> bloco 3'
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make

# --- bloco 5 [teste]
echo '>>> bloco 5 (teste)'
if ! (
make test
); then echo '[AVISO-TESTE] bloco 5 terminou com falhas'; fi

# --- bloco 6 (userinput)
echo '>>> bloco 6'
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib

