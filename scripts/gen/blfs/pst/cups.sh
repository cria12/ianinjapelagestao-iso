# Gerado de BLFS 12.4 pst/cups.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: utilizador lp criado só se não existir (permite repetir o passo)]
getent passwd lp > /dev/null ||
  useradd -c "Print Service User" -d /var/spool/cups -g lp -s /bin/false -u 9 lp

# --- bloco 2 [substituído: grupo lpadmin criado só se não existir]
getent group lpadmin > /dev/null || groupadd -g 19 lpadmin

# --- bloco 3 [substituído: <username> -> ninja (utilizador do sistema, administra impressoras)]
usermod -a -G lpadmin ninja

# --- bloco 4 [substituído: o Firefox não existe: o atalho "Gerir impressão" abre http://localhost:631 com xdg-open]
sed -i "s#@CUPS_HTMLVIEW@#xdg-open#" desktop/cups.desktop.in

# --- bloco 5 (userinput)
echo '>>> bloco 5'
./configure --libdir=/usr/lib            \
            --with-rcdir=/tmp/cupsinit   \
            --with-rundir=/run/cups      \
            --with-system-groups=lpadmin \
            --with-docdir=/usr/share/cups/doc-2.4.12 &&
make

# --- bloco 6 (root)
echo '>>> bloco 6'
make install &&
ln -svnf ../cups/doc-2.4.12 /usr/share/doc/cups-2.4.12

# --- bloco 7 (root)
echo '>>> bloco 7'
rm -rf /tmp/cupsinit

# --- bloco 8 (root)
echo '>>> bloco 8'
echo "ServerName /run/cups/cups.sock" > /etc/cups/client.conf

# --- bloco 9 (userinput)
echo '>>> bloco 9'
gtk-update-icon-cache -qtf /usr/share/icons/hicolor

# --- bloco 10 (root)
echo '>>> bloco 10'
cat > /etc/pam.d/cups << "EOF"
# Begin /etc/pam.d/cups

auth    include system-auth
account include system-account
session include system-session

# End /etc/pam.d/cups
EOF

# --- bloco 11 [omitido: make install-cups corre no passo cups-bootscript (função bootscripts); depois cups_sem_arranque tira os S35cups]
#   make install-cups

