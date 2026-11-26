# Gerado de BLFS 12.4 multimedia/alsa-utils.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --disable-alsaconf \
            --disable-bat      \
            --disable-xmlto    \
            --with-curses=ncursesw &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

# --- bloco 3 [omitido: alsactl init/store precisam de uma placa de som (não há no chroot); feitos no arranque pelo bootscript alsa]
#   alsactl init

# --- bloco 4 [omitido: alsactl init/store precisam de uma placa de som (não há no chroot); feitos no arranque pelo bootscript alsa]
#   alsactl -L store

# --- bloco 5 [omitido: exemplo de /etc/asound.conf para a placa 1 (depende do hardware)]
#   cat > /etc/asound.conf << "EOF"
#   # Begin /etc/asound.conf
#   
#   defaults.pcm.card 1
#   defaults.ctl.card 1
#   
#   # End /etc/asound.conf
#   EOF

# --- bloco 6 [substituído: make install-alsa no diretório do blfs-bootscripts; restauro sem estado gravado não dá FAIL]
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

