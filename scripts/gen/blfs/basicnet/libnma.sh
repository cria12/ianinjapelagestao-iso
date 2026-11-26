# Gerado de BLFS 12.4 basicnet/libnma.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: -D libnma_gtk4=false (GTK4 não instalado) e -D vapi=false (sem Vala)]
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

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

