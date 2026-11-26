# Gerado de BLFS 12.4 xfce/xfce4-terminal.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: retira doc/ do meson.build: a página de manual precisa do docbook-xsl (xsltproc --nonet falharia)]
# A página de manual exige a folha de estilos DocBook XSL (não instalada); o xsltproc
# com --nonet falharia. O xfce4-terminal não tem opção para a desligar: retira-se doc/.
sed -i "/^subdir(.doc.)/d" meson.build &&

mkdir build &&
cd    build &&

meson setup ..      \
      --prefix=/usr \
      --buildtype=release &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

