# Gerado de LFS 12.4 chapter08/glibc.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
patch -Np1 -i ../glibc-2.42-fhs-1.patch

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sed -e '/unistd.h/i #include <string.h>' \
    -e '/libc_rwlock_init/c\
  __libc_rwlock_define_initialized (, reset_lock);\
  memcpy (&lock, &reset_lock, sizeof (lock));' \
    -i stdlib/abort.c 

# --- bloco 3 (userinput)
echo '>>> bloco 3'
mkdir -v build
cd       build

# --- bloco 4 (userinput)
echo '>>> bloco 4'
echo "rootsbindir=/usr/sbin" > configparms

# --- bloco 5 (userinput)
echo '>>> bloco 5'
../configure --prefix=/usr                   \
             --disable-werror                \
             --disable-nscd                  \
             libc_cv_slibdir=/usr/lib        \
             --enable-stack-protector=strong \
             --enable-kernel=5.4

# --- bloco 6 (userinput)
echo '>>> bloco 6'
make

# --- bloco 7 [teste]
echo '>>> bloco 7 (teste)'
if ! (
make check
); then echo '[AVISO-TESTE] bloco 7 terminou com falhas'; fi

# --- bloco 8 [teste]
echo '>>> bloco 8 (teste)'
if ! (
grep "Timed out" $(find -name \*.out)
); then echo '[AVISO-TESTE] bloco 8 terminou com falhas'; fi

# --- bloco 9 (userinput)
echo '>>> bloco 9'
touch /etc/ld.so.conf

# --- bloco 10 (userinput)
echo '>>> bloco 10'
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

# --- bloco 11 (userinput)
echo '>>> bloco 11'
rm -f /usr/sbin/nscd

# --- bloco 12 (userinput)
echo '>>> bloco 12'
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/*.so.* /usr/lib

# --- bloco 13 (userinput)
echo '>>> bloco 13'
DIR=$(dirname $(gcc -print-libgcc-file-name))
[ -e $DIR/include/limits.h ]    || mv $DIR/include{-fixed,}/limits.h
[ -e $DIR/include/syslimits.h ] || mv $DIR/include{-fixed,}/syslimits.h
rm -rfv $DIR/include-fixed/*
unset DIR

# --- bloco 14 (userinput)
echo '>>> bloco 14'
make install

# --- bloco 15 (userinput)
echo '>>> bloco 15'
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

# --- bloco 16 (userinput)
echo '>>> bloco 16'
localedef -i C -f UTF-8 C.UTF-8
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8

# --- bloco 17 [substituído: alternativa "instalar todos os locales" substituída pelos locales da distro (pt_PT.UTF-8, en_US.UTF-8)]
localedef -i pt_PT -f UTF-8 pt_PT.UTF-8
localedef -i pt_PT -f ISO-8859-1 pt_PT
localedef -i pt_PT@euro -f ISO-8859-15 pt_PT@euro

# --- bloco 18 (userinput)
echo '>>> bloco 18'
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

# --- bloco 19 (userinput)
echo '>>> bloco 19'
tar -xf ../../tzdata2025b.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO tz

# --- bloco 20 [omitido: tzselect é interativo; fuso já decidido: Europe/Lisbon]
#   tzselect

# --- bloco 21 [substituído: /usr/share/zoneinfo/<xxx> -> Europe/Lisbon]
ln -sfv /usr/share/zoneinfo/Europe/Lisbon /etc/localtime

# --- bloco 22 (userinput)
echo '>>> bloco 22'
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

# --- bloco 23 (userinput)
echo '>>> bloco 23'
cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

