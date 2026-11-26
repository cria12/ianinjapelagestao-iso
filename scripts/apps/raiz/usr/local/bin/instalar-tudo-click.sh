#!/bin/bash
# instalar-tudo-click.sh — instala de uma vez as aplicações recomendadas (VS Code, Google Chrome,
# Claude Code e Codex) com o comando instalar-aplicacoes, numa janela de terminal; no fim o Chrome
# fica como navegador predefinido (o instalar-aplicacoes trata disso).
#
# Arranca sozinho no 1.º início de sessão (/etc/xdg/autostart/instalar-tudo-default.desktop):
#   - se já estiver tudo instalado, ou se já perguntou nesta pasta pessoal, não faz nada;
#   - sem Internet não pergunta (volta a tentar no próximo início de sessão).
# Uso manual: instalar-tudo-click.sh --agora   (pergunta sempre, mesmo que já tenha perguntado)
set -u

[ "$(id -u)" = 0 ] && { echo "Corra como o utilizador normal (ex.: ninja), não como root." >&2; exit 1; }
type -P instalar-aplicacoes > /dev/null || { echo "ERRO: falta o comando instalar-aplicacoes." >&2; exit 1; }

AGORA=0
[ "${1:-}" = --agora ] && AGORA=1
MARCA=${XDG_CONFIG_HOME:-$HOME/.config}/ianinjapelagestao/instalar-tudo.perguntado

tudo_instalado() {
  type -P code > /dev/null && type -P google-chrome > /dev/null && type -P codex > /dev/null &&
    { type -P claude > /dev/null || [ -x "$HOME/.local/bin/claude" ]; }
}

if tudo_instalado && [ $AGORA = 0 ]; then
  exit 0
fi
[ -e "$MARCA" ] && [ $AGORA = 0 ] && exit 0

# A rede pode demorar a subir depois do início de sessão: espera até 60 s
net=0
for _ in $(seq 12); do
  curl -fsI --max-time 5 https://dl.google.com > /dev/null 2>&1 && { net=1; break; }
  [ $AGORA = 1 ] && break
  sleep 5
done
if [ $net = 0 ]; then
  [ $AGORA = 1 ] && echo "Sem ligação à Internet: ligue-se à rede e tente outra vez." >&2
  exit 0
fi

mkdir -p "${MARCA%/*}" && : > "$MARCA"
# O instalar-aplicacoes pede para aceitar a licença de cada aplicação e avisa se a sessão live
# não tiver persistência (sem ela, o que se instala perde-se ao desligar).
if [ -n "${DISPLAY:-}" ] && type -P xfce4-terminal > /dev/null; then
  exec xfce4-terminal --title "Instalar aplicações" --hide-menubar \
    -x instalar-aplicacoes tudo --janela
fi
exec instalar-aplicacoes tudo
