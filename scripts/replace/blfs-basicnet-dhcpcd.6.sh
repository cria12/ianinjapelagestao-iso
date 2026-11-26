cat > /etc/sysconfig/ifconfig.eth0 << "EOF2"
ONBOOT="yes"
IFACE="eth0"
SERVICE="dhcpcd"
DHCP_START="-b -q -h $HOSTNAME"
DHCP_STOP="-k"
EOF2
