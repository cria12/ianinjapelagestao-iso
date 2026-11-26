# F8e — funções do bloco 9: Assistente de configuração do 1.º arranque (cria a conta do utilizador).
# Lido por scripts/f08e-apps.sh. Correm sob corre_passo (sem errexit): cada comando termina com
# || return 1. Ver decisoes-09.txt. Nada é compilado: são scripts Python 3 + GTK 3 (PyGObject do
# bloco 02) e o liblightdm-gobject (LightDM-1.typelib, F8d).
ASSISTENTE_SRC=$P/scripts/apps/assistente

# assistente_instalar — programa em /usr/share/ianinja-assistente, greeter e parte privilegiada em
# /usr/libexec/ianinja-assistente, comando /usr/sbin/ianinja-assistente, sessão de greeter
# (/usr/share/xgreeters), greeter-session do LightDM (lightdm.conf.d/60-*), regra do sudo para o
# utilizador lightdm e a dica do modo de texto. A imagem nunca sai "configurada".
assistente_instalar() {
  local s=$ASSISTENTE_SRC f
  install -v -d -m755 $LFS/usr/share/ianinja-assistente $LFS/usr/libexec/ianinja-assistente \
    $LFS/usr/share/xgreeters $LFS/etc/lightdm/lightdm.conf.d $LFS/etc/sudoers.d \
    $LFS/etc/profile.d $LFS/var/lib/ianinjapelagestao || return 1
  for f in assistente.py contas.py estilo.css; do
    install -v -m644 $s/$f $LFS/usr/share/ianinja-assistente/$f || return 1
  done
  install -v -m755 $s/greeter $LFS/usr/libexec/ianinja-assistente/greeter || return 1
  install -v -m755 $s/aplicar $LFS/usr/libexec/ianinja-assistente/aplicar || return 1
  install -v -m755 $s/ianinja-assistente $LFS/usr/sbin/ianinja-assistente || return 1
  install -v -m644 $s/ianinja-assistente.desktop $LFS/usr/share/xgreeters/ianinja-assistente.desktop || return 1
  install -v -m644 $s/60-ianinja-assistente.conf $LFS/etc/lightdm/lightdm.conf.d/60-ianinja-assistente.conf || return 1
  install -v -m440 $s/sudoers $LFS/etc/sudoers.d/ianinja-assistente || return 1
  install -v -m644 $s/profile.sh $LFS/etc/profile.d/ianinja-assistente.sh || return 1
  rm -fv $LFS/var/lib/ianinjapelagestao/configurado $LFS/etc/lightdm/lightdm.conf.d/70-ianinja-autologin.conf \
    $LFS/var/lib/lightdm/.ianinja-assistente-tentativas || return 1
  in_chroot "set -e
    chown -R root:root /usr/share/ianinja-assistente /usr/libexec/ianinja-assistente
    visudo -cf /etc/sudoers.d/ianinja-assistente
    bash -n /usr/libexec/ianinja-assistente/greeter
    bash -n /usr/sbin/ianinja-assistente
    bash -n /etc/profile.d/ianinja-assistente.sh
    python3 -c 'import ast, sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]' \
      /usr/share/ianinja-assistente/assistente.py /usr/share/ianinja-assistente/contas.py \
      /usr/libexec/ianinja-assistente/aplicar
    test -x /usr/bin/lightdm-gtk-greeter
    test -f /usr/lib/girepository-1.0/LightDM-1.typelib
    # o lightdm.conf não pode fixar greeter-session (ganharia ao lightdm.conf.d)
    ! grep -Eq '^[[:space:]]*greeter-session[[:space:]]*=' /etc/lightdm/lightdm.conf
    grep -qx 'greeter-session=ianinja-assistente' /etc/lightdm/lightdm.conf.d/60-ianinja-assistente.conf
    for c in useradd usermod userdel chpasswd sudo setxkbmap timeout; do type -P \$c > /dev/null || { echo \"falta \$c\"; exit 1; }; done
    test -f /usr/share/keymaps/i386/qwerty/br-abnt2.map.gz
    test -f /usr/share/keymaps/i386/qwerty/us.map.gz
    for z in Europe/Lisbon Atlantic/Madeira Atlantic/Azores America/Sao_Paulo America/Fortaleza America/Manaus \
             Africa/Luanda Africa/Maputo Atlantic/Cape_Verde Europe/London Europe/Paris America/New_York UTC; do
      test -e /usr/share/zoneinfo/\$z || { echo \"falta o fuso \$z\"; exit 1; }
    done" || return 1
}

# assistente_verificar — sem ecrã e sem tocar nas contas reais: o utilizador lightdm consegue usar o
# sudo só para o aplicar (estado), o assistente importa GTK + LightDM e lê o CSS como lightdm, e a
# criação completa de uma conta corre numa cópia de /etc em /tmp (useradd/chpasswd --root).
assistente_verificar() {
  in_chroot "set -e
    e=\$(su -s /bin/sh lightdm -c '/usr/bin/sudo -n /usr/libexec/ianinja-assistente/aplicar estado')
    echo \"estado visto pelo lightdm: \$e\"
    case \"\$e\" in ativo*|desligado*) ;; *) echo 'estado inesperado'; exit 1 ;; esac
    if su -s /bin/sh lightdm -c '/usr/bin/sudo -n /usr/libexec/ianinja-assistente/aplicar repor' 2>/dev/null; then
      echo 'ERRO: o lightdm conseguiu repor'; exit 1
    fi
    if su -s /bin/sh lightdm -c '/usr/bin/sudo -n /usr/bin/id' 2>/dev/null; then
      echo 'ERRO: o lightdm tem sudo para outros comandos'; exit 1
    fi
    su -s /bin/sh lightdm -c 'HOME=/var/lib/lightdm python3 -I /usr/share/ianinja-assistente/assistente.py --verificar'
    ianinja-assistente --estado
    T=/tmp/assistente-teste
    rm -rf \$T; mkdir -p \$T/etc/sysconfig \$T/etc/X11 \$T/var/lib \$T/home
    cp -a /etc/passwd /etc/group /etc/shadow /etc/gshadow /etc/login.defs /etc/default /etc/skel /etc/lightdm \$T/etc/
    cp -a /etc/X11/xorg.conf.d \$T/etc/X11/; cp -a /etc/sysconfig/console \$T/etc/sysconfig/
    echo '{\"nome_completo\": \"Ana Sousa\", \"utilizador\": \"ana\", \"senha\": \"Pastel-de-nata9\", \"autologin\": true, \"senha_root\": true, \"teclado\": \"br\", \"fuso\": \"America/Sao_Paulo\"}' \
      | python3 -I /usr/share/ianinja-assistente/contas.py criar --raiz \$T
    grep -q '^ana:x:[0-9]*:[0-9]*:Ana Sousa:/home/ana:/bin/bash\$' \$T/etc/passwd
    grep -E '^(wheel|audio|video|plugdev|lpadmin):' \$T/etc/group | grep -c ana | grep -qx 5
    grep -q '^ninja:!' \$T/etc/shadow
    grep -q '^hidden-users=.* ninja' \$T/etc/lightdm/users.conf
    grep -qx 'autologin-user=ana' \$T/etc/lightdm/lightdm.conf.d/70-ianinja-autologin.conf
    grep -q 'XkbLayout\" \"br\"' \$T/etc/X11/xorg.conf.d/00-keyboard.conf
    test -f \$T/home/ana/.bashrc && test \"\$(stat -c %U \$T/home/ana/.bashrc)\" != root
    test -f \$T/var/lib/ianinjapelagestao/configurado
    python3 -I /usr/share/ianinja-assistente/contas.py estado --raiz \$T | grep -q '^configurado'
    python3 -I /usr/share/ianinja-assistente/contas.py repor --raiz \$T
    ! grep -q '^ninja:!' \$T/etc/shadow
    rm -rf \$T
    # o sistema real continua intacto
    test ! -e /var/lib/ianinjapelagestao/configurado
    ! grep -q '^ana:' /etc/passwd
    ! grep -q '^ninja:!' /etc/shadow
    echo 'assistente: verificação OK'" || return 1
}
