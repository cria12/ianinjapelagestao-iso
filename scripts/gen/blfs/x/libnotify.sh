# Gerado de BLFS 12.4 x/libnotify.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D gtk_doc=false    \
            -D man=false        \
            ..                  &&
ninja

# --- bloco 2 [omitido: documentação API precisa de GTK-Doc (não instalado)]
#   sed "/docs_dir =/s@\$@ / 'libnotify'@" \
#       -i ../docs/reference/meson.build   &&
#   meson configure -D gtk_doc=true        &&
#   ninja

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install &&
if [ -e /usr/share/doc/libnotify ]; then
  rm -rf /usr/share/doc/libnotify-0.8.6
  mv -v  /usr/share/doc/libnotify{,-0.8.6}
fi

