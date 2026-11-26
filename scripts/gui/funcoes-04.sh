# scripts/gui/funcoes-04.sh — tema e aspeto ao estilo do macOS da F8d (corre depois de todas as
# páginas de scripts/gui/ordem.txt): temas WhiteSur (GTK, ícones, cursores), dock
# xfce4-docklike-plugin, fontes Inter e JetBrains Mono, papel de parede e logótipo próprios, e a
# configuração por omissão do Xfce/LightDM para todos os utilizadores (árvore scripts/gui/tema/raiz).
# Carregado por scripts/f08d-gui.sh. As funções correm sob corre_passo (sem errexit): cada comando
# termina em "|| return 1". Downloads no host para $LFS/sources, verificados por SHA-256 (fixados
# aqui e em scripts/gui/tema/fontes.txt); compilação e caches no chroot.

TEMA=$P/scripts/gui/tema

# --- versões fixadas (SHA-256 calculadas com sha256sum após download em 2026-11-05)
# WhiteSur GTK theme: tag 2026-09-10 (commit 99247ecd219bdc1c7409baff062b4aafcf1102a7); MIT.
# O repositório traz os temas já gerados em release/*.tar.xz (o install.sh precisaria do sassc).
WSGTK_TAG=2026-09-10
WSGTK_TB=whitesur-gtk-theme-$WSGTK_TAG.tar.gz
WSGTK_URL=https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/$WSGTK_TAG.tar.gz
WSGTK_SHA256=65516c8f45da45c602471e31b4de0b6e9aed6eb3fc3820df16161d077245a1a2
WSGTK_DIR=WhiteSur-gtk-theme-$WSGTK_TAG
# WhiteSur icon theme: tag 2026-09-10 (commit 73d8040da51a9ed74e47c7366e7e9ff437601a5c); GPL-3.0.
WSICO_TAG=2026-09-10
WSICO_TB=whitesur-icon-theme-$WSICO_TAG.tar.gz
WSICO_URL=https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/tags/$WSICO_TAG.tar.gz
WSICO_SHA256=406c9cd59705583f1754b0eaca96cc48bafda042b88ef143f16d8ae1820ecd95
WSICO_DIR=WhiteSur-icon-theme-$WSICO_TAG
# WhiteSur cursors: sem tags/releases; commit fixado e190baf (2025-04-05); GPL-3.0.
WSCUR_COMMIT=e190baf618ed95ee217d2fd45589bd309b37672b
WSCUR_TB=whitesur-cursors-${WSCUR_COMMIT:0:7}.tar.gz
WSCUR_URL=https://github.com/vinceliuice/WhiteSur-cursors/archive/$WSCUR_COMMIT.tar.gz
WSCUR_SHA256=35c817c2c26bc4d2c06801cfe6c924a068ad771d3846c5203b04d1c893dd5664
WSCUR_DIR=WhiteSur-cursors-$WSCUR_COMMIT
# xfce4-docklike-plugin 0.5.1 (2026-03-02, meson; exige libxfce4windowing >= 4.19.4); GPL-3.0+.
DOCKLIKE_VER=0.5.1
DOCKLIKE_TB=xfce4-docklike-plugin-$DOCKLIKE_VER.tar.xz
DOCKLIKE_URL=https://archive.xfce.org/src/panel-plugins/xfce4-docklike-plugin/0.5/$DOCKLIKE_TB
DOCKLIKE_SHA256=9d7b355c2be37fb0a73b77b4ed75f092d23c012a67b102c9f847c55ddc3095df
DOCKLIKE_DIR=xfce4-docklike-plugin-$DOCKLIKE_VER
# Inter 4.1 (rsms/inter, release v4.1); SIL OFL 1.1.
INTER_VER=4.1
INTER_TB=Inter-$INTER_VER.zip
INTER_URL=https://github.com/rsms/inter/releases/download/v$INTER_VER/$INTER_TB
INTER_SHA256=9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e
# JetBrains Mono 2.304 (release v2.304); SIL OFL 1.1.
JBMONO_VER=2.304
JBMONO_TB=JetBrainsMono-$JBMONO_VER.zip
JBMONO_URL=https://github.com/JetBrains/JetBrainsMono/releases/download/v$JBMONO_VER/$JBMONO_TB
JBMONO_SHA256=6f6376c6ed2960ea8a963cd7387ec9d76e3f629125bc33d1fdcd7eb7012f7bbf

