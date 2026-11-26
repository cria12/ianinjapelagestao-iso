# Gerado de LFS 12.4 chapter08/gcc.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

# --- bloco 2 (userinput)
echo '>>> bloco 2'
mkdir -v build
cd       build

# --- bloco 3 (userinput)
echo '>>> bloco 3'
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make

# --- bloco 5 (userinput)
echo '>>> bloco 5'
ulimit -s -H unlimited

# --- bloco 6 (userinput)
echo '>>> bloco 6'
sed -e '/cpython/d' -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp

# --- bloco 7 [teste]
echo '>>> bloco 7 (teste)'
if ! (
chown -R tester .
su tester -c "PATH=$PATH make -k check"
); then echo '[AVISO-TESTE] bloco 7 terminou com falhas'; fi

# --- bloco 8 (userinput)
echo '>>> bloco 8'
../contrib/test_summary

# --- bloco 9 (userinput)
echo '>>> bloco 9'
make install

# --- bloco 10 (userinput)
echo '>>> bloco 10'
chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/15.2.0/include{,-fixed}

# --- bloco 11 (userinput)
echo '>>> bloco 11'
ln -svr /usr/bin/cpp /usr/lib

# --- bloco 12 (userinput)
echo '>>> bloco 12'
ln -sv gcc.1 /usr/share/man/man1/cc.1

# --- bloco 13 (userinput)
echo '>>> bloco 13'
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/15.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

# --- bloco 14 (userinput)
echo '>>> bloco 14'
echo 'int main(){}' | cc -x c - -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

# --- bloco 15 (userinput)
echo '>>> bloco 15'
grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log

# --- bloco 16 (userinput)
echo '>>> bloco 16'
grep -B4 '^ /usr/include' dummy.log

# --- bloco 17 (userinput)
echo '>>> bloco 17'
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'

# --- bloco 18 (userinput)
echo '>>> bloco 18'
grep "/lib.*/libc.so.6 " dummy.log

# --- bloco 19 (userinput)
echo '>>> bloco 19'
grep found dummy.log

# --- bloco 20 (userinput)
echo '>>> bloco 20'
rm -v a.out dummy.log

# --- bloco 21 (userinput)
echo '>>> bloco 21'
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

