# Gerado de BLFS 12.4 general/newt.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: sem --with-gpm-support (o GPM não está instalado: rato na consola desnecessário para o nmtui)]
sed -e '/install -m 644 $(LIBNEWT)/ s/^/#/' \
    -e '/$(LIBNEWT):/,/rv/ s/^/#/'          \
    -e 's/$(LIBNEWT)/$(LIBNEWTSH)/g'        \
    -i Makefile.in                          &&
./configure --prefix=/usr      \
            --with-python=python3.13 &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

