# Gerado de LFS 12.4 chapter07/chroot.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: a entrada no chroot é feita pelo orquestrador (scripts/chroot-run.sh) com o mesmo env -i do livro]
#   chroot "$LFS" /usr/bin/env -i   \
#       HOME=/root                  \
#       TERM="$TERM"                \
#       PS1='(lfs chroot) \u:\w\$ ' \
#       PATH=/usr/bin:/usr/sbin     \
#       MAKEFLAGS="-j$(nproc)"      \
#       TESTSUITEFLAGS="-j$(nproc)" \
#       /bin/bash --login

