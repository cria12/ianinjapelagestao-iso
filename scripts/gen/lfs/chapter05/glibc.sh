# Gerado de LFS 12.4 chapter05/glibc.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac

# --- bloco 2 (userinput)
echo '>>> bloco 2'
patch -Np1 -i ../glibc-2.42-fhs-1.patch

# --- bloco 3 (userinput)
echo '>>> bloco 3'
mkdir -v build
cd       build

# --- bloco 4 (userinput)
echo '>>> bloco 4'
echo "rootsbindir=/usr/sbin" > configparms

# --- bloco 5 (userinput)
echo '>>> bloco 5'
../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib           \
      --enable-kernel=5.4

# --- bloco 6 (userinput)
echo '>>> bloco 6'
make

# --- bloco 7 (userinput)
echo '>>> bloco 7'
make DESTDIR=$LFS install

# --- bloco 8 (userinput)
echo '>>> bloco 8'
sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

# --- bloco 9 (userinput)
echo '>>> bloco 9'
echo 'int main(){}' | $LFS_TGT-gcc -x c - -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

# --- bloco 10 (userinput)
echo '>>> bloco 10'
grep -E -o "$LFS/lib.*/S?crt[1in].*succeeded" dummy.log

# --- bloco 11 (userinput)
echo '>>> bloco 11'
grep -B3 "^ $LFS/usr/include" dummy.log

# --- bloco 12 (userinput)
echo '>>> bloco 12'
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'

# --- bloco 13 (userinput)
echo '>>> bloco 13'
grep "/lib.*/libc.so.6 " dummy.log

# --- bloco 14 (userinput)
echo '>>> bloco 14'
grep found dummy.log

# --- bloco 15 (userinput)
echo '>>> bloco 15'
rm -v a.out dummy.log

