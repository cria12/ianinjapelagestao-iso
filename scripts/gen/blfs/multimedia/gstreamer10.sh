# Gerado de BLFS 12.4 multimedia/gstreamer10.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D gst_debug=false  &&
ninja

# --- bloco 2 (userinput)
echo '>>> bloco 2'
rm -rf /usr/bin/gst-* /usr/{lib,libexec}/gstreamer-1.0

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install

