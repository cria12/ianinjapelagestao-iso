# Gerado de BLFS 12.4 basicnet/libnl.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-static  &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

# --- bloco 3 [omitido: documentação API (libnl-doc, download adicional) — omitida para poupar espaço na ISO]
#   mkdir -vp /usr/share/doc/libnl-3.11.0 &&
#   tar -xf ../libnl-doc-3.11.0.tar.gz --strip-components=1 --no-same-owner \
#       -C  /usr/share/doc/libnl-3.11.0

