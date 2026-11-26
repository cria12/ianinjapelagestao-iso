mkdir build &&
cd    build &&
meson setup ..                    \
      --prefix=/usr               \
      --buildtype=release         \
      -D libaudit=no              \
      -D nmtui=true               \
      -D ovs=false                \
      -D ppp=false                \
      -D nbft=false               \
      -D selinux=false            \
      -D session_tracking=elogind \
      -D modem_manager=false      \
      -D systemdsystemunitdir=no  \
      -D systemd_journal=false    \
      -D nm_cloud_setup=false     \
      -D qt=false                 \
      -D vapi=false               \
      -D tests=no                 &&
ninja
