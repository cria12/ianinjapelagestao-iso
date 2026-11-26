#!/bin/bash
# F6 — Configuração do sistema + identidade (LFS Cap. 9 e 11.1)
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F6)" = ok ] && exit 0
montar_lfs
montar_kernfs > /dev/null
etapa_inicio F6

# 9.2 LFS-Bootscripts
bootscripts() {
  in_chroot 'set -e; cd /sources; rm -rf lfs-bootscripts-20250827; tar -xf lfs-bootscripts-20250827.tar.xz
cd lfs-bootscripts-20250827; make install; cd /sources; rm -rf lfs-bootscripts-20250827'
}
corre_passo f6-bootscripts $P/logs/09-bootscripts.log bootscripts

cat > $LFS/root/f06-config.sh << "SCRIPT"
set -e
# 9.4 Gestão de dispositivos: com net.ifnames=0 o kernel nomeia a 1.ª placa eth0;
# não se geram regras persistentes (ligariam o nome ao MAC da máquina de build).
sed -e '/^AlternativeNamesPolicy/s/=.*$/=/'  \
       /usr/lib/udev/network/99-default.link \
     > /etc/udev/network/99-default.link

# 9.5 Rede (SERVICE=dhcpcd, instalado na F8)
cd /etc/sysconfig/
cat > ifconfig.eth0 << "EOF"
ONBOOT="yes"
IFACE="eth0"
SERVICE="dhcpcd"
DHCP_START="-b -q"
DHCP_STOP="-k"
EOF
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf
# Gerido pelo dhcpcd no arranque

# End /etc/resolv.conf
EOF
echo "ianinjapelagestao" > /etc/hostname
cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost
127.0.1.1 ianinjapelagestao.localdomain ianinjapelagestao
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF

# 9.6 inittab (do livro) + consola série ttyS0 para testes/servidores
cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600
S0:2345:respawn:/sbin/agetty --noclear -L 115200 ttyS0 vt100

# End /etc/inittab
EOF
grep -qx ttyS0 /etc/securetty 2>/dev/null || true

cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF

cat > /etc/sysconfig/console << "EOF"
# Begin /etc/sysconfig/console

UNICODE="1"
KEYMAP="pt-latin1"
FONT="Lat2-Terminus16"

# End /etc/sysconfig/console
EOF

# rc.site — identidade nas mensagens de arranque
sed -i -e 's|^#DISTRO=.*|DISTRO="ianinjapelagestao" # The distro name|' \
       -e 's|^#DISTRO_MINI=.*|DISTRO_MINI="ianinja" # Short name|' \
       -e 's|^#DISTRO_CONTACT=.*|DISTRO_CONTACT="hiramocs@gmail.com"|' \
       -e 's|^#HOSTNAME=.*|HOSTNAME=ianinjapelagestao|' /etc/sysconfig/rc.site

# 9.7 Locale
cat > /etc/profile << "EOF"
# Begin /etc/profile

for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  export LANG=pt_PT.UTF-8
fi

# End /etc/profile
EOF

# 9.8 inputrc
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF

# 9.9 shells
cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

# 11.1 + identidade da distro
echo 12.4 > /etc/lfs-release
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="ianinjapelagestao"
DISTRIB_RELEASE="12.4"
DISTRIB_CODENAME="ianinja"
DISTRIB_DESCRIPTION="ianinjapelagestao 12.4 (LFS-based)"
EOF
cat > /etc/os-release << "EOF"
NAME="ianinjapelagestao"
VERSION="12.4"
ID=ianinjapelagestao
ID_LIKE=lfs
PRETTY_NAME="ianinjapelagestao 12.4 (LFS-based)"
VERSION_ID="12.4"
VERSION_CODENAME="ianinja"
HOME_URL="https://www.linuxfromscratch.org/lfs/"
RELEASE_TYPE="stable"
EOF
cat > /etc/motd << "EOF"

  Bem-vindo ao ianinjapelagestao 12.4 — Linux From Scratch (System V), sistema live.
  As alterações vivem em RAM (OverlayFS) e perdem-se ao desligar.
  Rede: dhcpcd em eth0 · Editor: nano · Ajuda: cat /usr/share/doc/ianinjapelagestao/README

EOF
SCRIPT
corre_passo f6-config $P/logs/09-config.log in_chroot "bash /root/f06-config.sh"
rm -f $LFS/root/f06-config.sh

# /etc/issue: banner "IANINJA PELAGESTAO" + \n \l (únicas sequências de escape do agetty)
{ echo; python3 $P/scripts/banner.py IANINJA PELAGESTAO
  echo '  ianinjapelagestao 12.4 (LFS-based) - \n \l'; echo; } > $LFS/etc/issue

decisao "Nomes de rede e consola série" \
"Não são geradas regras udev persistentes (Cap. 9.4.1.1): numa ISO live elas ficariam presas ao MAC da máquina de build. Com net.ifnames=0 no GRUB e AlternativeNamesPolicy vazio, a 1.ª placa chama-se sempre eth0. Ao /etc/inittab do livro foi acrescentado um agetty em ttyS0 (115200) para permitir testes headless no QEMU e uso em servidores. Consola: KEYMAP=pt-latin1, FONT=Lat2-Terminus16, UNICODE=1; LANG=pt_PT.UTF-8; fuso Europe/Lisbon (aplicado no Cap. 8 Glibc)."
etapa_fim F6 ok "bootscripts, rede dhcpcd/eth0, inittab+ttyS0, pt-latin1, pt_PT.UTF-8, identidade da distro"
