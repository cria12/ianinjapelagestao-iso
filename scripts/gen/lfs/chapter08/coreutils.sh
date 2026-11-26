# Gerado de LFS 12.4 chapter08/coreutils.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
patch -Np1 -i ../coreutils-9.7-upstream_fix-1.patch

# --- bloco 2 (userinput)
echo '>>> bloco 2'
patch -Np1 -i ../coreutils-9.7-i18n-1.patch

# --- bloco 3 (userinput)
echo '>>> bloco 3'
autoreconf -fv
automake -af
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make

# --- bloco 5 [teste]
echo '>>> bloco 5 (teste)'
if ! (
make NON_ROOT_USERNAME=tester check-root
); then echo '[AVISO-TESTE] bloco 5 terminou com falhas'; fi

# --- bloco 6 (userinput)
echo '>>> bloco 6'
groupadd -g 102 dummy -U tester

# --- bloco 7 (userinput)
echo '>>> bloco 7'
chown -R tester . 

# --- bloco 8 [teste]
echo '>>> bloco 8 (teste)'
if ! (
su tester -c "PATH=$PATH make -k RUN_EXPENSIVE_TESTS=yes check" \
   < /dev/null
); then echo '[AVISO-TESTE] bloco 8 terminou com falhas'; fi

# --- bloco 9 (userinput)
echo '>>> bloco 9'
groupdel dummy

# --- bloco 10 (userinput)
echo '>>> bloco 10'
make install

# --- bloco 11 (userinput)
echo '>>> bloco 11'
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8

