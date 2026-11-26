# Ambiente dos comandos BLFS no chroot (lido por run-blfs.sh antes de cada página).
# O chroot corre com "env -i" e não lê /etc/profile; aqui fica só o que as páginas pressupõem.

# Compila-se como root (ver docs/DECISOES.md), por isso "as_root cmd" é só "cmd"
# (o livro define as_root em "Notes on Building Software" para quem compila sem privilégios).
as_root() { "$@"; }

# Funções do /etc/profile do BLFS usadas pelos ficheiros de /etc/profile.d
pathremove() {
  local IFS=':' NEWPATH DIR PATHVARIABLE=${2:-PATH}
  for DIR in ${!PATHVARIABLE}; do
    [ "$DIR" != "$1" ] && NEWPATH=${NEWPATH:+$NEWPATH:}$DIR
  done
  export $PATHVARIABLE="$NEWPATH"
}
pathprepend() { pathremove $1 $2; local PATHVARIABLE=${2:-PATH}; export $PATHVARIABLE="$1${!PATHVARIABLE:+:${!PATHVARIABLE}}"; }
pathappend()  { pathremove $1 $2; local PATHVARIABLE=${2:-PATH}; export $PATHVARIABLE="${!PATHVARIABLE:+${!PATHVARIABLE}:}$1"; }
export -f as_root pathremove pathprepend pathappend

# Variáveis criadas por páginas anteriores (Xorg: XORG_PREFIX/XORG_CONFIG; Rust: PATH /opt/rustc)
for f in /etc/profile.d/xorg.sh /etc/profile.d/rustc.sh; do
  [ -r "$f" ] && . "$f"
done
# rede do WSL instável: o cargo repete os downloads de crates
export CARGO_NET_RETRY=10 CARGO_HTTP_TIMEOUT=120
true
