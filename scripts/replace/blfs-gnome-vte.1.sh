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
