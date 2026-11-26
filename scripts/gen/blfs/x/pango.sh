# Gerado de BLFS 12.4 x/pango.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup --prefix=/usr            \
            --buildtype=release      \
            --wrap-mode=nofallback   \
            -D introspection=enabled \
            ..                       &&
ninja

# --- bloco 2 [omitido: documentação da API: precisa de Gi-DocGen (não instalado)]
#   sed "/docs_dir =/s@\$@ / 'pango-1.56.4'@" -i ../docs/meson.build &&
#   meson configure -D documentation=true                            &&
#   ninja

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install

