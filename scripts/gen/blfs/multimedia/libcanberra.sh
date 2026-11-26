# Gerado de BLFS 12.4 multimedia/libcanberra.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
patch -Np1 -i ../libcanberra-0.30-wayland-1.patch

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr --disable-oss &&
make

# --- bloco 3 (root)
echo '>>> bloco 3'
make docdir=/usr/share/doc/libcanberra-0.30 install

