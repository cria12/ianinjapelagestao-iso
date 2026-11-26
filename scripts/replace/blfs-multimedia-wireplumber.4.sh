rm -vf /etc/xdg/autostart/pulseaudio.desktop         &&
rm -vf /etc/xdg/Xwayland-session.d/00-pulseaudio-x11 &&
if [ -f /etc/pulse/client.conf ]; then
  grep -q '^autospawn = no' /etc/pulse/client.conf || sed -e '$a autospawn = no' -i /etc/pulse/client.conf
fi
