# Gerado de LFS 12.4 chapter07/util-linux.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir -pv /var/lib/hwclock

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --libdir=/usr/lib     \
            --runstatedir=/run    \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-static      \
            --disable-liblastlog2 \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.41.1

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make install

