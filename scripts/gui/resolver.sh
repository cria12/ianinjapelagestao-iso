#!/bin/bash
# Gera scripts/gui/ordem.txt: páginas BLFS da interface gráfica por ordem de instalação.
# Dependências recomendadas que não fazem falta a um ambiente de trabalho são cortadas (SEM).
cd /root/ianinjapelagestao/scripts
ALVOS=(
  x/xorg-server x/xinit x/x7driver@xorg-libinput-driver
  xfce/xfce4-session xfce/xfce4-panel xfce/xfwm4 xfce/xfdesktop xfce/xfce4-settings
  xfce/thunar xfce/xfce4-terminal xfce/xfce4-appfinder xfce/tumbler xfce/xfce4-notifyd
  x/lightdm x/TTF-and-OTF-fonts
)
SEM=(
  pst/texlive x/installing pst/tex-path general/libpaper
  x/gtk4 general/gegl general/graphviz general/babl general/vala
  multimedia/gstreamer10 multimedia/gst10-plugins-base multimedia/gst10-plugins-good multimedia/gst10-plugins-bad
  multimedia/pulseaudio xsoft/xscreensaver x/glu
  pst/docbook pst/docbook-xsl general/libarchive
  x/vulkan-loader x/vulkan-headers gnome/gsettings-desktop-schemas
)
args=()
for s in "${SEM[@]}"; do args+=(--sem "$s"); done
python3 blfs-deps.py ../book/blfs --feitas gui/feitas.txt "${args[@]}" "${ALVOS[@]}" "$@"
