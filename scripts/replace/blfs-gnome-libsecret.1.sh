mkdir bld &&
cd    bld &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D gtk_doc=false    \
            -D manpage=false    \
            -D vapi=false       \
            ..                  &&
ninja
