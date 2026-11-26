mkdir build &&
cd    build &&

meson setup ..                 \
      --prefix=$XORG_PREFIX    \
      --buildtype=release      \
      -D platforms=x11         \
      -D gallium-drivers=iris,crocus,i915,radeonsi,r600,r300,nouveau,svga,virgl,llvmpipe,softpipe \
      -D vulkan-drivers=""     \
      -D valgrind=disabled     \
      -D libunwind=disabled    &&

ninja
