mkdir build &&
cd    build &&
meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D gtk_doc=false    \
      -D libnma_gtk4=false \
      -D vapi=false       \
      -D mobile_broadband_provider_info=false &&
ninja
