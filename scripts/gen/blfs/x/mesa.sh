# Gerado de BLFS 12.4 x/mesa.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: lspci | grep VGA: só informativo (a ISO leva drivers para todo o hardware comum)]
#   lspci | grep VGA

# --- bloco 2 (userinput)
echo '>>> bloco 2'
patch -Np1 -i ../mesa-add_xdemos-4.patch

# --- bloco 3 [substituído: drivers Gallium explícitos, sem Vulkan (glslang/Vulkan-Loader não instalados), só X11 (Wayland ainda não instalado), sem codecs com patentes]
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

# --- bloco 4 [omitido: suite de testes (+1.7 SBU e 576 MB) — omitida para poupar tempo]
#   meson configure -D build-tests=true &&
#   sed '/float rsqrtf/,/^}/d' \
#       -i ../src/gallium/drivers/llvmpipe/lp_test_arit.c &&
#   ninja test

# --- bloco 5 (root)
echo '>>> bloco 5'
ninja install

# --- bloco 6 [omitido: documentação HTML — omitida para poupar espaço na ISO]
#   cp -rv ../docs -T /usr/share/doc/mesa-25.1.8

