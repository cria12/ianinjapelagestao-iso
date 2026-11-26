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
