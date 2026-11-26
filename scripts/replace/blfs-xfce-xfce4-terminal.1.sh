# A página de manual exige a folha de estilos DocBook XSL (não instalada); o xsltproc
# com --nonet falharia. O xfce4-terminal não tem opção para a desligar: retira-se doc/.
sed -i "/^subdir(.doc.)/d" meson.build &&

mkdir build &&
cd    build &&

meson setup ..      \
      --prefix=/usr \
      --buildtype=release &&
ninja
