# Gerado de BLFS 12.4 x/libxcb.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure $XORG_CONFIG      \
            --without-doxygen \
            --docdir='${datadir}'/doc/libxcb-1.17.0 &&
LC_ALL=en_US.UTF-8 make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

# --- bloco 3 (root)
echo '>>> bloco 3'
chown -Rv root:root $XORG_PREFIX/share/doc/libxcb-1.17.0

