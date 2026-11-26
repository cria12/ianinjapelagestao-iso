# Gerado de BLFS 12.4 basicnet/wpa_supplicant.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
cat > wpa_supplicant/.config << "EOF"
CONFIG_BACKEND=file
CONFIG_CTRL_IFACE=y
CONFIG_DEBUG_FILE=y
CONFIG_DEBUG_SYSLOG=y
CONFIG_DEBUG_SYSLOG_FACILITY=LOG_DAEMON
CONFIG_DRIVER_NL80211=y
CONFIG_DRIVER_WEXT=y
CONFIG_DRIVER_WIRED=y
CONFIG_EAP_GTC=y
CONFIG_EAP_LEAP=y
CONFIG_EAP_MD5=y
CONFIG_EAP_MSCHAPV2=y
CONFIG_EAP_OTP=y
CONFIG_EAP_PEAP=y
CONFIG_EAP_TLS=y
CONFIG_EAP_TTLS=y
CONFIG_IEEE8021X_EAPOL=y
CONFIG_IPV6=y
CONFIG_LIBNL32=y
CONFIG_PEERKEY=y
CONFIG_PKCS12=y
CONFIG_READLINE=y
CONFIG_SMARTCARD=y
CONFIG_WPS=y
CFLAGS += -I/usr/include/libnl3
EOF

# --- bloco 2 [omitido: interface D-Bus: o D-Bus não está instalado (sem NetworkManager/ambiente gráfico)]
#   cat >> wpa_supplicant/.config << "EOF"
#   CONFIG_CTRL_IFACE_DBUS=y
#   CONFIG_CTRL_IFACE_DBUS_NEW=y
#   CONFIG_CTRL_IFACE_DBUS_INTRO=y
#   EOF

# --- bloco 3 (userinput)
echo '>>> bloco 3'
cd wpa_supplicant &&
make BINDIR=/usr/sbin LIBDIR=/usr/lib

# --- bloco 4 (root)
echo '>>> bloco 4'
install -v -m755 wpa_{cli,passphrase,supplicant} /usr/sbin/ &&
install -v -m644 doc/docbook/wpa_supplicant.conf.5 /usr/share/man/man5/ &&
install -v -m644 doc/docbook/wpa_{cli,passphrase,supplicant}.8 /usr/share/man/man8/

# --- bloco 5 [omitido: ficheiros de serviço D-Bus (D-Bus não instalado)]
#   install -v -m644 dbus/fi.w1.wpa_supplicant1.service \
#                    /usr/share/dbus-1/system-services/ &&
#   install -v -d -m755 /etc/dbus-1/system.d &&
#   install -v -m644 dbus/dbus-wpa_supplicant.conf \
#                    /etc/dbus-1/system.d/wpa_supplicant.conf

# --- bloco 6 [omitido: wpa_passphrase SSID é interativo (pede a senha) — feito em tempo de execução pelo ligar-wifi]
#   wpa_passphrase SSID | sed '/^\t#/d' > /etc/sysconfig/wpa_supplicant-wifi0.conf

# --- bloco 7 [substituído: make install-service-wpa tem de correr no diretório do blfs-bootscripts]
BS=/sources/blfs-bootscripts-20250225
[ -d $BS ] || tar -C /sources -xf /sources/blfs-bootscripts-20250225.tar.xz
(cd $BS && make install-service-wpa)

# --- bloco 8 [substituído: modelo com <placeholders>: /etc/sysconfig/ifconfig.wlan0 com ONBOOT="no" e DHCP_START="-b -q -h $HOSTNAME"]
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

# --- bloco 9 [omitido: alternativa com IP estático (a ISO usa DHCP)]
#   cat > /etc/sysconfig/ifconfig.wifi0 << "EOF"
#   ONBOOT="yes"
#   IFACE="wlan0"
#   SERVICE="wpa"
#   
#   # Additional arguments to wpa_supplicant
#   WPA_ARGS=""
#   
#   WPA_SERVICE="ipv4-static"
#   IP="192.168.1.1"
#   GATEWAY="192.168.1.2"
#   PREFIX="24"
#   BROADCAST="192.168.1.255"
#   EOF

# --- bloco 10 [omitido: ifup wifi0 é para o sistema em execução (o chroot não tem placa Wi-Fi)]
#   ifup wifi0

