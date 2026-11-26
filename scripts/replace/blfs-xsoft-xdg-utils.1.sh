./configure --prefix=/usr &&
cd scripts &&
for x in xdg-desktop-menu xdg-desktop-icon xdg-mime xdg-icon-resource \
         xdg-open xdg-email xdg-screensaver xdg-settings; do
  sed -e "s/<[^>]*>//g" -e "s/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g" desc/$x.xml | cat -s > $x.txt || exit 1
done &&
make scripts &&
sh ./xdg-open --version &&
cd ..
