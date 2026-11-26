# Gerado de BLFS 12.4 general/json-glib.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- bloco 2 [omitido: páginas de manual (DocBook) e documentação (gi-docgen) não instalados]
#   meson configure -D man=true &&
#   ninja

# --- bloco 3 [omitido: páginas de manual (DocBook) e documentação (gi-docgen) não instalados]
#   sed "/json_docdir =/s|$| / 'json-glib-1.10.6'|" -i ../doc/meson.build &&
#   meson configure -D documentation=enabled &&
#   ninja

# --- bloco 4 (root)
echo '>>> bloco 4'
ninja install

