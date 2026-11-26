BS=/sources/blfs-bootscripts-20250225
[ -d $BS ] || tar -C /sources -xf /sources/blfs-bootscripts-20250225.tar.xz
(cd $BS && make install-alsa)
# ianinjapelagestao: num sistema live o 1.º arranque nunca tem /var/lib/alsa/asound.state; sem estado
# (ou sem placa de som) o "alsactl restore" falha e o arranque mostraria FAIL. Sem estado gravado
# usa-se "alsactl init" (volumes por omissão) e a falta de placa de som não é um erro.
sed -i 's|^      /usr/sbin/alsactl --no-ucm restore$|      if [ ! -e /var/lib/alsa/asound.state ]; then\n         /usr/sbin/alsactl --no-ucm init > /dev/null 2>\&1; true\n      else\n         /usr/sbin/alsactl --no-ucm restore\n      fi|' /etc/rc.d/init.d/alsa
sed -i 's|^      /usr/sbin/alsactl --no-ucm store$|      mkdir -p /var/lib/alsa\n      if grep -q . /proc/asound/cards 2> /dev/null \&\& ! grep -q "no soundcards" /proc/asound/cards; then /usr/sbin/alsactl --no-ucm store; else true; fi|' /etc/rc.d/init.d/alsa
grep -q 'alsactl --no-ucm init' /etc/rc.d/init.d/alsa
bash -n /etc/rc.d/init.d/alsa
