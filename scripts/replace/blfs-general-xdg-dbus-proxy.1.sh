mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D man=disabled .. &&
ninja
