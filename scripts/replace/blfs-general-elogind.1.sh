mkdir build &&
cd    build &&

meson setup ..                               \
      --prefix=/usr                          \
      --buildtype=release                    \
      -D man=false                           \
      -D docdir=/usr/share/doc/elogind-255.17 \
      -D cgroup-controller=elogind           \
      -D dev-kvm-mode=0660                   \
      -D dbuspolicydir=/etc/dbus-1/system.d &&
ninja
