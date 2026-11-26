# Gerado de BLFS 12.4 postlfs/fuse.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i '/^udev/,$ s/^/#/' util/meson.build &&

mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- bloco 2 [omitido: documentação da API com Doxygen (não instalado)]
#   pushd .. &&
#     doxygen doc/Doxyfile &&
#   popd

# --- bloco 3 [omitido: testes: venv + pip install looseversion (o chroot não tem rede) e pytest]
#   python3 -m venv --system-site-packages testenv &&
#   source testenv/bin/activate                    &&
#   pip3 install looseversion                      &&
#   python3 -m pytest
#   deactivate

# --- bloco 4 (root)
echo '>>> bloco 4'
ninja install                  &&
chmod u+s /usr/bin/fusermount3 &&

cd ..                          &&
cp -Rv doc/html -T /usr/share/doc/fuse-3.17.4 &&
install -v -m644   doc/{README.NFS,kernel.txt} \
                   /usr/share/doc/fuse-3.17.4

# --- bloco 5 (root)
echo '>>> bloco 5'
cat > /etc/fuse.conf << "EOF"
# Set the maximum number of FUSE mounts allowed to non-root users.
# The default is 1000.
#
#mount_max = 1000

# Allow non-root users to specify the 'allow_other' or 'allow_root'
# mount options.
#
#user_allow_other
EOF

