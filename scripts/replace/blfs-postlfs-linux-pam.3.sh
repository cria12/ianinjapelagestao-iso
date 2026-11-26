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
