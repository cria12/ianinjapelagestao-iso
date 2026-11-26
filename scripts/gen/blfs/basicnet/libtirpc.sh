# Gerado de BLFS 12.4 basicnet/libtirpc.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
patch -Np1 -i ../libtirpc-1.3.6-gcc15_fixes-1.patch

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-static  \
            --disable-gssapi  &&
make

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

