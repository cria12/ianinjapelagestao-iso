# Gerado de LFS 12.4 chapter08/perl.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
export BUILD_ZLIB=False
export BUILD_BZIP2=0

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sh Configure -des                                          \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D privlib=/usr/lib/perl5/5.42/core_perl      \
             -D archlib=/usr/lib/perl5/5.42/core_perl      \
             -D sitelib=/usr/lib/perl5/5.42/site_perl      \
             -D sitearch=/usr/lib/perl5/5.42/site_perl     \
             -D vendorlib=/usr/lib/perl5/5.42/vendor_perl  \
             -D vendorarch=/usr/lib/perl5/5.42/vendor_perl \
             -D man1dir=/usr/share/man/man1                \
             -D man3dir=/usr/share/man/man3                \
             -D pager="/usr/bin/less -isR"                 \
             -D useshrplib                                 \
             -D usethreads

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make

# --- bloco 4 [teste]
echo '>>> bloco 4 (teste)'
if ! (
TEST_JOBS=$(nproc) make test_harness
); then echo '[AVISO-TESTE] bloco 4 terminou com falhas'; fi

# --- bloco 5 (userinput)
echo '>>> bloco 5'
make install
unset BUILD_ZLIB BUILD_BZIP2

