# Gerado de BLFS 12.4 basicnet/network-manager-applet.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: + -D wwan=false (ModemManager não instalado, como explica o livro)]
mkdir build &&
cd    build &&
meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D appindicator=no  \
      -D selinux=false    \
      -D team=false       \
      -D wwan=false       &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