# baixar <url> <ficheiro em $LFS/sources> <sha256> — cópia da função de scripts/f08b-ia.sh,
# definida só se o script da etapa ainda não a tiver
if ! declare -F baixar > /dev/null; then
baixar() {
  local url=$1 f=$LFS/sources/$2 sha=$3
  if [ -f "$f" ] && echo "$sha  $f" | sha256sum -c --status; then
    echo "já descarregado e verificado: $f"; return 0
  fi
  rm -f "$f"
  wget -nv -c -O "$f.part" "$url" || return 1
  echo "$sha  $f.part" | sha256sum -c || { echo "SHA-256 errado em $f.part (apagado)"; rm -f "$f.part"; return 1; }
  mv -v "$f.part" "$f"
}
fi

# --- 1. downloads (host)
tema_descarregar() {
  baixar $WSGTK_URL $WSGTK_TB $WSGTK_SHA256 || return 1
  baixar $WSICO_URL $WSICO_TB $WSICO_SHA256 || return 1
  baixar $WSCUR_URL $WSCUR_TB $WSCUR_SHA256 || return 1
  baixar $DOCKLIKE_URL $DOCKLIKE_TB $DOCKLIKE_SHA256 || return 1
  baixar $INTER_URL $INTER_TB $INTER_SHA256 || return 1
  baixar $JBMONO_URL $JBMONO_TB $JBMONO_SHA256 || return 1
}

# --- 2. dock: xfce4-docklike-plugin (meson, só X11: o gtk-layer-shell do backend Wayland não existe)
tema_docklike() {
  in_chroot "set -e
    cd /sources
    rm -rf $DOCKLIKE_DIR
    tar -xf $DOCKLIKE_TB
    cd $DOCKLIKE_DIR
    mkdir build
    cd build
    meson setup --prefix=/usr --libdir=/usr/lib --buildtype=release -D x11=enabled -D wayland=disabled ..
    ninja
    ninja install
    install -v -D -m644 ../COPYING /usr/share/doc/$DOCKLIKE_DIR/COPYING
    cd /sources
    rm -rf $DOCKLIKE_DIR
    test -f /usr/lib/xfce4/panel/plugins/libdocklike.so
    test -f /usr/share/xfce4/panel/plugins/docklike.desktop
    ! ldd /usr/lib/xfce4/panel/plugins/libdocklike.so | grep 'not found'" || return 1
}

# --- 3. tema GTK/xfwm4: variantes pré-geradas de release/ (Light por omissão; Dark e -solid,
# sem transparências, ficam disponíveis). Só se instalam gtk-2.0, gtk-3.0, gtk-4.0, xfwm4 e
# index.theme: gnome-shell, cinnamon, unity, plank e metacity não se usam no Xfce (e o gnome-shell
# traz o logótipo da Apple no botão "Atividades").
tema_gtk() {
  in_chroot "set -e
    cd /sources
    rm -rf $WSGTK_DIR
    tar -xf $WSGTK_TB $WSGTK_DIR/release $WSGTK_DIR/COPYING
    install -v -d -m755 /usr/share/themes
    for t in WhiteSur-Light WhiteSur-Dark WhiteSur-Light-solid WhiteSur-Dark-solid; do
      rm -rf /usr/share/themes/\$t
      tar -xf $WSGTK_DIR/release/\$t.tar.xz -C /usr/share/themes
      rm -rf /usr/share/themes/\$t/{gnome-shell,cinnamon,unity,plank,metacity-1}
      test -f /usr/share/themes/\$t/gtk-3.0/gtk.css
      test -f /usr/share/themes/\$t/xfwm4/themerc
    done
    chmod -R u=rwX,go=rX /usr/share/themes/WhiteSur-*
    install -v -D -m644 $WSGTK_DIR/COPYING /usr/share/doc/whitesur-gtk-theme-$WSGTK_TAG/COPYING
    rm -rf $WSGTK_DIR
    ls /usr/share/themes" || return 1
}

