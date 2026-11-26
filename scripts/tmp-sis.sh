set -euo pipefail
F=/tmp/fakelfs; rm -rf $F
mkdir -p $F/etc/rc.d/{init.d,rcS.d,rc0.d,rc6.d} $F/etc/sysconfig $F/etc/pam.d $F/usr/sbin $F/var/lib $F/mnt
for s in login sshd su sudo; do debugfs -c -R "cat /etc/pam.d/$s" /dev/loop0 2>/dev/null > $F/etc/pam.d/$s; done
P=/root/ianinjapelagestao; LFS=$F
sed -n '/^instalar_sistema() {/,/^}/p' $P/scripts/f09-live.sh > /tmp/fn.sh; source /tmp/fn.sh
P=$P LFS=$LFS bash -euo pipefail -c "$(declare -f instalar_sistema); instalar_sistema" > /tmp/i.log 2>&1 && echo "execucao OK ($(wc -l < /tmp/i.log) linhas)"
# falha forçada: sem rc0.d -> deve falhar
rm -rf $F/etc/rc.d/rc0.d
P=$P LFS=$LFS bash -euo pipefail -c "$(declare -f instalar_sistema); instalar_sistema" > /tmp/i.log 2>&1 && echo "NAO DETETOU FALHA" || echo "falha detetada: $(tail -1 /tmp/i.log)"
rm -rf $F /tmp/fn.sh /tmp/i.log
