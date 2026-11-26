# Gerado de BLFS 12.4 general/libpng.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: patch APNG opcional (só o Firefox/Thunderbird o usam) — não descarregado]
#   gzip -cd ../libpng-1.6.47-apng.patch.gz | patch -p1

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr --disable-static &&
make

# --- bloco 3 (root)
echo '>>> bloco 3'
make install &&
mkdir -v /usr/share/doc/libpng-1.6.50 &&
cp -v README libpng-manual.txt /usr/share/doc/libpng-1.6.50