# --- 4. ícones: o install.sh do WhiteSur só usa cp/sed/ln e gtk-update-icon-cache (instala WhiteSur,
# WhiteSur-light e WhiteSur-dark). Depois troca-se o logótipo da Apple (start-here*) pelo da distro
# e apaga-se o folder-apple (pasta com o logótipo da Apple; nenhum programa o usa) e as ligações
# simbólicas que ficarem a apontar para nada.
tema_icones() {
  in_chroot "set -e
    cd /sources
    rm -rf $WSICO_DIR
    tar -xf $WSICO_TB
    cd $WSICO_DIR
    bash ./install.sh -d /usr/share/icons
    install -v -D -m644 COPYING /usr/share/doc/whitesur-icon-theme-$WSICO_TAG/COPYING
    install -v -m644 AUTHORS /usr/share/doc/whitesur-icon-theme-$WSICO_TAG/AUTHORS
    cd /sources
    rm -rf $WSICO_DIR" || return 1
  install -v -D -m644 $TEMA/raiz/usr/share/icons/hicolor/scalable/apps/ianinja-logo.svg \
    $LFS/usr/share/icons/hicolor/scalable/apps/ianinja-logo.svg || return 1
  install -v -m644 $TEMA/raiz/usr/share/icons/hicolor/scalable/apps/ianinja-logo-symbolic.svg \
    $LFS/usr/share/icons/hicolor/scalable/apps/ianinja-logo-symbolic.svg || return 1
  in_chroot "set -e
    for d in /usr/share/icons/WhiteSur /usr/share/icons/WhiteSur-light /usr/share/icons/WhiteSur-dark; do
      test -f \$d/index.theme
      find \$d -type f -name start-here.svg -exec cp -v /usr/share/icons/hicolor/scalable/apps/ianinja-logo.svg {} \;
      find \$d -type f -name start-here-symbolic.svg -exec cp -v /usr/share/icons/hicolor/scalable/apps/ianinja-logo-symbolic.svg {} \;
      find \$d -name 'folder-apple*' -print -delete
      find \$d -xtype l -delete
      gtk-update-icon-cache -f -t \$d
    done
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor
    du -sh /usr/share/icons/WhiteSur*" || return 1
}

# --- 5. cursores: dist/ do repositório (cursores X já gerados; o build.sh precisaria do inkscape)
tema_cursores() {
  in_chroot "set -e
    cd /sources
    rm -rf $WSCUR_DIR
    tar -xf $WSCUR_TB
    rm -rf /usr/share/icons/WhiteSur-cursors
    cp -r $WSCUR_DIR/dist /usr/share/icons/WhiteSur-cursors
    chmod -R u=rwX,go=rX /usr/share/icons/WhiteSur-cursors
    install -v -D -m644 $WSCUR_DIR/LICENSE /usr/share/doc/whitesur-cursors-${WSCUR_COMMIT:0:7}/LICENSE
    rm -rf $WSCUR_DIR
    test -f /usr/share/icons/WhiteSur-cursors/index.theme
    test -e /usr/share/icons/WhiteSur-cursors/cursors/left_ptr" || return 1
}

