# /etc/skel: só o root escreve; ficheiros ilegíveis para grupo/outros (texto da página)
install -v -d -m755 -o root -g root /etc/skel
for f in .bash_profile .profile .bashrc .bash_logout; do
  install -v -m600 -o root -g root /root/$f /etc/skel/$f
done
# utilizador da distro (criado depois de /etc/skel estar povoado); idempotente
if ! getent passwd ninja > /dev/null; then
  useradd -m -s /bin/bash -c 'ninja' ninja
fi
for f in .bash_profile .profile .bashrc .bash_logout; do
  [ -e /home/ninja/$f ] || install -v -m600 -o ninja -g "$(id -gn ninja)" /etc/skel/$f /home/ninja/$f
done
# senha definida em scripts/senhas.local (fora do Git), copiada por preparar_runner
. /sources/ianinja/senhas.local
printf 'ninja:%s\n' "$SENHA_NINJA" | chpasswd
