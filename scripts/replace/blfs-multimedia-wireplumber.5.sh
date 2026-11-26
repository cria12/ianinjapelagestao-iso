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
