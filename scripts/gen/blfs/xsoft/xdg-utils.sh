# Gerado de BLFS 12.4 xsoft/xdg-utils.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: sem xmlto/DocBook: textos de ajuda gerados do XML com sed e só "make scripts" (sem man/html)]
./configure --prefix=/usr &&
cd scripts &&
for x in xdg-desktop-menu xdg-desktop-icon xdg-mime xdg-icon-resource \
         xdg-open xdg-email xdg-screensaver xdg-settings; do
  sed -e "s/<[^>]*>//g" -e "s/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g" desc/$x.xml | cat -s > $x.txt || exit 1
done &&
make scripts &&
sh ./xdg-open --version &&
cd ..

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

