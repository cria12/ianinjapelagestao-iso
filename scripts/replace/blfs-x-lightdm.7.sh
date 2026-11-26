# o LightDM lança o servidor com xserver-command=X (valor por omissão)
[ -x /usr/bin/Xorg ] &&
{ [ -e /usr/bin/X ] || ln -sv Xorg /usr/bin/X; }
