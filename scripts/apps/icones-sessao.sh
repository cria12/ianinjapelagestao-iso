#!/bin/bash
# scripts/apps/icones-sessao.sh — corre DENTRO do chroot (passo icones-sessao da F8e, funcoes-07.sh).
# Ícones dos diálogos de sessão do Xfce (xfce4-session "Terminar sessão", plugin Ações do painel)
# no tema WhiteSur, sem depender do librsvg na altura de os mostrar:
#  1. Para cada nome pedido pelo xfce4-session 4.20.3 (xfsm-logout, -reboot, -shutdown, -suspend,
#     -hibernate, -switch-user, -lock e os nomes de recurso system-*), grava em
#     WhiteSur/apps/scalable um <nome>.png de 256x256 desenhado agora pelo rsvg-convert a partir do
#     SVG equivalente do próprio WhiteSur (log-out, reboot, shutdown, suspend, hibernate, users,
#     system-lock-screen). O GTK 3 prefere .png a .svg na mesma pasta, por isso no diálogo (48 px,
#     96 px com escala 2) passa a carregar um PNG com o leitor interno do gdk-pixbuf. Nos tamanhos
#     pequenos (painel, menus: 16-32 px) continuam a ganhar as pastas fixas actions/NN e status/NN.
#     WhiteSur-light e WhiteSur-dark usam as mesmas pastas (ligações para ../WhiteSur/apps).
#  2. Inherits=hicolor,breeze -> Inherits=Adwaita,hicolor nos três index.theme: o breeze não existe
#     no sistema; o Adwaita (BLFS) está instalado e passa a servir de recurso para nomes que faltem.
#  3. Refaz as caches (gtk-update-icon-cache); a verificação (ianinja-verificar-icones) é feita
#     pela função icones_sessao depois deste script.
# Idempotente: pode correr outra vez (regrava os PNG e as caches).
set -e
W=/usr/share/icons/WhiteSur
A=$W/apps/scalable
test -d $A
command -v rsvg-convert > /dev/null

# nome pedido -> SVG de origem (em $A) — o equivalente "macOS" do próprio WhiteSur
while read -r nome origem; do
  [ -n "$nome" ] || continue
  f=$(readlink -f $A/$origem.svg)
  test -s "$f" || { echo "falta a origem $A/$origem.svg"; exit 1; }
  rsvg-convert -w 256 -h 256 -f png -o $A/$nome.png.tmp "$f"
  mv -f $A/$nome.png.tmp $A/$nome.png
  chmod 644 $A/$nome.png
  echo "$A/$nome.png <- $f"
done << 'EOF'
xfsm-logout             log-out
xfsm-reboot             reboot
xfsm-shutdown           shutdown
xfsm-suspend            suspend
xfsm-hibernate          hibernate
xfsm-switch-user        system-switch-user
xfsm-lock               system-lock-screen
system-log-out          log-out
system-reboot           reboot
system-shutdown         shutdown
system-suspend          suspend
system-hibernate        hibernate
system-suspend-hibernate hibernate
system-switch-user      system-switch-user
system-lock-screen      system-lock-screen
EOF

for t in WhiteSur WhiteSur-light WhiteSur-dark; do
  i=/usr/share/icons/$t/index.theme
  test -f $i
  sed -i 's/^Inherits=.*/Inherits=Adwaita,hicolor/' $i
  grep -q '^Inherits=Adwaita,hicolor$' $i
  find /usr/share/icons/$t -xtype l -delete
  gtk-update-icon-cache -f -t /usr/share/icons/$t
done
