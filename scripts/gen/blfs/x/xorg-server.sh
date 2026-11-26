# Gerado de BLFS 12.4 x/xorg-server.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: patch opcional TearFree: o xfwm4 do Xfce tem compositor (o livro só o aconselha sem compositor)]
#   patch -Np1 -i ../xorg-server-21.1.18-tearfree_backport-1.patch

# --- bloco 2 (userinput)
echo '>>> bloco 2'
mkdir build &&
cd    build &&

meson setup ..               \
      --prefix=$XORG_PREFIX  \
      --localstatedir=/var   \
      -D glamor=true         \
      -D systemd_logind=true \
      -D xkb_output_dir=/var/lib/xkb &&
ninja

# --- bloco 3 [substituído: acrescento ao /etc/sysconfig/createfiles só se ainda não existir (o passo pode ser repetido)]
ninja install &&
mkdir -pv /etc/X11/xorg.conf.d &&
install -v -d -m1777 /tmp/.{ICE,X11}-unix &&
if ! grep -q '^/tmp/.X11-unix' /etc/sysconfig/createfiles; then
cat >> /etc/sysconfig/createfiles << "EOF2"
/tmp/.ICE-unix dir 1777 root root
/tmp/.X11-unix dir 1777 root root
EOF2
fi

