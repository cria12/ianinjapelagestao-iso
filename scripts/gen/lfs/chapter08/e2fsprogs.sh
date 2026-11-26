# Gerado de LFS 12.4 chapter08/e2fsprogs.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir -v build
cd       build

# --- bloco 2 (userinput)
echo '>>> bloco 2'
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-elf-shlibs \
             --disable-libblkid  \
             --disable-libuuid   \
             --disable-uuidd     \
             --disable-fsck

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
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

# --- bloco 7 (userinput)
echo '>>> bloco 7'
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

# --- bloco 8 (userinput)
echo '>>> bloco 8'
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

# --- bloco 9 (userinput)
echo '>>> bloco 9'
sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf

