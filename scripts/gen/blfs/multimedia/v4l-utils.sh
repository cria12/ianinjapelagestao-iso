# Gerado de BLFS 12.4 multimedia/v4l-utils.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i '/^ir_bpf_enabled/s/=.*/= false/' utils/keytable/meson.build

# --- bloco 2 (userinput)
echo '>>> bloco 2'
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D gconv=disabled   \
      -D doxygen-doc=disabled &&
ninja

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install

# --- bloco 4 [substituído: o v4l2gl só é compilado com GLU (não instalado): copiar só os programas que existam]
for prog in v4l2gl v4l2grab
do
   if [ -f contrib/test/$prog ]; then cp -v contrib/test/$prog /usr/bin; fi
done

