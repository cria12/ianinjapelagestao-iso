# ianinjapelagestao: modelo para a placa Wi-Fi (net.ifnames=0 -> wlan0), DESLIGADO no arranque.
# A rede e a senha vão para /etc/sysconfig/wpa_supplicant-wlan0.conf (ver: ligar-wifi <SSID>).
cat > /etc/sysconfig/ifconfig.wlan0 << "EOF2"
# Wi-Fi (BLFS: wpa_supplicant + dhcpcd). Ligar à mão: sudo ligar-wifi <SSID>
# Para ligar sozinho no arranque (só faz sentido com persistência): ONBOOT="yes"
ONBOOT="no"
IFACE="wlan0"
SERVICE="wpa"

# Additional arguments to wpa_supplicant
WPA_ARGS=""

WPA_SERVICE="dhcpcd"
DHCP_START="-b -q -h $HOSTNAME"
DHCP_STOP="-k"
EOF2