# --- 6. fontes: Inter (estática, 10 estilos) e JetBrains Mono (6 estilos), zips extraídos com o
# módulo zipfile do Python (o unzip não está instalado)
tema_fontes() {
  in_chroot "set -e
    cd /sources
    rm -rf tema-inter tema-jbmono
    python3 -I -m zipfile -e $INTER_TB tema-inter
    python3 -I -m zipfile -e $JBMONO_TB tema-jbmono
    install -v -d -m755 /usr/share/fonts/inter /usr/share/fonts/jetbrains-mono
    for s in Regular Italic Light LightItalic Medium MediumItalic SemiBold SemiBoldItalic Bold BoldItalic; do
      install -v -m644 tema-inter/extras/ttf/Inter-\$s.ttf /usr/share/fonts/inter
    done
    for s in Regular Italic Medium MediumItalic Bold BoldItalic; do
      install -v -m644 tema-jbmono/fonts/ttf/JetBrainsMono-\$s.ttf /usr/share/fonts/jetbrains-mono
    done
    install -v -D -m644 tema-inter/LICENSE.txt /usr/share/doc/inter-$INTER_VER/LICENSE.txt
    install -v -D -m644 tema-jbmono/OFL.txt /usr/share/doc/jetbrains-mono-$JBMONO_VER/OFL.txt
    rm -rf tema-inter tema-jbmono
    fc-cache -f
    fc-list : family | grep -E '^(Inter|JetBrains Mono)' | sort -u" || return 1
}

# --- 7. árvore raiz/ (configuração por omissão) + atalho Super+Espaço + papel de parede por omissão
tema_config() {
  local d
  [ -d $TEMA/raiz ] || return 1
  cp -rv --no-preserve=ownership $TEMA/raiz/. $LFS/ || return 1
  chmod 755 $LFS/etc/skel/.config $LFS/etc/skel/.config/gtk-3.0 $LFS/var/lib/lightdm/.config \
    $LFS/var/lib/lightdm/.config/gtk-3.0 $LFS/usr/share/backgrounds/ianinja || return 1
  # gtk.css do painel (cantos da dock) para os utilizadores já existentes; nada em ~/.config/xfce4
  for d in $LFS/home/ninja $LFS/root; do
    rm -rf $d/.config/xfce4 || return 1
    install -v -D -m644 $TEMA/raiz/etc/skel/.config/gtk-3.0/gtk.css $d/.config/gtk-3.0/gtk.css || return 1
  done
  in_chroot "set -e
    chown -R ninja: /home/ninja/.config
    chown -R lightdm:lightdm /var/lib/lightdm/.config
    ls -ld /home/ninja/.config /home/ninja/.config/gtk-3.0 /var/lib/lightdm/.config" || return 1
  # imagem por omissão do xfdesktop (usada em monitores sem entrada em xfce4-desktop.xml)
  d=$LFS/usr/share/backgrounds/xfce
  [ -d $d ] || return 1
  if [ -f $d/xfce-x.svg ] && [ ! -L $d/xfce-x.svg ]; then
    mv -v $d/xfce-x.svg $d/xfce-x-original.svg || return 1
  fi
  ln -sfv ../ianinja/ianinja-claro.svg $d/xfce-x.svg || return 1
  tema_greeter_lingua || return 1
  tema_atalho || return 1
}

# O LightDM é lançado pelo init (/etc/rc.d/init.d/xdm) sem LANG, e o greeter ficava em C.UTF-8
# (data em inglês, indicador "C.utf8"). O PAM do greeter passa a ler também
# /etc/lightdm/ambiente-greeter (árvore raiz/, LANG=pt_PT.UTF-8) com um segundo pam_env.
tema_greeter_lingua() {
  local f=$LFS/etc/pam.d/lightdm-greeter
  [ -f $f ] || { echo "falta $f (instalado pelo lightdm)"; return 1; }
  [ -f $LFS/etc/lightdm/ambiente-greeter ] || return 1
  if ! grep -q 'envfile=/etc/lightdm/ambiente-greeter' $f; then
    sed -i '0,/^auth[[:space:]]\+required[[:space:]]\+pam_env.so.*/s||&\nauth      required pam_env.so readenv=1 envfile=/etc/lightdm/ambiente-greeter|' $f || return 1
  fi
  grep -n 'pam_env' $f
  grep -q 'envfile=/etc/lightdm/ambiente-greeter' $f || return 1
}

