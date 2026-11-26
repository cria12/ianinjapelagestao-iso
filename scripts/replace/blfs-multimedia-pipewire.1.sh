mkdir build &&
cd    build &&
meson setup ..                 \
      --prefix=/usr            \
      --buildtype=release      \
      -D systemd=disabled      \
      -D session-managers="[]" &&
ninja
