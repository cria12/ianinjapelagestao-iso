# Gerado de BLFS 12.4 postlfs/openssh.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: utilizador/grupo sshd criados só se não existirem (permite repetir o passo)]
install -v -g sys -m700 -d /var/lib/sshd &&

{ getent group sshd > /dev/null || groupadd -g 50 sshd; } &&
{ getent passwd sshd > /dev/null ||
  useradd  -c 'sshd PrivSep' \
           -d /var/lib/sshd  \
           -g sshd           \
           -s /bin/false     \
           -u 50 sshd; }

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr                            \
            --sysconfdir=/etc/ssh                    \
            --with-privsep-path=/var/lib/sshd        \
            --with-default-path=/usr/bin             \
            --with-superuser-path=/usr/sbin:/usr/bin \
            --with-pid-dir=/run                      &&
make

# --- bloco 3 (root)
echo '>>> bloco 3'
make install &&
install -v -m755    contrib/ssh-copy-id /usr/bin     &&

install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1              &&
install -v -m755 -d /usr/share/doc/openssh-10.0p1     &&
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-10.0p1

# --- bloco 4 (root)
echo '>>> bloco 4'
echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# --- bloco 5 [omitido: ssh-keygen/ssh-copy-id interativos para um host remoto (REMOTE_USERNAME@REMOTE_HOSTNAME)]
#   ssh-keygen &&
#   ssh-copy-id -i ~/.ssh/id_ed25519.pub REMOTE_USERNAME@REMOTE_HOSTNAME

# --- bloco 6 [omitido: desativar login por senha deixaria a ISO inacessível por ssh (não há chaves autorizadas)]
#   echo "PasswordAuthentication no" >> /etc/ssh/sshd_config &&
#   echo "KbdInteractiveAuthentication no" >> /etc/ssh/sshd_config

# --- bloco 7 (root)
echo '>>> bloco 7'
sed 's@d/login@d/sshd@g' /etc/pam.d/login > /etc/pam.d/sshd &&
chmod 644 /etc/pam.d/sshd &&
echo "UsePAM yes" >> /etc/ssh/sshd_config

# --- bloco 8 [substituído: make install-sshd tem de correr no diretório do blfs-bootscripts]
BS=/sources/blfs-bootscripts-20250225
[ -d $BS ] || tar -C /sources -xf /sources/blfs-bootscripts-20250225.tar.xz
(cd $BS && make install-sshd)

