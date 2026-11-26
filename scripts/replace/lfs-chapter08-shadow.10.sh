# senha definida em scripts/senhas.local (fora do Git), copiada por preparar_runner
. /sources/ianinja/senhas.local
printf 'root:%s\n' "$SENHA_ROOT" | chpasswd