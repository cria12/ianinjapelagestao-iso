# Gerado de LFS 12.4 chapter08/kmod.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir -p build
cd       build

meson setup --prefix=/usr ..    \
            --buildtype=release \
            -D manpages=false

# --- bloco 2 (userinput)
echo '>>> bloco 2'
ninja

# --- bloco 3 (userinput)
echo '>>> bloco 3'
ninja install

