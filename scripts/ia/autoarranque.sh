# /usr/share/ia/autoarranque.sh — lança o ia-chat ao entrar numa consola virtual local.
# Carregado ("source") no fim do ~/.bash_profile do utilizador ninja.
# Só atua se: não for root; stdin for um terminal; a consola for tty1..tty6 (nunca a série
# ttyS0 nem sessões ssh); IA_SEM_CHAT não estiver definida; houver modelo predefinido.
# Para desativar: export IA_SEM_CHAT=1 (ou apagar a linha no ~/.bash_profile).
_ia_auto() {
  [ "$(id -u)" -ne 0 ] || return 0
  [ -z "${IA_SEM_CHAT+x}" ] || return 0
  [ -z "${_IA_CHAT_AUTO:-}" ] || return 0          # só uma vez (não repetir em "bash -l")
  [ -t 0 ] || return 0
  [ -z "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ] || return 0
  case "$(tty 2> /dev/null)" in
    /dev/tty[1-6]) ;;
    *) return 0 ;;
  esac
  [ -e /usr/share/ia/modelos/predefinido.gguf ] || return 0
  type -P ia-chat > /dev/null || return 0
  export _IA_CHAT_AUTO=1
  echo "A iniciar o chat de IA… (Ctrl+C ou /sair para voltar à shell)"
  ia-chat
}
_ia_auto
unset -f _ia_auto
