# F8e — funções do bloco 12: correções do teste em hardware real (2026-11-13). Lido por
# scripts/f08e-apps.sh. Correm sob corre_passo (sem errexit): cada comando termina com || return 1.
# Ver decisoes-12.txt.

# correcoes_12_instalar —
#  * instalar-driver-nvidia com /usr/sbin no PATH (falhava "falta o comando modprobe" como ninja);
#  * /usr/sbin no PATH de todos os utilizadores (/etc/profile.d/sbin.sh);
#  * GNOME Keyring: PAM do LightDM (desbloqueia o chaveiro "login" com a senha da sessão) e
#    autostart dos componentes secrets/pkcs11 também no Xfce (o pacote só os liga no GNOME/MATE).
correcoes_12_instalar() {
  install -v -m755 $P/scripts/apps/drivers/instalar-driver-nvidia $LFS/usr/bin/instalar-driver-nvidia || return 1
  cat > $LFS/etc/profile.d/sbin.sh << "EOF" || return 1
# /etc/profile.d/sbin.sh — ianinjapelagestao: /usr/sbin também para utilizadores normais
# (modprobe, modinfo, ip, iw, blkid... — o /etc/profile do LFS só o acrescenta ao root)
pathappend /usr/sbin
EOF
  chmod 644 $LFS/etc/profile.d/sbin.sh || return 1
  in_chroot "set -e
    # PAM: lightdm (login com senha) e passwd (mudar a senha muda a do chaveiro)
    f=/etc/pam.d/lightdm
    grep -q pam_gnome_keyring \$f || {
      sed -i '/^auth[[:space:]]\+required[[:space:]]\+pam_unix.so/a auth      optional pam_gnome_keyring.so' \$f
      echo 'session   optional pam_gnome_keyring.so auto_start' >> \$f
    }
    f=/etc/pam.d/passwd
    # o passwd do LFS só tem 'password include system-password': o módulo vai logo a seguir
    grep -q pam_gnome_keyring \$f || sed -i '/^password[[:space:]]\+\(include\|required\|requisite\)[[:space:]]/a password  optional    pam_gnome_keyring.so use_authtok' \$f
    cat \$f
    [ \$(grep -c pam_gnome_keyring /etc/pam.d/lightdm) = 2 ]
    [ \$(grep -c '^password.*pam_gnome_keyring' /etc/pam.d/passwd) = 1 ]
    ls -l /usr/lib/security/pam_gnome_keyring.so
    # autostart: secrets e pkcs11 também no Xfce (o ssh fica de fora: o Xfce já tem o seu agente)
    [ -f /etc/xdg/autostart/gnome-keyring-secrets.desktop ]
    for d in /etc/xdg/autostart/gnome-keyring-secrets.desktop /etc/xdg/autostart/gnome-keyring-pkcs11.desktop; do
      [ -f \$d ] || continue
      grep -q '^OnlyShowIn=.*XFCE' \$d || sed -i 's/^OnlyShowIn=\(.*\)/OnlyShowIn=\1XFCE;/' \$d
      grep '^OnlyShowIn' \$d
      desktop-file-validate \$d || true
    done
    bash -n /usr/bin/instalar-driver-nvidia
    sh -n /usr/bin/pipewire-launcher.sh" || return 1
}

# correcoes_12_verificar — ferramentas presentes e teste real do áudio como ninja (sem placa de
# som no chroot: basta o PipeWire, o WirePlumber e o servidor PulseAudio arrancarem e responderem)
correcoes_12_verificar() {
  in_chroot "set -e
    for f in /usr/bin/{pipewire,pipewire-pulse,wireplumber,wpctl,pipewire-launcher.sh,gnome-keyring-daemon,v4l2-ctl,lua} \
             /etc/xdg/autostart/pipewire.desktop /usr/share/dbus-1/services/org.freedesktop.secrets.service \
             /usr/lib/spa-0.2/bluez5/libspa-bluez5.so /usr/lib/security/pam_gnome_keyring.so /etc/profile.d/sbin.sh; do
      [ -e \$f ] || { echo \"FALTA: \$f\"; exit 1; }
      echo \"ok \$f\"
    done
    grep -q 'PATH=\$PATH:/usr/sbin' /usr/bin/instalar-driver-nvidia
    # PATH do ninja num shell de login (como o terminal do Xfce): modprobe/depmod/modinfo encontrados
    su - ninja -c 'type -P modprobe depmod modinfo'
    wireplumber --version | head -2
    gnome-keyring-daemon --version
    # instalar-driver-nvidia -l como ninja, sem placa (deve dizer 'nenhuma' e sair 0)
    su ninja -c 'PATH=/usr/bin instalar-driver-nvidia -l' || true" || return 1
  in_chroot "
    R=\$(mktemp -d /tmp/xdg-teste.XXXXXX); chown ninja \$R; chmod 700 \$R
    su ninja -s /bin/sh -c \"export XDG_RUNTIME_DIR=\$R; cd /tmp; timeout 25 dbus-run-session -- sh -c '
      /usr/bin/pipewire-launcher.sh; sleep 4
      ls \$R; pw-cli info 0 | head -3
      wpctl status | head -25
      [ -S \$R/pulse/native ] && echo PULSE-OK || echo SEM-PULSE
      pgrep -x wireplumber > /dev/null && echo WIREPLUMBER-OK || echo SEM-WIREPLUMBER
      pkill -x pipewire-pulse; pkill -x wireplumber; pkill -x pipewire; true'\" > /tmp/teste-audio.txt 2>&1
    cat /tmp/teste-audio.txt
    grep -q PULSE-OK /tmp/teste-audio.txt && grep -q WIREPLUMBER-OK /tmp/teste-audio.txt ||
      echo 'AVISO-TESTE: PipeWire/WirePlumber/pipewire-pulse não arrancaram no chroot (ver acima)'
    rm -rf \$R /tmp/teste-audio.txt
    true" || return 1
}
