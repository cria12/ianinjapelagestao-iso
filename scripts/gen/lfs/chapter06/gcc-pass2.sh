# Gerado de LFS 12.4 chapter06/gcc-pass2.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
tar -xf ../mpfr-4.2.2.tar.xz
mv -v mpfr-4.2.2 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

# --- bloco 2 (userinput)
echo '>>> bloco 2'
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

# --- bloco 3 (userinput)
echo '>>> bloco 3'
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

# --- bloco 4 (userinput)
echo '>>> bloco 4'
mkdir -v build
cd       build

# --- bloco 5 (userinput)
echo '>>> bloco 5'
../configure                   \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --target=$LFS_TGT          \
    --prefix=/usr              \
    --with-build-sysroot=$LFS  \
    --enable-default-pie       \
    --enable-default-ssp       \
    --disable-nls              \
    --disable-multilib         \
    --disable-libatomic        \
    --disable-libgomp          \
    --disable-libquadmath      \
    --disable-libsanitizer     \
    --disable-libssp           \
    --disable-libvtv           \
    --enable-languages=c,c++   \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc

# --- bloco 6 (userinput)
echo '>>> bloco 6'
make

# --- bloco 7 (userinput)
echo '>>> bloco 7'
make DESTDIR=$LFS install

# --- bloco 8 (userinput)
echo '>>> bloco 8'
ln -sv gcc $LFS/usr/bin/cc

