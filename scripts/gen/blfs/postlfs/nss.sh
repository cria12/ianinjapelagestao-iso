# Gerado de BLFS 12.4 postlfs/nss.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
patch -Np1 -i ../nss-standalone-1.patch &&

cd nss &&

make BUILD_OPT=1                      \
  NSPR_INCLUDE_DIR=/usr/include/nspr  \
  USE_SYSTEM_ZLIB=1                   \
  ZLIB_LIBS=-lz                       \
  NSS_ENABLE_WERROR=0                 \
  $([ $(uname -m) = x86_64 ] && echo USE_64=1) \
  $([ -f /usr/include/sqlite3.h ] && echo NSS_USE_SYSTEM_SQLITE=1)

# --- bloco 2 [omitido: testes (all.sh) precisam de rede e de um nome de máquina resolúvel; o chroot não tem rede]
#   cd tests &&
#   HOST=localhost DOMSUF=localdomain ./all.sh
#   cd ../

# --- bloco 3 (root)
echo '>>> bloco 3'
cd ../dist                                                          &&

install -v -m755 Linux*/lib/*.so              /usr/lib              &&
install -v -m644 Linux*/lib/{*.chk,libcrmf.a} /usr/lib              &&

install -v -m755 -d                           /usr/include/nss      &&
cp -v -RL {public,private}/nss/*              /usr/include/nss      &&

install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} /usr/bin &&

install -v -m644 Linux*/lib/pkgconfig/nss.pc  /usr/lib/pkgconfig

# --- bloco 4 (root)
echo '>>> bloco 4'
ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so

