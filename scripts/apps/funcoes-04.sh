# F8e — funções do bloco 4 (ambiente de programação: Python, Node.js/npm, GDB, Valgrind e o
# comando instalar-ferramentas). Lido por scripts/f08e-apps.sh. Correm sob corre_passo (sem
# errexit): cada comando termina com || return 1. Ver scripts/apps/decisoes-04.txt.

# prog_ambiente — /etc/profile.d/programacao.sh (npm -g em ~/.npm-global sem sudo; ~/.local/bin,
# ~/.cargo/bin, ~/go/bin no PATH; JAVA_HOME), /usr/bin/instalar-ferramentas (Rust, Go e Java a
# pedido, dos sites oficiais) e o atalho no menu Desenvolvimento.
prog_ambiente() {
  local d=$P/scripts/apps/programacao
  install -v -m644 $d/programacao.sh $LFS/etc/profile.d/programacao.sh || return 1
  install -v -m755 $d/instalar-ferramentas $LFS/usr/bin/instalar-ferramentas || return 1
  install -v -D -m644 $d/instalar-ferramentas.desktop \
    $LFS/usr/share/applications/instalar-ferramentas.desktop || return 1
  install -v -d -m755 $LFS/var/lib/instalar-ferramentas $LFS/usr/local/bin || return 1
  in_chroot "set -e
    bash -n /etc/profile.d/programacao.sh
    bash -n /usr/bin/instalar-ferramentas
    desktop-file-validate /usr/share/applications/instalar-ferramentas.desktop
    update-desktop-database -q /usr/share/applications
    instalar-ferramentas -h > /dev/null
    for c in curl tar gzip sha256sum python3 flock xfce4-terminal sudo; do
      type -P \$c > /dev/null || { echo \"falta \$c\"; exit 1; }
    done" || return 1
}

# prog_verificar — Python (sqlite3, ssl, venv/pip, requests, pytest), Node.js/npm, GDB e Valgrind
# no chroot; e, como o UID 1000 com uma pasta pessoal temporária, npm install -g de um pacote
# local (sem rede) para ~/.npm-global e um venv com pip. Nada fica em /home/ninja.
prog_verificar() {
  install -v -m755 $P/scripts/apps/programacao/verificar-programacao.sh \
    $LFS/tmp/verificar-programacao.sh || return 1
  in_chroot "bash /tmp/verificar-programacao.sh"; local rc=$?
  rm -f $LFS/tmp/verificar-programacao.sh
  return $rc
}
