sed -i 's:"/desktop:"/org:' schema/*.xml &&
mkdir build &&
cd    build &&
meson setup --prefix=/usr       \
            --buildtype=release \
            -D gtk_doc=false    \
            -D ssh_agent=false  \
            -D introspection=false \
            ..                  &&
ninja
