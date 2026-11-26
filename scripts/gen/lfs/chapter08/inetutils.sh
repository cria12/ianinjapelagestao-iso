# Gerado de LFS 12.4 chapter08/inetutils.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make

# --- bloco 4 [teste]
echo '>>> bloco 4 (teste)'
if ! (
make check
); then echo '[AVISO-TESTE] bloco 4 terminou com falhas'; fi

# --- bloco 5 (userinput)
echo '>>> bloco 5'
make install

# --- bloco 6 (userinput)
echo '>>> bloco 6'
mv -v /usr/{,s}bin/ifconfig

