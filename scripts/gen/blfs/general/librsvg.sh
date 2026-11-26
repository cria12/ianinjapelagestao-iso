# Gerado de BLFS 12.4 general/librsvg.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -e "/OUTDIR/s|,| / 'librsvg-2.61.0', '--no-namespace-dir',|" \
    -e '/output/s|Rsvg-2.0|librsvg-2.61.0|'                      \
    -i doc/meson.build

# --- bloco 2 (userinput)
echo '>>> bloco 2'
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- bloco 3 [teste]
echo '>>> bloco 3 (teste)'
if ! (
ninja test
); then echo '[AVISO-TESTE] bloco 3 terminou com falhas'; fi

# --- bloco 4 (root)
echo '>>> bloco 4'
ninja install

