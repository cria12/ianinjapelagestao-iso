# Gerado de BLFS 12.4 general/freetype2.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: documentação adicional (freetype-doc) — omitida para poupar espaço na ISO]
#   tar -xf ../freetype-doc-2.13.3.tar.xz --strip-components=2 -C docs

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&

sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h  &&

./configure --prefix=/usr --enable-freetype-config --disable-static &&
make

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

# --- bloco 4 [omitido: documentação adicional (freetype-doc) — omitida para poupar espaço na ISO]
#   cp -v -R docs -T /usr/share/doc/freetype-2.13.3 &&
#   rm -v /usr/share/doc/freetype-2.13.3/freetype-config.1