# Os atalhos de teclado por omissão vêm do libxfce4ui (/etc/xdg/.../xfce4-keyboard-shortcuts.xml) e o
# ficheiro de sistema substitui a lista inteira: em vez de o reescrever, acrescenta-se <Super>space
# à secção commands/default do ficheiro instalado (python3 xml.etree; xmlstarlet não existe).
tema_atalho() {
  local f=$LFS/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
  [ -f $f ] || { echo "falta $f (instalado pelo libxfce4ui)"; return 1; }
  python3 -I - $f <<'EOF' || return 1
import sys, xml.etree.ElementTree as ET
f = sys.argv[1]
arv = ET.parse(f)
raiz = arv.getroot()
cmds = raiz.find("./property[@name='commands']/property[@name='default']")
if cmds is None:
    sys.exit("secção commands/default não encontrada")
tecla = "<Super>space"
p = cmds.find("./property[@name='%s']" % tecla)
if p is None:
    p = ET.SubElement(cmds, "property", {"name": tecla, "type": "string", "value": "xfce4-appfinder --collapsed"})
    ET.SubElement(p, "property", {"name": "startup-notify", "type": "bool", "value": "true"})
    print("acrescentado:", tecla, "-> xfce4-appfinder --collapsed")
else:
    print("já existe:", tecla, "->", p.get("value"))
ET.indent(arv, "  ")
arv.write(f, encoding="UTF-8", xml_declaration=True)
EOF
  grep -n 'Super&gt;space' $f || return 1
}

