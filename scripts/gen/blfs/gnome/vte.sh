# Gerado de BLFS 12.4 gnome/vte.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: GnuTLS, GTK-4 e Vala não estão instalados: + -D gnutls=false -D gtk4=false -D vapi=false]
mkdir build &&
cd    build &&

meson setup ..                \
      --prefix=/usr           \
      --buildtype=release     \
      -D _systemd=false       \
      -D gnutls=false         \
      -D gtk4=false           \
      -D vapi=false           &&
ninja

# --- bloco 2 [omitido: documentação API precisa de Gi-DocGen (não instalado)]
#   sed -e "/docdir =/s@\$@/ 'vte-0.80.3'@" \
#       -i ../doc/reference/meson.build     &&
#   meson configure -D docs=true            &&
#   ninja

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install &&
rm -v /etc/profile.d/vte.*

