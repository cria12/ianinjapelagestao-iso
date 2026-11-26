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
