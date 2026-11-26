mkdir build &&
cd    build &&
meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D appindicator=no  \
      -D selinux=false    \
      -D team=false       \
      -D wwan=false       &&
ninja
