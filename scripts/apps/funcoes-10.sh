# F8e — funções do bloco 10 (otimizações: sistema mais leve em disco, na ISO e na RAM).
# Lido por scripts/f08e-apps.sh. Correm sob corre_passo (sem errexit): cada comando termina com
# || return 1. Os ficheiros instalados estão em scripts/apps/otimizacoes/. Ver decisoes-10.txt.
# A parte que só diz respeito à imagem (exclusões do SquashFS, compressão) está na F9
# (scripts/f09-live.sh, função exclusoes_live) e o zswap.enabled=0 na F10 (grub.cfg).

OTIM_D=$P/scripts/apps/otimizacoes

# otim_strip — strip --strip-unneeded dos ELF x86-64 que ainda têm símbolos (BLFS compila com -g
# ou sem strip: ~2,2 GB -> ~1,4 GB). Corre otimizacoes/strip.sh no chroot (usa o strip do próprio
# alvo) e confirma a seguir que os programas principais continuam a arrancar.
otim_strip() {
  local p
  in_chroot "du -sm /usr /opt 2>/dev/null | sed 's/^/antes (MiB): /'"
  in_chroot "bash -s" < $OTIM_D/strip.sh || return 1
  in_chroot "du -sm /usr /opt 2>/dev/null | sed 's/^/depois (MiB): /'"
  # verificação: cada programa que existir tem de responder (Python/Node/GDB, compiladores,
  # Xorg, Flatpak, IA, OpenCV...); um ELF estragado pelo strip falharia aqui
  in_chroot "set -e
for c in 'bash --version' 'python3 --version' 'node --version' 'npm --version' 'gdb --version' \
         'gcc --version' 'clang --version' 'git --version' 'Xorg -version' 'flatpak --version' \
         'bwrap --version' 'valgrind --version' 'llama-cli --version' 'xfconf-query --version' 'lightdm --version' \
         'cmake --version' 'ffmpeg -version' 'curl --version' 'openssl version' 'sudo -V'; do
  set -- \$c
  command -v \$1 > /dev/null || { echo \"(não existe: \$1)\"; continue; }
  \$c > /dev/null 2>&1 < /dev/null || { echo \"ERRO depois do strip: \$c\"; exit 1; }
  echo \"ok: \$c\"
done
python3 -I -c 'import sqlite3, ssl, ctypes, numpy, cv2, gi, requests; print(\"python: imports OK\")'
# compilar e ligar um programa C (crt, libc, libgcc) e um C++ (libstdc++)
d=\$(mktemp -d); cd \$d
printf '#include <stdio.h>\nint main(void){puts(\"ola\");return 0;}\n' > a.c
printf '#include <iostream>\nint main(){std::cout<<\"ola\"<<std::endl;}\n' > b.cpp
gcc -O2 -o a a.c && ./a | grep -qx ola
g++ -O2 -o b b.cpp && ./b | grep -qx ola
cd /; rm -rf \$d
echo 'compilação C/C++: OK'
ldconfig -p | grep -q libc.so.6" || return 1
}

# otim_bluetooth — bluetoothd e blueman-applet só com adaptador Bluetooth:
#  - /etc/sysconfig/bluetooth (lido pelo bootscript do BLFS no início) ganha um bloco marcado
#    que faz o 'start' sair com SKIP quando não há /sys/class/bluetooth/hci*;
#  - regra do udev + ianinja-bluetooth-hotplug: adaptador ligado mais tarde arranca o serviço;
#  - o autostart do blueman-applet passa a chamar blueman-se-houver.
otim_bluetooth() {
  local f=$LFS/etc/sysconfig/bluetooth a=$LFS/etc/xdg/autostart/blueman.desktop
  [ -x $LFS/etc/rc.d/init.d/bluetooth ] || { echo "sem /etc/rc.d/init.d/bluetooth (bloco 3)"; return 1; }
  touch $f || return 1
  sed -i '/^# >>> ianinjapelagestao-otimizacoes/,/^# <<< ianinjapelagestao-otimizacoes/d' $f || return 1
  cat >> $f << "EOF" || return 1
# >>> ianinjapelagestao-otimizacoes (scripts/apps/funcoes-10.sh)
# Sem adaptador Bluetooth o bluetoothd não arranca (poupa memória e tempo de arranque).
# Um adaptador ligado depois é tratado pelo udev (/etc/udev/rules.d/90-ianinja-bluetooth.rules).
if [ "${1:-}" = start ] && ! ls -d /sys/class/bluetooth/hci* > /dev/null 2>&1; then
   log_info_msg "Bluetooth: nenhum adaptador encontrado"
   log_skip_msg
   exit 0
fi
# <<< ianinjapelagestao-otimizacoes
EOF
  install -v -m755 $OTIM_D/ianinja-bluetooth-hotplug $LFS/usr/sbin/ianinja-bluetooth-hotplug || return 1
  install -v -Dm644 $OTIM_D/90-ianinja-bluetooth.rules $LFS/etc/udev/rules.d/90-ianinja-bluetooth.rules || return 1
  install -v -m755 $OTIM_D/blueman-se-houver $LFS/usr/bin/blueman-se-houver || return 1
  [ -f $a ] || { echo "sem $a (bloco 3)"; return 1; }
  sed -i 's|^Exec=.*|Exec=/usr/bin/blueman-se-houver|' $a || return 1
  grep -qx 'Exec=/usr/bin/blueman-se-houver' $a || return 1
  # no chroot não há adaptador: o start tem de sair com 0 sem lançar o bluetoothd
  in_chroot "set -e
sh -n /etc/sysconfig/bluetooth; sh -n /usr/sbin/ianinja-bluetooth-hotplug; sh -n /usr/bin/blueman-se-houver
/etc/rc.d/init.d/bluetooth start
! pidof bluetoothd
/usr/bin/blueman-se-houver
udevadm verify /etc/udev/rules.d/90-ianinja-bluetooth.rules 2>/dev/null || true
desktop-file-validate /etc/xdg/autostart/blueman.desktop || true" || return 1
}

# otim_xfce — compositor do xfwm4 desligado sozinho em modo de recurso (desenho por software);
# limite de 50 MiB para o tumbler gerar miniaturas de imagens (PixbufThumbnailer: lê a imagem
# inteira para a RAM).
otim_xfce() {
  local t=$LFS/etc/xdg/tumbler/tumbler.rc
  install -v -m755 $OTIM_D/ianinja-compositor-auto $LFS/usr/bin/ianinja-compositor-auto || return 1
  install -v -Dm644 $OTIM_D/ianinja-compositor-auto.desktop $LFS/etc/xdg/autostart/ianinja-compositor-auto.desktop || return 1
  if [ -f $t ]; then
    sed -i '/^\[PixbufThumbnailer\]/,/^$/s/^MaxFileSize=.*/MaxFileSize=52428800/' $t || return 1
    sed -n '/^\[PixbufThumbnailer\]/,/^$/p' $t | grep -qx 'MaxFileSize=52428800' || return 1
  else
    echo "(sem $t: tumbler não instalado, nada a limitar)"
  fi
  in_chroot "set -e; sh -n /usr/bin/ianinja-compositor-auto
desktop-file-validate /etc/xdg/autostart/ianinja-compositor-auto.desktop" || return 1
}

# otim_verificar — resumo do que fica a arrancar (rc, autostart) e do espaço usado, para o log
otim_verificar() {
  in_chroot "echo '== rc5.d:'; ls /etc/rc.d/rc5.d | tr '\n' ' '; echo
echo '== autostart:'; grep -H '^Exec=' /etc/xdg/autostart/*.desktop
echo '== maiores diretórios (MiB):'; du -xsm /usr/* /opt 2>/dev/null | sort -n | tail -8" || return 1
}
