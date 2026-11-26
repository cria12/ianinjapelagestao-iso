# scripts/apps/funcoes-05.sh — funções próprias do bloco 5 da F8e: OSTree e Flatpak (não estão no
# BLFS 12.4: compilados de fonte, versão fixada + SHA-256), o remote Flathub, a integração com o
# Xfce (menus, tema WhiteSur nas aplicações Flatpak, portais) e a "Loja" gráfica.
# Carregado por scripts/f08e-apps.sh. Correm sob corre_passo (sem errexit): cada comando termina
# em "|| return 1". Downloads no host para $LFS/sources (função baixar da etapa, SHA-256).
# Ver scripts/apps/decisoes-05.txt.

# libostree — https://github.com/ostreedev/ostree/releases (SHA-256 calculado no ficheiro descarregado)
LOJA_OSTREE_VER=2026.6
LOJA_OSTREE_TB=libostree-$LOJA_OSTREE_VER.tar.xz
LOJA_OSTREE_URL=https://github.com/ostreedev/ostree/releases/download/v$LOJA_OSTREE_VER/$LOJA_OSTREE_TB
LOJA_OSTREE_SHA256=164b8226aea6a0e6601036de02a5e3b62307bae25890ed557fb4e19020bd5974

# Flatpak 1.18.x (série estável; 1.19 é a de desenvolvimento). SHA-256 = o do ficheiro
# flatpak-1.18.4.tar.xz.sha256sum publicado no próprio release (conferido).
LOJA_FLATPAK_VER=1.18.4
LOJA_FLATPAK_TB=flatpak-$LOJA_FLATPAK_VER.tar.xz
LOJA_FLATPAK_URL=https://github.com/flatpak/flatpak/releases/download/$LOJA_FLATPAK_VER/$LOJA_FLATPAK_TB
LOJA_FLATPAK_SHA256=b899a7a00c48d2c626cb8ec33fe556720b376c25805d7222430c0fdca4c6ac8d

# Definição do remote Flathub (URL do repositório + chave GPG pública). Se o Flathub mudar o
# ficheiro (raro: a chave é a mesma desde 2017) o SHA-256 falha e é preciso rever e atualizar aqui.
LOJA_FLATHUB_URL=https://dl.flathub.org/repo/flathub.flatpakrepo
LOJA_FLATHUB_REPO=flathub.flatpakrepo
LOJA_FLATHUB_SHA256=3371dd250e61d9e1633630073fefda153cd4426f72f4afa0c3373ae2e8fea03a

LOJA_SRC=$P/scripts/apps/loja

# loja_compilar <tarball> <diretório> <comandos> — extrai em /sources (chroot), corre, apaga
loja_compilar() {
  in_chroot "set -e; cd /sources; rm -rf $2; tar -xf $1; cd $2
    $3
    cd /sources; rm -rf $2"
}

# loja_ostree — libostree + ostree (backend de armazenamento do Flatpak). HTTP com libcurl (já
# instalada; dispensa o libsoup), assinaturas GPG com gpgme, checksums com OpenSSL, rofiles-fuse
# com fuse3. Sem systemd, SELinux, Avahi, composefs, gtk-doc nem páginas de manual (DocBook).
loja_ostree() {
  baixar $LOJA_OSTREE_URL $LOJA_OSTREE_TB $LOJA_OSTREE_SHA256 || return 1
  loja_compilar $LOJA_OSTREE_TB libostree-$LOJA_OSTREE_VER "
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static \
                --with-curl --without-soup --without-soup3 --with-gpgme --with-crypto=openssl \
                --without-libsystemd --with-systemdsystemunitdir=no --without-selinux \
                --without-avahi --without-composefs --without-dracut --without-mkinitcpio \
                --disable-gtk-doc --disable-man --enable-introspection=yes
    make
    make install
    rm -vf /etc/grub.d/15_ostree
    ostree --version" || return 1
}

