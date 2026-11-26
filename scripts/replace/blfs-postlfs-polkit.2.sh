mkdir build &&
cd    build &&

meson setup ..                     \
      --prefix=/usr                \
      --buildtype=release          \
      -D man=false                 \
      -D session_tracking=elogind  \
      -D systemdsystemunitdir=/tmp \
      -D tests=false
