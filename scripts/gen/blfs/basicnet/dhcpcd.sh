# Gerado de BLFS 12.4 basicnet/dhcpcd.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: utilizador/grupo de privilege separation — o livro usa --disable-privsep (bloco 2)]
#   install  -v -m700 -d /var/lib/dhcpcd &&
#   
#   groupadd -g 52 dhcpcd        &&
#   useradd  -c 'dhcpcd PrivSep' \
#            -d /var/lib/dhcpcd  \
#            -g dhcpcd           \
#            -s /bin/false       \
#            -u 52 dhcpcd &&
#   chown    -v dhcpcd:dhcpcd /var/lib/dhcpcd 

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr                \
            --sysconfdir=/etc            \
            --libexecdir=/usr/lib/dhcpcd \
            --dbdir=/var/lib/dhcpcd      \
            --runstatedir=/run           \
            --disable-privsep         &&
make

# --- bloco 3 [omitido: alternativa com privilege separation (o livro recomenda o bloco 2)]
#   ./configure --prefix=/usr                \
#               --sysconfdir=/etc            \
#               --libexecdir=/usr/lib/dhcpcd \
#               --dbdir=/var/lib/dhcpcd      \
#               --runstatedir=/run           \
#               --privsepuser=dhcpcd         &&
#   make

# --- bloco 4 (root)
echo '>>> bloco 4'
make install

# --- bloco 5 [substituído: make install-service-dhcpcd tem de correr no diretório do blfs-bootscripts]
BS=/sources/blfs-bootscripts-20250225
[ -d $BS ] || tar -C /sources -xf /sources/blfs-bootscripts-20250225.tar.xz
(cd $BS && make install-service-dhcpcd)

# --- bloco 6 [substituído: modelo com <placeholders>: substituído por DHCP_START="-b -q -h $HOSTNAME" / DHCP_STOP="-k"]
cat > /etc/sysconfig/ifconfig.eth0 << "EOF2"
ONBOOT="yes"
IFACE="eth0"
SERVICE="dhcpcd"
DHCP_START="-b -q -h $HOSTNAME"
DHCP_STOP="-k"
EOF2

# --- bloco 7 [omitido: exemplo de configuração estática (a ISO usa DHCP)]
#   cat > /etc/sysconfig/ifconfig.eth0 << "EOF"
#   ONBOOT="yes"
#   IFACE="eth0"
#   SERVICE="dhcpcd"
#   DHCP_START="-b -q -S ip_address=192.168.0.10/24 -S routers=192.168.0.1"
#   DHCP_STOP="-k"
#   EOF

# --- bloco 8 [omitido: resolv.conf.head opcional com servidores OpenDNS (usam-se os DNS do DHCP)]
#   cat > /etc/resolv.conf.head << "EOF"
#   # OpenDNS servers
#   nameserver 208.67.222.222
#   nameserver 208.67.220.220
#   EOF

