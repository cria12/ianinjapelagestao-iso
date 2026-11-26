# Gerado de BLFS 12.4 x/lightdm.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: utilizador/grupo lightdm criados só se não existirem (permite repetir o passo)]
{ getent group lightdm > /dev/null || groupadd -g 65 lightdm; } &&
{ getent passwd lightdm > /dev/null ||
  useradd  -c "Lightdm Daemon" \
           -d /var/lib/lightdm \
           -u 65 -g lightdm    \
           -s /bin/false lightdm; }

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sed -i s/systemd/elogind/ data/pam/*

# --- bloco 3 (userinput)
echo '>>> bloco 3'
./configure --prefix=/usr                 \
            --libexecdir=/usr/lib/lightdm \
            --localstatedir=/var          \
            --sbindir=/usr/bin            \
            --sysconfdir=/etc             \
            --disable-static              \
            --disable-tests               \
            --with-greeter-user=lightdm   \
            --with-greeter-session=lightdm-gtk-greeter \
            --docdir=/usr/share/doc/lightdm-1.32.0 &&
make

# --- bloco 4 (root)
echo '>>> bloco 4'
make install                                                  &&
cp tests/src/lightdm-session /usr/bin                         &&
sed -i '1 s/sh/bash --login/' /usr/bin/lightdm-session        &&
rm -rf /etc/init                                              &&
install -v -dm755 -o lightdm -g lightdm /var/lib/lightdm      &&
install -v -dm755 -o lightdm -g lightdm /var/lib/lightdm-data &&
install -v -dm755 -o lightdm -g lightdm /var/cache/lightdm    &&
install -v -dm770 -o lightdm -g lightdm /var/log/lightdm

# --- bloco 5 (userinput)
echo '>>> bloco 5'
tar -xf ../lightdm-gtk-greeter-2.0.9.tar.gz &&
cd lightdm-gtk-greeter-2.0.9 &&

./configure --prefix=/usr                 \
            --libexecdir=/usr/lib/lightdm \
            --sbindir=/usr/bin            \
            --sysconfdir=/etc             \
            --with-libxklavier            \
            --enable-kill-on-sigterm      \
            --disable-libido              \
            --disable-libindicator        \
            --disable-static              \
            --disable-maintainer-mode     \
            --docdir=/usr/share/doc/lightdm-gtk-greeter-2.0.9 &&
make

# --- bloco 6 (root)
echo '>>> bloco 6'
make install

# --- bloco 7 [substituído: o Xorg está em /usr (XORG_PREFIX=/usr), não em /opt/xorg: só garante /usr/bin/X -> Xorg]
# o LightDM lança o servidor com xserver-command=X (valor por omissão)
[ -x /usr/bin/Xorg ] &&
{ [ -e /usr/bin/X ] || ln -sv Xorg /usr/bin/X; }

# --- bloco 8 [omitido: make install-lightdm corre no passo lightdm-bootscript (função bootscripts, no diretório do blfs-bootscripts)]
#   make install-lightdm

# --- bloco 9 [substituído: telinit 5 não pode correr no chroot -> configuração funcional do seat (greeter e sessão xfce); runlevel 5 no passo lightdm-runlevel5]
# Configuração funcional mínima do seat (o aspeto do greeter fica para scripts/gui/tema).
# O LightDM lê /etc/lightdm/lightdm.conf.d/*.conf antes de /etc/lightdm/lightdm.conf.
install -v -dm755 /etc/lightdm/lightdm.conf.d &&
cat > /etc/lightdm/lightdm.conf.d/10-ianinjapelagestao.conf << "EOF" &&
# ianinjapelagestao (F8d): greeter GTK e sessão Xfce por omissão
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=xfce
EOF
[ -f /usr/share/xsessions/xfce.desktop ] &&
[ -f /usr/share/xgreeters/lightdm-gtk-greeter.desktop ] &&
[ -x /usr/bin/lightdm ] &&
[ -f /etc/pam.d/lightdm ] && [ -f /etc/pam.d/lightdm-greeter ]

