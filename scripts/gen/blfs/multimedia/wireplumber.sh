# Gerado de BLFS 12.4 multimedia/wireplumber.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release -D system-lua=true .. &&
ninja

# --- bloco 2 (root)
echo '>>> bloco 2'
ninja install

# --- bloco 3 [substituído: a documentação só existe com Sphinx (não instalado): mv só se o diretório existir]
if [ -d /usr/share/doc/wireplumber ]; then
  rm -rf /usr/share/doc/wireplumber-0.5.10 &&
  mv -v /usr/share/doc/wireplumber{,-0.5.10}
fi

# --- bloco 4 [substituído: sem PulseAudio instalado não há /etc/pulse/client.conf (o sed falharia); ficam só os rm]
rm -vf /etc/xdg/autostart/pulseaudio.desktop         &&
rm -vf /etc/xdg/Xwayland-session.d/00-pulseaudio-x11 &&
if [ -f /etc/pulse/client.conf ]; then
  grep -q '^autospawn = no' /etc/pulse/client.conf || sed -e '$a autospawn = no' -i /etc/pulse/client.conf
fi

# --- bloco 5 [substituído: lançador: o ciclo de espera do livro ([ $(pgrep) = "" ]) nunca espera; espera-se pelo socket pipewire-0]
cat > /usr/bin/pipewire-launcher.sh << "EOF"
#!/bin/sh
# Begin /usr/bin/pipewire-launcher.sh
# Do BLFS (página do WirePlumber), com a espera corrigida: o livro testa [ $(pgrep ...) = "" ],
# que dá erro (e por isso não espera) quando há 0 ou mais de 1 processo; aqui espera-se pelo
# socket do PipeWire antes de arrancar o WirePlumber e o pipewire-pulse.

: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
export XDG_RUNTIME_DIR
U=$(id -un)

# instâncias anteriores (logout/login rápido ou PipeWire pendurado)
pkill -u "$U" -x pipewire-pulse
pkill -u "$U" -x wireplumber
pkill -u "$U" -x pipewire
sleep 0.5

/usr/bin/pipewire &

i=0
while [ ! -S "$XDG_RUNTIME_DIR/pipewire-0" ] && [ $i -lt 50 ]; do
  sleep 0.2
  i=$((i + 1))
done

/usr/bin/wireplumber &
/usr/bin/pipewire-pulse &

# End /usr/bin/pipewire-launcher.sh
EOF

# --- bloco 6 (root)
echo '>>> bloco 6'
chmod +x /usr/bin/pipewire-launcher.sh

# --- bloco 7 (root)
echo '>>> bloco 7'
cat > /etc/xdg/autostart/pipewire.desktop << "EOF"
[Desktop Entry]
Version=1.0
Name=Pipewire
Comment=Starts the Pipewire and Wireplumber daemons
Exec=/usr/bin/pipewire-launcher.sh
Terminal=false
Type=Application
EOF