# loja_flatpak — Flatpak com o bubblewrap e o xdg-dbus-proxy do sistema (páginas do BLFS),
# system helper (polkit) para instalações de sistema e /var/lib/flatpak; sem systemd, dconf,
# malcontent, SELinux, documentação nem testes. Cria o utilizador de sistema "flatpak" (o
# system helper exige-o; o livro não tem systemd-sysusers) e tira as unidades systemd.
loja_flatpak() {
  baixar $LOJA_FLATPAK_URL $LOJA_FLATPAK_TB $LOJA_FLATPAK_SHA256 || return 1
  loja_compilar $LOJA_FLATPAK_TB flatpak-$LOJA_FLATPAK_VER "
    mkdir build; cd build
    meson setup .. --prefix=/usr --buildtype=release --sysconfdir=/etc --localstatedir=/var \
      -D system_install_dir=/var/lib/flatpak \
      -D system_bubblewrap=/usr/bin/bwrap -D system_dbus_proxy=/usr/bin/xdg-dbus-proxy \
      -D systemd=disabled -D dconf=disabled -D malcontent=disabled -D selinux_module=disabled \
      -D gtkdoc=disabled -D docbook_docs=disabled -D man=disabled \
      -D tests=false -D installed_tests=false \
      -D gir=enabled -D libzstd=enabled -D seccomp=enabled -D system_helper=enabled \
      -D privileged_group=wheel -D wayland_security_context=auto
    ninja
    ninja install
    rm -rvf /usr/lib/systemd/system/flatpak-* /usr/lib/systemd/user/flatpak-* \
            /usr/lib/systemd/system-environment-generators/*flatpak* \
            /usr/lib/systemd/user-environment-generators/*flatpak*
    rmdir -v --ignore-fail-on-non-empty /usr/lib/systemd/system /usr/lib/systemd/*-environment-generators 2>/dev/null || true
    getent group flatpak > /dev/null || groupadd -r flatpak
    getent passwd flatpak > /dev/null || useradd -r -g flatpak -d / -s /bin/false -c 'Flatpak system helper' flatpak
    install -v -dm755 /var/lib/flatpak
    flatpak --version
    test -f /etc/profile.d/flatpak.sh" || return 1
}

# loja_flathub — remote Flathub na instalação do sistema e na do utilizador ninja (modo --user,
# o que a Loja usa: sem sudo, em ~/.local/share/flatpak, que fica no disco de dados quando há
# persistência); tema WhiteSur-Light visível pelas aplicações GTK 3 do Flatpak; portais do
# Xfce = gtk; valores do org.gnome.desktop.interface (portal Settings) iguais aos do Xfce.
loja_flathub() {
  local h=$LFS/home/ninja t=$LFS/usr/share/themes/WhiteSur-Light d
  baixar $LOJA_FLATHUB_URL $LOJA_FLATHUB_REPO $LOJA_FLATHUB_SHA256 || return 1
  install -v -D -m644 $LFS/sources/$LOJA_FLATHUB_REPO $LFS/usr/share/loja/flathub.flatpakrepo || return 1
  # portais: o xdg-desktop-portal >= 1.18 escolhe o backend por <desktop>-portals.conf
  install -v -d -m755 $LFS/usr/share/xdg-desktop-portal || return 1
  printf '# ianinjapelagestao: no Xfce os portais (abrir ficheiros, imprimir, definições...) são os do\n# xdg-desktop-portal-gtk.\n[preferred]\ndefault=gtk\n' \
    > $LFS/usr/share/xdg-desktop-portal/xfce-portals.conf || return 1
  cat > $LFS/usr/share/glib-2.0/schemas/90_ianinjapelagestao-loja.gschema.override << "EOF" || return 1
# ianinjapelagestao: o portal Settings (xdg-desktop-portal-gtk) mostra estes valores às aplicações
# Flatpak; iguais aos do Xfce (xsettings.xml).
[org.gnome.desktop.interface]
gtk-theme='WhiteSur-Light'
icon-theme='WhiteSur'
cursor-theme='WhiteSur-cursors'
font-name='Inter 10'
color-scheme='prefer-light'
EOF
  [ -d $t/gtk-3.0 ] || { echo "falta o tema $t"; return 1; }
  # tema GTK 3 em ~/.themes (o /usr do sistema não é visível dentro da sandbox) + override global
  for d in $LFS/etc/skel $h; do
    install -v -d -m755 $d/.themes/WhiteSur-Light $d/.local/share/flatpak/overrides || return 1
    rm -rf $d/.themes/WhiteSur-Light/gtk-3.0
    cp -r $t/gtk-3.0 $t/index.theme $d/.themes/WhiteSur-Light/ || return 1
    printf '[Context]\nfilesystems=~/.themes:ro;\n' > $d/.local/share/flatpak/overrides/global || return 1
  done
  in_chroot "set -e
    glib-compile-schemas /usr/share/glib-2.0/schemas
    flatpak remote-add --system --if-not-exists flathub /usr/share/loja/flathub.flatpakrepo
    flatpak remote-list --system --columns=name,url | grep -q '^flathub'
    chown -R ninja:ninja /home/ninja/.themes /home/ninja/.local
    su -s /bin/bash ninja -c 'HOME=/home/ninja flatpak remote-add --user --if-not-exists flathub /usr/share/loja/flathub.flatpakrepo' \
      && su -s /bin/bash ninja -c 'HOME=/home/ninja flatpak remote-list --user' | grep -q '^flathub' \
      || echo '[AVISO-TESTE] remote flathub do ninja não criado na construção (a Loja cria-o no 1.º uso)'
    flatpak remote-list --system" || return 1
}

# loja_instalar — a Loja: /usr/share/loja (programa Python + GTK 3, CSS), /usr/bin/loja, atalho,
# ícone e lançador fixado na dock (docklike.rc da árvore do tema).
loja_instalar() {
  local f
  install -v -d -m755 $LFS/usr/share/loja || return 1
  for f in loja.py loja_flathub.py loja_flatpak.py estilo.css; do
    install -v -m644 $LOJA_SRC/$f $LFS/usr/share/loja/$f || return 1
  done
  install -v -m755 $LOJA_SRC/loja $LFS/usr/bin/loja || return 1
  install -v -D -m644 $P/scripts/apps/raiz/usr/share/applications/loja.desktop \
    $LFS/usr/share/applications/loja.desktop || return 1
  install -v -D -m644 $P/scripts/apps/raiz/usr/share/icons/hicolor/scalable/apps/loja.svg \
    $LFS/usr/share/icons/hicolor/scalable/apps/loja.svg || return 1
  install -v -D -m644 $P/scripts/gui/tema/raiz/etc/xdg/xfce4/panel/docklike.rc \
    $LFS/etc/xdg/xfce4/panel/docklike.rc || return 1
  in_chroot "set -e
    python3 -m py_compile /usr/share/loja/loja.py /usr/share/loja/loja_flathub.py /usr/share/loja/loja_flatpak.py
    rm -rf /usr/share/loja/__pycache__
    desktop-file-validate /usr/share/applications/loja.desktop
    update-desktop-database -q /usr/share/applications
    gtk-update-icon-cache -qtf /usr/share/icons/hicolor
    grep -q '^pinned=.*;loja;' /etc/xdg/xfce4/panel/docklike.rc" || return 1
}

# loja_verificar — ferramentas no sítio e a lógica da Loja sem rede nem ecrã (--verificar: importa
# o GTK, lê o CSS, lê a lista do flatpak e o estado live/persistência)
loja_verificar() {
  in_chroot "set -e
    for c in flatpak ostree bwrap xdg-dbus-proxy fusermount3 gpg gpgv appstreamcli loja; do
      type -P \$c > /dev/null || { echo \"falta \$c\"; exit 1; }
    done
    ls -l /usr/bin/fusermount3 | grep -q '^-rwsr'
    test -x /usr/libexec/xdg-desktop-portal
    test -x /usr/libexec/xdg-desktop-portal-gtk
    test -x /usr/libexec/flatpak-system-helper
    test -f /usr/share/dbus-1/services/org.freedesktop.portal.Desktop.service
    test -f /usr/share/xdg-desktop-portal/portals/gtk.portal
    bwrap --version; flatpak --version; ostree --version | head -3
    bwrap --ro-bind / / --dev /dev --proc /proc true \
      || echo '[AVISO-TESTE] bwrap não criou uma sandbox no chroot (no sistema arrancado usa namespaces de utilizador)'
    flatpak --installations
    su -s /bin/bash ninja -c 'HOME=/home/ninja loja --verificar'" || return 1
}
