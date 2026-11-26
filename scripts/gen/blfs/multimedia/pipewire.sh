# Gerado de BLFS 12.4 multimedia/pipewire.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: -D systemd=disabled: o libsystemd.pc do elogind não tem sd-journal (plugin do journal); sem session manager, como o livro]
mkdir build &&
cd    build &&
meson setup ..                 \
      --prefix=/usr            \
      --buildtype=release      \
      -D systemd=disabled      \
      -D session-managers="[]" &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

