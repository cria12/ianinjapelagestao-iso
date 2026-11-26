# Gerado de BLFS 12.4 general/glib2.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: patch opcional glib-skip_warnings (GLIB_LOG_LEVEL) — não descarregado]
#   patch -Np1 -i ../glib-skip_warnings-1.patch

# --- bloco 2 (root)
echo '>>> bloco 2'
if [ -e /usr/include/glib-2.0 ]; then
    rm -rf /usr/include/glib-2.0.old &&
    mv -vf /usr/include/glib-2.0{,.old}
fi

# --- bloco 3 (userinput)
echo '>>> bloco 3'
mkdir build &&
cd    build &&

meson setup ..                  \
      --prefix=/usr             \
      --buildtype=release       \
      -D introspection=disabled \
      -D glib_debug=disabled    \
      -D man-pages=enabled      \
      -D sysprof=disabled       &&
ninja

# --- bloco 4 (root)
echo '>>> bloco 4'
ninja install

# --- bloco 5 (userinput)
echo '>>> bloco 5'
tar xf ../../gobject-introspection-1.84.0.tar.xz &&

meson setup gobject-introspection-1.84.0 gi-build \
            --prefix=/usr --buildtype=release     &&
ninja -C gi-build

# --- bloco 6 (root)
echo '>>> bloco 6'
ninja -C gi-build install

# --- bloco 7 (userinput)
echo '>>> bloco 7'
meson configure -D introspection=enabled &&
ninja

# --- bloco 8 [omitido: documentação da API precisa de gi-docgen (não instalado); o bloco 9 faz o ninja install final]
#   sed "/docs_dir =/s|$| / 'glib-' + meson.project_version()|" \
#       -i ../docs/reference/meson.build                        &&
#   meson configure -D documentation=true                       &&
#   ninja

# --- bloco 9 (root)
echo '>>> bloco 9'
ninja install

