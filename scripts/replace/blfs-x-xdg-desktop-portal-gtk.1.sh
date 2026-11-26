mkdir build &&
cd    build &&
meson setup --prefix=/usr --buildtype=release \
            -D wallpaper=disabled             \
            -D settings=enabled               \
            -D appchooser=enabled             \
            -D lockdown=enabled .. &&
ninja
