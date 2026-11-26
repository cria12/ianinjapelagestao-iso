# Gerado de BLFS 12.4 general/dbus.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup --prefix=/usr          \
            --buildtype=release    \
            --wrap-mode=nofallback \
            -D systemd=disabled    \
            .. &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

# --- bloco 3 (root)
echo '>>> bloco 3'
chown -v root:messagebus /usr/libexec/dbus-daemon-launch-helper &&
chmod -v      4750       /usr/libexec/dbus-daemon-launch-helper

# --- bloco 4 (root)
echo '>>> bloco 4'
dbus-uuidgen --ensure

# --- bloco 5 (root)
echo '>>> bloco 5'
ln -sfv /var/lib/dbus/machine-id /etc

# --- bloco 6 (root)
echo '>>> bloco 6'
if [ -e /usr/share/doc/dbus ]; then
  rm -rf /usr/share/doc/dbus-1.16.2    &&
  mv -v  /usr/share/doc/dbus{,-1.16.2}
fi

# --- bloco 7 [omitido: testes precisam de D-Bus Python/PyGObject e reconfiguram com asserts/intrusive_tests (não usar em produção)]
#   meson configure -D asserts=true -D intrusive_tests=true &&
#   ninja test

# --- bloco 8 (root)
echo '>>> bloco 8'
cat > /etc/dbus-1/session-local.conf << "EOF"
<!DOCTYPE busconfig PUBLIC
 "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>

  <!-- Search for .service files in /usr/local -->
  <servicedir>/usr/local/share/dbus-1/services</servicedir>

</busconfig>
EOF

# --- bloco 9 [omitido: make install-dbus: feito no passo dbus-bootscript (função bootscripts, no diretório do blfs-bootscripts)]
#   make install-dbus

# --- bloco 10 [omitido: arrancar o daemon de sistema / de sessão: não há D-Bus a correr no chroot (arranca no boot pelo bootscript)]
#   /etc/init.d/dbus start

# --- bloco 11 [omitido: arrancar o daemon de sistema / de sessão: não há D-Bus a correr no chroot (arranca no boot pelo bootscript)]
#   # Start the D-Bus session daemon
#   eval `dbus-launch`
#   export DBUS_SESSION_BUS_ADDRESS

# --- bloco 12 [omitido: arrancar o daemon de sistema / de sessão: não há D-Bus a correr no chroot (arranca no boot pelo bootscript)]
#   # Kill the D-Bus session daemon
#   kill $DBUS_SESSION_BUS_PID

