ninja install &&
mkdir -pv /etc/X11/xorg.conf.d &&
install -v -d -m1777 /tmp/.{ICE,X11}-unix &&
if ! grep -q '^/tmp/.X11-unix' /etc/sysconfig/createfiles; then
cat >> /etc/sysconfig/createfiles << "EOF2"
/tmp/.ICE-unix dir 1777 root root
/tmp/.X11-unix dir 1777 root root
EOF2
fi
