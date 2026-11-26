# Gerado de BLFS 12.4 general/icu.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: exemplos com <application or library> (ldd/readelf), não são comandos]
#   ldd <application or library> 

# --- bloco 2 [omitido: exemplos com <application or library> (ldd/readelf), não são comandos]
#   readelf -d  <application or library> | grep NEEDED

# --- bloco 3 (userinput)
echo '>>> bloco 3'
case $(uname -m) in
  i?86) sed -e "s/U_PLATFORM_IS_LINUX_BASED/__X86_64__ \&\& &/" \
            -i source/test/intltest/ustrtest.cpp ;;
esac

# --- bloco 4 (userinput)
echo '>>> bloco 4'
cd source                 &&
./configure --prefix=/usr &&
make

# --- bloco 5 (root)
echo '>>> bloco 5'
make install

