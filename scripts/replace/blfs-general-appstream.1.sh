sed -i "/^subdir(.docs\/.)/d" meson.build &&
mkdir build &&
cd    build &&
meson setup --prefix=/usr       \
            --buildtype=release \
            -D apidocs=false    \
            -D docs=false       \
            -D install-docs=false \
            -D stemming=false   .. &&
ninja
