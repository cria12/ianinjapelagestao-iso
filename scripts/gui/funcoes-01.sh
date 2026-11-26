# F8d — funções do bloco 1 (base gráfica: bibliotecas gerais, Xorg, Mesa). Lido por scripts/f08d-gui.sh.
# Correm sob corre_passo (sem errexit): cada comando termina com || return 1.

# xorg_teclado — teclado português no X (o mesmo que a consola: KEYMAP="pt-latin1").
# O livro configura o teclado na página "Xorg-7 Testing and Configuration" (não transcrita);
# usa-se o ficheiro InputClass de /etc/X11/xorg.conf.d, que o LightDM e o Xfce respeitam
# (no Xfce, "usar predefinições do sistema" no teclado).
xorg_teclado() {
  mkdir -p $LFS/etc/X11/xorg.conf.d || return 1
  cat > $LFS/etc/X11/xorg.conf.d/00-keyboard.conf << "EOF2" || return 1
# ianinjapelagestao: teclado português (igual à consola, /etc/sysconfig/console)
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "pt"
EndSection
EOF2
}

# mesa_vgem — o livro pede CONFIG_DRM_VGEM para o llvmpipe/softpipe ("couldn't get an RGB,
# Double-buffered visual") e lembra que, como módulo, não é carregado sozinho. O kernel da F7
# tem DRM_VGEM=m: carrega-se no arranque pelo bootscript modules (/etc/sysconfig/modules).
mesa_vgem() {
  local f=$LFS/etc/sysconfig/modules
  [ -f $f ] || { echo "$f não existe"; return 1; }
  if ! grep -q '^vgem' $f; then
    sed -i '/^# End \/etc\/sysconfig\/modules/i vgem' $f || return 1
  fi
  grep -q '^vgem' $f || { echo "vgem não ficou em $f"; return 1; }
}

# limpar_machine_id — o livro manda gerar /var/lib/dbus/machine-id (dbus-uuidgen --ensure) para
# as compilações no chroot; numa ISO ficaria igual em todas as cópias. O bootscript dbus do BLFS
# volta a gerá-lo no arranque (dbus-uuidgen --ensure antes do dbus-daemon). Deve ser o ÚLTIMO
# passo da F8d (as páginas seguintes podem precisar dele); /etc/machine-id é um symlink para ele.
limpar_machine_id() {
  rm -fv $LFS/var/lib/dbus/machine-id || return 1
}
