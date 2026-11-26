# Gerado de BLFS 12.4 x/gtk3.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: -D man=false (sem docbook-xsl-nons as páginas de manual falham com xsltproc --nonet); x11 e wayland explícitos]
mkdir build &&
cd    build &&

meson setup ..                \
      --prefix=/usr           \
      --buildtype=release     \
      -D x11_backend=true     \
      -D wayland_backend=true \
      -D man=false            \
      -D broadway_backend=true &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

# --- bloco 3 (root)
echo '>>> bloco 3'
gtk-query-immodules-3.0 --update-cache

# --- bloco 4 (root)
echo '>>> bloco 4'
glib-compile-schemas /usr/share/glib-2.0/schemas

# --- bloco 5 [omitido: ~/.config/gtk-3.0 do utilizador: tema configurado em scripts/gui/tema]
#   mkdir -vp ~/.config/gtk-3.0
#   cat > ~/.config/gtk-3.0/settings.ini << "EOF"
#   [Settings]
#   gtk-theme-name = Adwaita
#   gtk-icon-theme-name = oxygen
#   gtk-font-name = DejaVu Sans 12
#   gtk-cursor-theme-size = 18
#   gtk-toolbar-style = GTK_TOOLBAR_BOTH_HORIZ
#   gtk-xft-antialias = 1
#   gtk-xft-hinting = 1
#   gtk-xft-hintstyle = hintslight
#   gtk-xft-rgba = rgb
#   gtk-cursor-theme-name = Adwaita
#   EOF

# --- bloco 6 [omitido: ~/.config/gtk-3.0 do utilizador: tema configurado em scripts/gui/tema]
#   cat > ~/.config/gtk-3.0/gtk.css << "EOF"
#   *  {
#      -GtkScrollbar-has-backward-stepper: 1;
#      -GtkScrollbar-has-forward-stepper: 1;
#   }
#   EOF

