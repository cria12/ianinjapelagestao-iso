# Gerado de BLFS 12.4 general/elogind.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: -D man=auto -> -D man=false: há xsltproc mas não DocBook (xsltproc --nonet falharia)]
mkdir build &&
cd    build &&

meson setup ..                               \
      --prefix=/usr                          \
      --buildtype=release                    \
      -D man=false                           \
      -D docdir=/usr/share/doc/elogind-255.17 \
      -D cgroup-controller=elogind           \
      -D dev-kvm-mode=0660                   \
      -D dbuspolicydir=/etc/dbus-1/system.d &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install                                           &&
ln -sfv  libelogind.pc /usr/lib/pkgconfig/libsystemd.pc &&
ln -sfvn elogind /usr/include/systemd

# --- bloco 3 (root)
echo '>>> bloco 3'
sed -e '/\[Login\]/a KillUserProcesses=no' \
    -i /etc/elogind/logind.conf

# --- bloco 4 [substituído: acrescento ao /etc/pam.d/system-session só se ainda não existir (o passo pode ser repetido)]
if ! grep -q 'Begin elogind addition' /etc/pam.d/system-session; then
cat >> /etc/pam.d/system-session << "EOF2"
# Begin elogind addition

session  required    pam_loginuid.so
session  optional    pam_elogind.so

# End elogind addition
EOF2
fi &&
cat > /etc/pam.d/elogind-user << "EOF2"
# Begin /etc/pam.d/elogind-user

account  required    pam_access.so
account  include     system-account

session  required    pam_env.so
session  required    pam_limits.so
session  required    pam_unix.so
session  required    pam_loginuid.so
session  optional    pam_keyinit.so force revoke
session  optional    pam_elogind.so

auth     required    pam_deny.so
password required    pam_deny.so

# End /etc/pam.d/elogind-user
EOF2

