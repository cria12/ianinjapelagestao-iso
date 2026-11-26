# Gerado de BLFS 12.4 postlfs/linux-pam.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: só se aplica se docbook/libxslt/lynx estiverem instalados para gerar a documentação (não estão)]
#   sed -e "s/'elinks'/'lynx'/"                       \
#       -e "s/'-no-numbering', '-no-references'/      \
#             '-force-html', '-nonumbers', '-stdin'/" \
#       -i meson.build

# --- bloco 2 (userinput)
echo '>>> bloco 2'
mkdir build &&
cd    build &&

meson setup ..        \
  --prefix=/usr       \
  --buildtype=release \
  -D docdir=/usr/share/doc/Linux-PAM-1.7.1 &&

ninja

# --- bloco 3 [substituído: cria /etc/pam.d/other temporário E corre o "ninja test" indicado no texto (falhas toleradas)]
install -v -m755 -d /etc/pam.d &&
cat > /etc/pam.d/other << "EOF2"
auth     required       pam_deny.so
account  required       pam_deny.so
password required       pam_deny.so
session  required       pam_deny.so
EOF2
# "Now run the tests by issuing ninja test" (texto do livro, fora de bloco) — falhas não param a build
echo '>>> ninja test'
if ! ninja test; then echo '[AVISO-TESTE] Linux-PAM: ninja test terminou com falhas'; fi

# --- bloco 4 (root)
echo '>>> bloco 4'
rm -fv /etc/pam.d/other

# --- bloco 5 (root)
echo '>>> bloco 5'
ninja install &&
chmod -v 4755 /usr/sbin/unix_chkpwd

# --- bloco 6 (root)
echo '>>> bloco 6'
rm -rf /usr/lib/systemd

# --- bloco 7 (root)
echo '>>> bloco 7'
tar -C / -xvf ../../Linux-PAM-1.7.1-docs.tar.xz

# --- bloco 8 (root)
echo '>>> bloco 8'
install -vdm755 /etc/pam.d &&
cat > /etc/pam.d/system-account << "EOF" &&
# Begin /etc/pam.d/system-account

account   required    pam_unix.so

# End /etc/pam.d/system-account
EOF

cat > /etc/pam.d/system-auth << "EOF" &&
# Begin /etc/pam.d/system-auth

auth      required    pam_unix.so

# End /etc/pam.d/system-auth
EOF

cat > /etc/pam.d/system-session << "EOF" &&
# Begin /etc/pam.d/system-session

session   required    pam_unix.so

# End /etc/pam.d/system-session
EOF

cat > /etc/pam.d/system-password << "EOF"
# Begin /etc/pam.d/system-password

# use yescrypt hash for encryption, use shadow, and try to use any
# previously defined authentication token (chosen password) set by any
# prior module.
password  required    pam_unix.so       yescrypt shadow try_first_pass

# End /etc/pam.d/system-password
EOF

# --- bloco 9 (root)
echo '>>> bloco 9'
cat > /etc/pam.d/other << "EOF"
# Begin /etc/pam.d/other

auth        required        pam_warn.so
auth        required        pam_deny.so
account     required        pam_warn.so
account     required        pam_deny.so
password    required        pam_warn.so
password    required        pam_deny.so
session     required        pam_warn.so
session     required        pam_deny.so

# End /etc/pam.d/other
EOF

