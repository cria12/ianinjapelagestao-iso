# Gerado de BLFS 12.4 x/at-spi2-core.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup ..                  \
      --prefix=/usr             \
      --buildtype=release       \
      -D gtk2_atk_adaptor=false \
      -D systemd_user_dir=/tmp  &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install &&
rm /tmp/at-spi-dbus-bus.service

