# F8e — funções do bloco 1 (dependências das aplicações e comando instalar-aplicacoes).
# Lido por scripts/f08e-apps.sh. Correm sob corre_passo (sem errexit): cada comando termina com || return 1.

# cups_sem_arranque — o CUPS só é preciso pela biblioteca libcups.so.2 (o Chrome e o VS Code
# ligam-se a ela). O serviço fica instalado (/etc/rc.d/init.d/cups, links K00 de paragem) mas NÃO
# arranca no boot: tiram-se os S35cups dos níveis 2-5 e esconde-se o atalho "Manage Printing"
# (abriria http://localhost:631 sem servidor). Para imprimir: sudo /etc/rc.d/init.d/cups start
# (ou, para sempre: sudo ln -s ../init.d/cups /etc/rc.d/rc5.d/S35cups, idem rc2-4), e instalar
# o cups-filters (não incluído).
cups_sem_arranque() {
  local n f=$LFS/usr/share/applications/cups.desktop
  [ -x $LFS/etc/rc.d/init.d/cups ] || { echo "falta /etc/rc.d/init.d/cups (passo cups-bootscript)"; return 1; }
  for n in 2 3 4 5; do
    rm -fv $LFS/etc/rc.d/rc$n.d/S35cups || return 1
  done
  if [ -f $f ] && ! grep -q '^NoDisplay=true' $f; then
    sed -i '/^\[Desktop Entry\]/a NoDisplay=true' $f || return 1
  fi
  if ls $LFS/etc/rc.d/rc?.d/S*cups > /dev/null 2>&1; then echo "ainda há links S*cups"; return 1; fi
  [ -e $LFS/usr/lib/libcups.so.2 ] || { echo "falta /usr/lib/libcups.so.2"; return 1; }
}

# apps_instalar_comando — /usr/bin/instalar-aplicacoes (descarrega VS Code, Chrome, Claude Code e
# Codex no 1.º uso), o atalho "Instalar aplicações" (abre o xfce4-terminal com o menu), o ícone,
# e a dock (docklike.rc da árvore do tema, agora com o lançador instalar-aplicacoes fixado).
# O docklike.rc só é lido por quem ainda não tem ~/.config/xfce4/panel/docklike-<id>.rc
# (na construção nenhum utilizador o tem: confirmado em /home/ninja).
apps_instalar_comando() {
  local d=$P/scripts/apps
  install -v -m755 $d/instalar-aplicacoes $LFS/usr/bin/instalar-aplicacoes || return 1
  cp -rv --no-preserve=ownership $d/raiz/. $LFS/ || return 1
  install -v -D -m644 $P/scripts/gui/tema/raiz/etc/xdg/xfce4/panel/docklike.rc \
    $LFS/etc/xdg/xfce4/panel/docklike.rc || return 1
  install -v -d -m755 $LFS/var/lib/instalar-aplicacoes || return 1
  in_chroot "set -e
    bash -n /usr/bin/instalar-aplicacoes
    desktop-file-validate /usr/share/applications/instalar-aplicacoes.desktop
    bash -n /usr/local/bin/instalar-tudo-click.sh && test -x /usr/local/bin/instalar-tudo-click.sh
    desktop-file-validate /etc/xdg/autostart/instalar-tudo-default.desktop
    update-desktop-database -q /usr/share/applications
    gtk-update-icon-cache -qtf /usr/share/icons/hicolor
    grep -q '^pinned=.*instalar-aplicacoes;' /etc/xdg/xfce4/panel/docklike.rc
    instalar-aplicacoes -h > /dev/null
    instalar-aplicacoes -l
    for c in curl tar sha256sum python3 ar flock xfce4-terminal sudo unshare findmnt dbus-send; do
      type -P \$c > /dev/null || { echo \"falta \$c\"; exit 1; }
    done" || return 1
}

# apps_verificar_bibliotecas — bibliotecas que o ldd mostrou em falta no VS Code 1.145 e no
# Chrome 157 (binários oficiais; ver decisoes-01.txt) e as que eles já encontravam: têm de existir
# e não ter dependências por resolver. Os binários oficiais não estão aqui (não vão na ISO).
apps_verificar_bibliotecas() {
  in_chroot "set -e
    for l in libnspr4.so libplc4.so libplds4.so libnss3.so libnssutil3.so libsmime3.so libssl3.so \
             libsoftokn3.so libfreebl3.so libcups.so.2 libsecret-1.so.0 libgnutls.so.30 \
             libxkbfile.so.1 libXss.so.1 libgbm.so.1 libgtk-3.so.0 libnotify.so.4 libasound.so.2 \
             libatk-bridge-2.0.so.0 libxkbcommon.so.0 libdrm.so.2 libudev.so.1; do
      f=/usr/lib/\$l
      [ -e \$f ] || { echo \"falta \$f\"; exit 1; }
      if ldd \$f | grep 'not found'; then echo \"\$f tem dependências em falta\"; exit 1; fi
    done
    for c in xdg-open xdg-settings xdg-mime xdg-icon-resource xdg-desktop-menu; do type -P \$c; done
    echo 'bibliotecas e utilitários das aplicações: OK'" || return 1
}
