# Gerado de BLFS 12.4 general/bluez.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr         \
            --sysconfdir=/etc     \
            --localstatedir=/var  \
            --enable-library      \
            --disable-manpages    \
            --disable-systemd     &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install &&
ln -svf ../libexec/bluetooth/bluetoothd /usr/sbin

# --- bloco 3 (root)
echo '>>> bloco 3'
install -v -dm755 /etc/bluetooth &&
install -v -m644 src/main.conf /etc/bluetooth/main.conf

# --- bloco 4 [omitido: documentação .txt omitida para poupar espaço na ISO]
#   install -v -dm755 /usr/share/doc/bluez-5.83 &&
#   install -v -m644 doc/*.txt /usr/share/doc/bluez-5.83

# --- bloco 5 (root)
echo '>>> bloco 5'
install -m644 ./obexd/src/org.bluez.obex.service /usr/share/dbus-1/services

# --- bloco 6 (root)
echo '>>> bloco 6'
cat > /etc/bluetooth/rfcomm.conf << "EOF"
# Start rfcomm.conf
# Set up the RFCOMM configuration of the Bluetooth subsystem in the Linux kernel.
# Use one line per command
# See the rfcomm man page for options


# End of rfcomm.conf
EOF

# --- bloco 7 (root)
echo '>>> bloco 7'
cat > /etc/bluetooth/uart.conf << "EOF"
# Start uart.conf
# Attach serial devices via UART HCI to BlueZ stack
# Use one line per device
# See the hciattach man page for options

# End of uart.conf
EOF

# --- bloco 8 [omitido: make install-bluetooth corre no passo bluez-bootscript (função bootscripts)]
#   make install-bluetooth