# --- 8. verificação final
tema_verificar() {
  local f falta=0
  for f in \
    etc/xdg/xfce4/xfconf/xfce-perchannel-xml/{xsettings,xfwm4,xfce4-desktop,xfce4-terminal,xfce4-appfinder,xfce4-keyboard-shortcuts}.xml \
    etc/xdg/xfce4/panel/default.xml etc/xdg/xfce4/panel/docklike.rc etc/xdg/xfce4/terminal/terminalrc \
    etc/gtk-3.0/settings.ini etc/fonts/conf.d/52-ianinja-tema.conf etc/lightdm/lightdm-gtk-greeter.conf \
    etc/skel/.config/gtk-3.0/gtk.css home/ninja/.config/gtk-3.0/gtk.css root/.config/gtk-3.0/gtk.css \
    var/lib/lightdm/.config/gtk-3.0/gtk.css usr/share/icons/default/index.theme \
    usr/share/backgrounds/ianinja/ianinja-claro.svg usr/share/backgrounds/xfce/xfce-x.svg \
    usr/share/icons/hicolor/scalable/apps/ianinja-logo.svg usr/share/icons/hicolor/scalable/apps/ianinja-logo-symbolic.svg \
    usr/share/themes/WhiteSur-Light/gtk-3.0/gtk.css usr/share/themes/WhiteSur-Light/xfwm4/themerc \
    usr/share/icons/WhiteSur/index.theme usr/share/icons/WhiteSur/icon-theme.cache \
    usr/share/icons/WhiteSur-cursors/index.theme usr/share/fonts/inter/Inter-Regular.ttf \
    usr/share/fonts/jetbrains-mono/JetBrainsMono-Regular.ttf \
    usr/lib/xfce4/panel/plugins/libdocklike.so usr/share/xfce4/panel/plugins/docklike.desktop; do
    if [ -e "$LFS/$f" ]; then echo "ok    /$f"; else echo "FALTA /$f"; falta=1; fi
  done
  [ -d $LFS/home/ninja/.config/xfce4 ] && { echo "não devia existir /home/ninja/.config/xfce4"; falta=1; }
  [ $falta = 0 ] || return 1
  # XML válidos (xfconf, painel, fontconfig, SVG)
  python3 -I - $LFS <<'EOF' || return 1
import sys, glob, xml.etree.ElementTree as ET
L = sys.argv[1]
fich = sorted(glob.glob(L + "/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/*.xml")) + [
    L + "/etc/xdg/xfce4/panel/default.xml", L + "/etc/fonts/conf.d/52-ianinja-tema.conf",
    L + "/usr/share/backgrounds/ianinja/ianinja-claro.svg",
    L + "/usr/share/icons/hicolor/scalable/apps/ianinja-logo.svg",
    L + "/usr/share/icons/hicolor/scalable/apps/ianinja-logo-symbolic.svg"]
erros = 0
for f in fich:
    try:
        ET.parse(f); print("XML ok", f[len(L):])
    except Exception as e:
        print("XML INVÁLIDO", f[len(L):], e); erros += 1
r = ET.parse(L + "/etc/xdg/xfce4/panel/default.xml").getroot()
plugins = [p.get("value") for p in r.findall("./property[@name='plugins']/property")]
print("plugins do painel:", " ".join(plugins))
if "docklike" not in plugins: erros += 1
sys.exit(1 if erros else 0)
EOF
  # no chroot: fontes, temas, caches e desenho dos SVG pelo librsvg
  in_chroot "set -e
    falha() { echo \"FALTA: \$*\"; exit 1; }
    fc-match sans-serif | tee /dev/stderr | grep -q Inter || falha 'Inter como sans-serif'
    fc-match monospace | tee /dev/stderr | grep -q 'JetBrains Mono' || falha 'JetBrains Mono como monospace'
    fc-list : family | grep -q '^Inter' || falha 'família Inter'
    for t in WhiteSur WhiteSur-light WhiteSur-dark hicolor; do
      test -s /usr/share/icons/\$t/icon-theme.cache || falha \"cache de ícones \$t\"
    done
    test -f /usr/share/icons/WhiteSur/places/scalable/start-here.svg || falha start-here
    cmp -s /usr/share/icons/WhiteSur/places/scalable/start-here.svg /usr/share/icons/hicolor/scalable/apps/ianinja-logo.svg || falha 'logótipo da distro em start-here'
    grep -q '^Inherits=WhiteSur-cursors' /usr/share/icons/default/index.theme || falha 'cursor por omissão'
    gdk-pixbuf-query-loaders 2>/dev/null | grep -qi svg || falha 'loader SVG do gdk-pixbuf (librsvg)'
    for s in /usr/share/backgrounds/ianinja/ianinja-claro.svg /usr/share/icons/hicolor/scalable/apps/ianinja-logo.svg /usr/share/icons/hicolor/scalable/apps/ianinja-logo-symbolic.svg; do
      rsvg-convert -w 256 -o /tmp/tema-teste.png \$s || falha \"desenho de \$s\"
    done
    # o xfdesktop e o greeter abrem o papel de parede pelo gdk-pixbuf (deteção do formato pelos
    # primeiros bytes), não pelo rsvg-convert: testar pelo mesmo caminho
    gdk-pixbuf-thumbnailer -s 256 /usr/share/backgrounds/ianinja/ianinja-claro.svg /tmp/tema-teste.png || falha 'papel de parede pelo gdk-pixbuf'
    test -s /tmp/tema-teste.png || falha 'papel de parede pelo gdk-pixbuf'
    rm -f /tmp/tema-teste.png
    grep -q 'envfile=/etc/lightdm/ambiente-greeter' /etc/pam.d/lightdm-greeter || falha 'língua do greeter'
    grep -q 'color: #363636' /home/ninja/.config/gtk-3.0/gtk.css || falha 'texto escuro do painel'
    readlink -f /usr/share/backgrounds/xfce/xfce-x.svg | grep -q ianinja-claro.svg || falha 'fundo por omissão do xfdesktop'
    if ldd /usr/lib/xfce4/panel/plugins/libdocklike.so | grep 'not found'; then falha 'bibliotecas do docklike'; fi
    grep -q '^theme-name = WhiteSur-Light' /etc/lightdm/lightdm-gtk-greeter.conf || falha 'tema do greeter'
    stat -c '%U %n' /var/lib/lightdm/.config/gtk-3.0/gtk.css /home/ninja/.config/gtk-3.0/gtk.css
    echo 'tema: tudo no sítio'" || return 1
}
