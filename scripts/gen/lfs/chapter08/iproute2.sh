# Gerado de LFS 12.4 chapter08/iproute2.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make NETNS_RUN_DIR=/run/netns

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make SBINDIR=/usr/sbin install

# --- bloco 4 (userinput)
echo '>>> bloco 4'
install -vDm644 COPYING README* -t /usr/share/doc/iproute2-6.16.0

