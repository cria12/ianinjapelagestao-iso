# Gerado de BLFS 12.4 basicnet/lynx.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr           \
            --sysconfdir=/etc/lynx  \
            --with-zlib             \
            --with-bzlib            \
            --with-ssl              \
            --with-screen=ncursesw  \
            --enable-locale-charset \
            --datadir=/usr/share/doc/lynx-2.9.2 &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install-full
chgrp -v -R root /usr/share/doc/lynx-2.9.2/lynx_doc

# --- bloco 3 (root)
echo '>>> bloco 3'
sed -e '/#LOCALE/     a LOCALE_CHARSET:TRUE'     \
    -i /etc/lynx/lynx.cfg

# --- bloco 4 (root)
echo '>>> bloco 4'
sed -e '/#DEFAULT_ED/ a DEFAULT_EDITOR:vi'       \
    -i /etc/lynx/lynx.cfg

# --- bloco 5 (root)
echo '>>> bloco 5'
sed -e '/#PERSIST/    a PERSISTENT_COOKIES:TRUE' \
    -i /etc/lynx/lynx.cfg

