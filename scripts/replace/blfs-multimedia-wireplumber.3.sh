if [ -d /usr/share/doc/wireplumber ]; then
  rm -rf /usr/share/doc/wireplumber-0.5.10 &&
  mv -v /usr/share/doc/wireplumber{,-0.5.10}
fi
