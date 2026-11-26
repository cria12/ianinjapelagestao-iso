# Gerado de BLFS 12.4 postlfs/make-ca.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (root)
echo '>>> bloco 1'
make install &&
install -vdm755 /etc/ssl/local

# --- bloco 2 (root)
echo '>>> bloco 2'
/usr/sbin/make-ca -g

# --- bloco 3 [omitido: não há cron no sistema (sem /etc/cron.weekly); atualizar certificados à mão com make-ca -g]
#   cat > /etc/cron.weekly/update-pki.sh << "EOF" &&
#   #!/bin/bash
#   /usr/sbin/make-ca -g
#   EOF
#   chmod 754 /etc/cron.weekly/update-pki.sh

# --- bloco 4 [omitido: exemplos de certificados locais (CAcert / Makebelieve) — só ilustrativos]
#   wget http://www.cacert.org/certs/root.crt &&
#   wget http://www.cacert.org/certs/class3.crt &&
#   openssl x509 -in root.crt -text -fingerprint -setalias "CAcert Class 1 root" \
#           -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
#           > /etc/ssl/local/CAcert_Class_1_root.pem &&
#   openssl x509 -in class3.crt -text -fingerprint -setalias "CAcert Class 3 root" \
#           -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
#           > /etc/ssl/local/CAcert_Class_3_root.pem &&
#   /usr/sbin/make-ca -r

# --- bloco 5 [omitido: exemplos de certificados locais (CAcert / Makebelieve) — só ilustrativos]
#   openssl x509 -in /etc/ssl/certs/Makebelieve_CA_Root.pem \
#                -text \
#                -fingerprint \
#                -setalias "Disabled Makebelieve CA Root" \
#                -addreject serverAuth \
#                -addreject emailProtection \
#                -addreject codeSigning \
#          > /etc/ssl/local/Disabled_Makebelieve_CA_Root.pem &&
#   /usr/sbin/make-ca -r

# --- bloco 6 [omitido: export interativo para a sessão atual; o bloco 7 (/etc/profile.d/pythoncerts.sh) torna-o permanente]
#   export _PIP_STANDALONE_CERT=/etc/pki/tls/certs/ca-bundle.crt

# --- bloco 7 (root)
echo '>>> bloco 7'
mkdir -pv /etc/profile.d &&
cat > /etc/profile.d/pythoncerts.sh << "EOF"
# Begin /etc/profile.d/pythoncerts.sh

export _PIP_STANDALONE_CERT=/etc/pki/tls/certs/ca-bundle.crt

# End /etc/profile.d/pythoncerts.sh
EOF

