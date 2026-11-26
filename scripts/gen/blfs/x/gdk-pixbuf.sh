# Gerado de BLFS 12.4 x/gdk-pixbuf.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D others=enabled   \
      --wrap-mode=nofallback &&
ninja

# --- bloco 2 [omitido: documentação da API: precisa de Gi-DocGen (não instalado)]
#   sed "/docs_dir =/s@\$@ / 'gdk-pixbuf-2.42.12'@" -i ../docs/meson.build &&
#   meson configure -D gtk_doc=true                                        &&
#   ninja

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install

# --- bloco 4 (root)
echo '>>> bloco 4'
gdk-pixbuf-query-loaders --update-cache

