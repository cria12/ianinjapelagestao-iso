# Gerado de BLFS 12.4 postlfs/gnutls.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr \
            --docdir=/usr/share/doc/gnutls-3.8.10 \
            --with-default-trust-store-pkcs11="pkcs11:" &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

