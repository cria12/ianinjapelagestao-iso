# Gerado de BLFS 12.4 general/libical.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: sem Vala: -D ICAL_GLIB_VAPI=false (GObject Introspection mantém-se)]
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr  \
      -D CMAKE_BUILD_TYPE=Release   \
      -D SHARED_ONLY=yes            \
      -D ICAL_BUILD_DOCS=false      \
      -D GOBJECT_INTROSPECTION=true \
      -D ICAL_GLIB_VAPI=false       \
      .. &&
make -j1

# --- bloco 2 [omitido: documentação da API precisa de Doxygen (não instalado)]
#   make docs

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

# --- bloco 4 [omitido: documentação da API precisa de Doxygen (não instalado)]
#   install -vdm755 /usr/share/doc/libical-3.0.20/html &&
#   cp -vr apidocs/html/* /usr/share/doc/libical-3.0.20/html

