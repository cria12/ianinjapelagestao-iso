# Gerado de BLFS 12.4 gnome/libsecret.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: sem Vala (VAPI) nem docbook-xsl (páginas de manual): + -D vapi=false -D manpage=false]
mkdir bld &&
cd    bld &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D gtk_doc=false    \
            -D manpage=false    \
            -D vapi=false       \
            ..                  &&
ninja

# --- bloco 2 [omitido: documentação da API precisa de gi-docgen (não instalado)]
#   sed "s/api_version_major/'0.21.7'/"            \
#       -i ../docs/reference/libsecret/meson.build &&
#   meson configure -D gtk_doc=true                &&
#   ninja

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install

