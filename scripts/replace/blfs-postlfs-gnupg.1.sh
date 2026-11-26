mkdir build &&
cd    build &&
../configure --prefix=/usr        \
             --localstatedir=/var \
             --sysconfdir=/etc    \
             --disable-ldap       \
             --docdir=/usr/share/doc/gnupg-2.4.8 &&
make &&
makeinfo --html --no-split -I doc -o doc/gnupg_nochunks.html ../doc/gnupg.texi &&
makeinfo --plaintext       -I doc -o doc/gnupg.txt           ../doc/gnupg.texi &&
make -C doc html
