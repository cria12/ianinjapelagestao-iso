# Gerado de BLFS 12.4 general/libxml2.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-static  \
            --with-history    \
            --with-icu        \
            PYTHON=/usr/bin/python3 \
            --docdir=/usr/share/doc/libxml2-2.14.5 &&
make

# --- bloco 2 [omitido: suite de testes opcional (xmlts20130923.tar.gz) não descarregada; não há "make check"]
#   tar xf ../xmlts20130923.tar.gz

# --- bloco 3 [omitido: /etc/init.d/httpd stop: não há servidor web (e não se correm os testes)]
#   /etc/init.d/httpd stop

# --- bloco 4 (root)
echo '>>> bloco 4'
make install

# --- bloco 5 (root)
echo '>>> bloco 5'
rm -vf /usr/lib/libxml2.la &&
sed '/libs=/s/xml2.*/xml2"/' -i /usr/bin/xml2-config

