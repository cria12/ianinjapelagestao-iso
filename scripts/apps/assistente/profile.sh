# /etc/profile.d/ianinja-assistente.sh — no modo de texto (consolas tty1-tty6), enquanto o sistema
# não tiver uma conta criada pelo Assistente de configuração, lembra como criá-la.
if [ ! -e /var/lib/ianinjapelagestao/configurado ] && [ -x /usr/sbin/ianinja-assistente ]; then
  case "$(tty 2>/dev/null)" in
    /dev/tty[1-6]) echo "Dica: para criar a sua conta (utilizador e senha): sudo ianinja-assistente --texto" ;;
  esac
fi
