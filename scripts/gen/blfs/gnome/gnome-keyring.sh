# Gerado de BLFS 12.4 gnome/gnome-keyring.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: -D manpage=false: as páginas de manual exigem docbook-xsl (não instalado) e o xsltproc tentaria a rede]
sed -i 's:"/desktop:"/org:' schema/*.xml &&

mkdir build-gkr &&
cd    build-gkr &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D systemd=disabled \
      -D manpage=false    \
      -D ssh-agent=true   &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

