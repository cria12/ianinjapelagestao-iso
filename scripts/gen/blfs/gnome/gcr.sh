# Gerado de BLFS 12.4 gnome/gcr.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed '/ssh.add/d; /ssh.agent/d' -i meson.build

# --- bloco 2 [substituído: -D introspection=false: o GIR gera também os .vapi, que exigem o Vala (não instalado); o libnma só usa a API C]
sed -i 's:"/desktop:"/org:' schema/*.xml &&
mkdir build &&
cd    build &&
meson setup --prefix=/usr       \
            --buildtype=release \
            -D gtk_doc=false    \
            -D ssh_agent=false  \
            -D introspection=false \
            ..                  &&
ninja

# --- bloco 3 [omitido: documentação da API precisa do GTK-Doc (não instalado)]
#   sed -e "/install_dir/s@,\$@ / 'gcr-3.41.2'&@" \
#       -i ../docs/*/meson.build                  &&
#   meson configure -D gtk_doc=true               &&
#   ninja

# --- bloco 4 (root)
echo '>>> bloco 4'
ninja install

