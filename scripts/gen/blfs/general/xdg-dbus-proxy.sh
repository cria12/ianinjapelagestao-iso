# Gerado de BLFS 12.4 general/xdg-dbus-proxy.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: -D man=disabled: a página de manual exige docbook-xsl (não instalado) e o xsltproc tentaria a rede]
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D man=disabled .. &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

