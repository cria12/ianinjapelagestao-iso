# Gerado de LFS 12.4 chapter06/coreutils.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make DESTDIR=$LFS install

# --- bloco 4 (userinput)
echo '>>> bloco 4'
mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8

