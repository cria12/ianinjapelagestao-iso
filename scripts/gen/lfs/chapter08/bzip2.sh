# Gerado de LFS 12.4 chapter08/bzip2.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile

# --- bloco 3 (userinput)
echo '>>> bloco 3'
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make -f Makefile-libbz2_so
make clean

# --- bloco 5 (userinput)
echo '>>> bloco 5'
make

# --- bloco 6 (userinput)
echo '>>> bloco 6'
make PREFIX=/usr install

# --- bloco 7 (userinput)
echo '>>> bloco 7'
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so

# --- bloco 8 (userinput)
echo '>>> bloco 8'
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done

# --- bloco 9 (userinput)
echo '>>> bloco 9'
rm -fv /usr/lib/libbz2.a

