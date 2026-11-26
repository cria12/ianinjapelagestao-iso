# Gerado de BLFS 12.4 general/bubblewrap.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sed 's@symlink usr/lib64@ro-bind-try /lib64@' -i ../tests/libtest.sh

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install

