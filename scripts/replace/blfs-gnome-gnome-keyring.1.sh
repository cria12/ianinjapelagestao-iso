sed -i 's:"/desktop:"/org:' schema/*.xml &&

mkdir build-gkr &&
cd    build-gkr &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D systemd=disabled \
      -D manpage=false    \
      -D ssh-agent=true   &&
ninja
