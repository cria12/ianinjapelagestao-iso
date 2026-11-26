#!/bin/bash
# F8 — Pacotes BLFS 12.4 (System V), dentro do chroot: certificados, PAM/Shadow/Sudo, rede (dhcpcd,
# Wget, cURL, OpenSSH), editores e utilitários; ficheiros de arranque do Bash e utilizador ninja.
# Cada pacote: URL/MD5 lidos da página do livro (scripts/blfs-fetch.py), download no host para
# $LFS/sources, comandos transcritos da página (scripts/gen/blfs/...) executados por run-blfs.sh.
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F8)" = ok ] && exit 0
montar_lfs
montar_kernfs > /dev/null
etapa_inicio F8

S=$P/scripts
BLFS=$P/book/blfs
FETCH="python3 $S/blfs-fetch.py"

# BLFS Boot Scripts (Cap. 2): a página não indica MD5 — soma registada em 2026-11-04
BS_MD5=ec1bae931da7e994d2fbb752913215a0
BS_TB=$($FETCH tarball $BLFS introduction/bootscripts)
BS_DIR=${BS_TB%.tar.xz}
# os blocos substituídos (scripts/replace/blfs-*) usam este diretório
[ "$BS_DIR" = blfs-bootscripts-20250225 ] || { echo "versão inesperada do blfs-bootscripts: $BS_DIR"; exit 1; }

# Páginas transcritas (ordem de instalação; dependências antes de quem as usa)
PAGINAS=(
  general/libtasn1 postlfs/p11-kit postlfs/make-ca
  postlfs/linux-pam postlfs/shadow postlfs/sudo
  basicnet/dhcpcd
  general/libunistring general/libidn2 basicnet/libpsl basicnet/wget basicnet/curl
  postlfs/openssh
  postlfs/nano general/cpio
  postlfs/dosfstools general/popt postlfs/efivar postlfs/efibootmgr
  general/hwdata general/pciutils general/libusb general/usbutils general/which general/tree
  general/git basicnet/lynx
  postlfs/profile postlfs/skel
)
python3 $S/gen-scripts.py blfs $BLFS "${PAGINAS[@]}" > /dev/null
mkdir -p $LFS/sources/ianinja/gen
rm -rf $LFS/sources/ianinja/gen/blfs
cp -r $S/gen/blfs $LFS/sources/ianinja/gen/
cp $S/run-blfs.sh $LFS/sources/ianinja/
chmod -R a+rX $LFS/sources/ianinja

# --- funções (correm dentro de corre_passo: errexit não se aplica, por isso || return 1)

# pacote <cap/pagina> [opções do blfs-fetch] — download+MD5 no host, build no chroot
pacote() {
  local page=$1 tb; shift
  $FETCH fetch $BLFS $LFS/sources "$page" "$@" || return 1
  tb=$($FETCH tarball $BLFS "$page") || return 1
  in_chroot "bash /sources/ianinja/run-blfs.sh $page $tb"
}

# pagina_config <cap/pagina> — páginas só de configuração (sem tarball)
pagina_config() {
  in_chroot "bash /sources/ianinja/run-blfs.sh $1 -"
}

# O /etc/resolv.conf do chroot é um marcador (gerido pelo dhcpcd no arranque); para downloads
# feitos DENTRO do chroot (make-ca -g) copia-se temporariamente o do host e repõe-se no fim.
RESOLV_BAK=$LFS/etc/resolv.conf.f8-orig
repor_resolv() {
  if [ -e "$RESOLV_BAK" ] || [ -L "$RESOLV_BAK" ]; then
    rm -f "$LFS/etc/resolv.conf"
    mv -f "$RESOLV_BAK" "$LFS/etc/resolv.conf"
  fi
}
com_rede() {
  local rc=0
  repor_resolv
  cp -a "$LFS/etc/resolv.conf" "$RESOLV_BAK" || return 1
  rm -f "$LFS/etc/resolv.conf"
  cp -L /etc/resolv.conf "$LFS/etc/resolv.conf" || { repor_resolv; return 1; }
  "$@" || rc=$?
  repor_resolv
  return $rc
}
repor_resolv            # caso uma execução anterior tenha sido interrompida
trap repor_resolv EXIT

# BLFS Boot Scripts: extraído em /sources e mantido durante a F8 (recomendação do livro);
# os "make install-<serviço>" estão nas páginas de cada pacote.
bootscripts() {
  $FETCH fetch $BLFS $LFS/sources introduction/bootscripts --md5 $BS_MD5 || return 1
  in_chroot "set -e; cd /sources; rm -rf $BS_DIR; tar -xf $BS_TB; test -f $BS_DIR/Makefile"
}

make_ca() { com_rede pacote postlfs/make-ca; }

# OpenSSH: o "make install" gera chaves de host — seriam iguais em todas as cópias da ISO.
# Apagam-se; o bootscript sshd do BLFS passa a correr "ssh-keygen -A" (só cria as que faltam)
# antes de arrancar o daemon. O sshd não arranca sozinho: contas live com senha
# fixa da construção numa ISO pública — ativa-se com /etc/rc.d/init.d/sshd start.
sshd_chaves() {
  rm -fv $LFS/etc/ssh/ssh_host_* || return 1
  local init=$LFS/etc/rc.d/init.d/sshd r
  if ! grep -q 'ssh-keygen -A' $init; then
    sed -i '/log_info_msg "Starting SSH Server..."/a\        /usr/bin/ssh-keygen -A > /dev/null 2>\&1 # ianinjapelagestao: chaves de host geradas no arranque do serviço' $init || return 1
  fi
  grep -n 'ssh-keygen -A' $init || return 1
  for r in 2 3 4 5; do
    rm -fv $LFS/etc/rc.d/rc$r.d/S30sshd || return 1
  done
}

# sudo para o utilizador ninja (sem senha: os testes automáticos usam "sudo -n")
sudoers_ninja() {
  install -v -d -m750 $LFS/etc/sudoers.d || return 1
  printf 'ninja ALL=(ALL:ALL) NOPASSWD: ALL\n' > $LFS/etc/sudoers.d/ninja || return 1
  chmod -v 0440 $LFS/etc/sudoers.d/ninja || return 1
  in_chroot "visudo -c -f /etc/sudoers.d/ninja"
}

limpeza() {
  in_chroot "rm -rf /sources/$BS_DIR"
}

# Verificação final: programas, certificados, serviços, utilizador e sudo
verificacao() {
  in_chroot 'set -e
falha() { echo "FALTA: $*"; exit 1; }
for c in make-ca trust dhcpcd wget curl ssh sshd ssh-keygen sudo visudo nano cpio mkfs.fat fsck.fat \
         efibootmgr efivar lspci lsusb which tree git lynx; do
  p=$(command -v $c) || falha "programa $c"
  printf "%-12s %s\n" "$c" "$p"
done
test -s /etc/pki/tls/certs/ca-bundle.crt || falha "/etc/pki/tls/certs/ca-bundle.crt"
echo "ca-bundle.crt: $(grep -c "BEGIN CERTIFICATE" /etc/pki/tls/certs/ca-bundle.crt) certificados"
for f in /etc/pam.d/{login,su,sudo,sshd,system-auth,other} /etc/rc.d/init.d/sshd /lib/services/dhcpcd \
         /etc/rc.d/rc0.d/K30sshd /etc/skel/.bashrc /etc/bashrc /etc/profile.d/i18n.sh \
         /etc/sudoers.d/ninja /home/ninja/.bashrc; do
  test -e $f || falha "$f"
  echo "ok $f"
done
if ls /etc/ssh/ssh_host_* 2>/dev/null; then falha "(não devia haver) chaves de host SSH na imagem"; fi
grep -q "ssh-keygen -A" /etc/rc.d/init.d/sshd || falha "ssh-keygen -A no bootscript sshd"
if ls /etc/rc.d/rc3.d/S*sshd 2>/dev/null; then falha "(não devia haver) arranque automático do sshd"; fi
cat /etc/sysconfig/ifconfig.eth0
id ninja
sudo -u ninja sudo -n true || falha "sudo -u ninja sudo -n true"
echo "sudo -u ninja sudo -n true: ok"'
}

PASSOS=(
  "bootscripts|bootscripts"
  "libtasn1|pacote general/libtasn1"
  "p11-kit|pacote postlfs/p11-kit"
  "make-ca|make_ca"
  "linux-pam|pacote postlfs/linux-pam --extra -docs.tar.xz"
  "shadow|pacote postlfs/shadow"
  "sudo|pacote postlfs/sudo"
  "dhcpcd|pacote basicnet/dhcpcd"
  "libunistring|pacote general/libunistring"
  "libidn2|pacote general/libidn2"
  "libpsl|pacote basicnet/libpsl"
  "wget|pacote basicnet/wget"
  "curl|pacote basicnet/curl"
  "openssh|pacote postlfs/openssh"
  "sshd-chaves|sshd_chaves"
  "nano|pacote postlfs/nano"
  "cpio|pacote general/cpio"
  "dosfstools|pacote postlfs/dosfstools"
  "popt|pacote general/popt"
  "efivar|pacote postlfs/efivar"
  "efibootmgr|pacote postlfs/efibootmgr"
  "hwdata|pacote general/hwdata"
  "pciutils|pacote general/pciutils"
  "libusb|pacote general/libusb"
  "usbutils|pacote general/usbutils"
  "which|pacote general/which"
  "tree|pacote general/tree"
  "git|pacote general/git"
  "lynx|pacote basicnet/lynx"
  "bash-profile|pagina_config postlfs/profile"
  "skel-ninja|pagina_config postlfs/skel"
  "sudoers-ninja|sudoers_ninja"
  "limpeza|limpeza"
  "verificacao|verificacao"
)
TOTAL=${#PASSOS[@]}
n=0
for linha in "${PASSOS[@]}"; do
  n=$((n+1))
  nome=${linha%%|*}
  read -r -a cmd <<< "${linha#*|}"
  corre_passo "f8-$nome" "$P/logs/f8-$nome.log" "${cmd[@]}" \
    || { etapa_fim F8 falhou "falhou em $nome ($n/$TOTAL) — ver logs/f8-$nome.log"; exit 1; }
  etapa_nota F8 "$n/$TOTAL — último: $nome"
done

# --- Decisões (desvios ao livro)
decisao "BLFS: compilação como root dentro do chroot" \
"Os blocos 'userinput' do BLFS (configure/make), que o livro prevê para um utilizador sem privilégios, são executados como root dentro do chroot, tal como no Cap. 8 do LFS — o sistema ainda não tem utilizadores nem arrancou. Cada página é transcrita automaticamente (scripts/gen-scripts.py -> scripts/gen/blfs/) e executada por scripts/run-blfs.sh (extrair, cd, comandos, apagar). URLs e somas MD5 vêm da própria página (scripts/blfs-fetch.py), com a errata ftp.gnu.org/gnu -> ftpmirror.gnu.org aplicada. Test suites que só aparecem no texto (fora de blocos) não são corridas, exceto o 'ninja test' do Linux-PAM (falhas toleradas, ver logs/f8-linux-pam.log)."
decisao "BLFS: blfs-bootscripts sem MD5 no livro" \
"A página 'BLFS Boot Scripts' não indica soma MD5 para blfs-bootscripts-20250225.tar.xz. Foi fixada a soma obtida em 2026-11-04 (ec1bae931da7e994d2fbb752913215a0); um tarball diferente faz a F8 falhar. O diretório extraído é mantido em /sources durante a F8 (recomendação do livro) e apagado no fim. Os blocos 'make install-service-dhcpcd' e 'make install-sshd' foram substituídos por versões que entram nesse diretório (scripts/replace/blfs-basicnet-dhcpcd.5.sh e blfs-postlfs-openssh.8.sh)."
decisao "BLFS: certificados (make-ca) e DNS no chroot" \
"O 'make-ca -g' descarrega o certdata.txt da Mozilla dentro do chroot; como o /etc/resolv.conf do LFS é só um marcador (o dhcpcd gere-o no arranque), o do host é copiado temporariamente para \$LFS/etc/resolv.conf e o original é reposto logo a seguir (também em caso de erro). O bloco do cron semanal (/etc/cron.weekly/update-pki.sh) foi omitido: o sistema não tem cron; numa ISO live os certificados ficam com a data de construção e podem ser atualizados à mão com 'make-ca -g'."
decisao "BLFS: dependências recomendadas instaladas" \
"Além das dependências obrigatórias (p11-kit/libtasn1 para o make-ca, Linux-PAM para o Shadow, libusb para o usbutils, efivar+popt para o efibootmgr), foram instaladas estas recomendadas, por serem necessárias ao funcionamento: libunistring, libidn2 e libpsl (o configure do cURL 8.15 exige libpsl e o livro desaconselha desativá-lo; Wget usa-o também) e hwdata (pci.ids/usb.ids, sem os quais lspci/lsusb só mostram números). Foi também instalada a documentação pré-gerada do Linux-PAM (download adicional com MD5 na página). Dependências opcionais (Doxygen, texlive, asciidoc, GnuTLS, nghttp2, etc.) não foram instaladas e os blocos que delas dependem foram omitidos (ver scripts/book-overrides.txt)."
decisao "BLFS: configuração do dhcpcd" \
"O dhcpcd foi compilado sem privilege separation (--disable-privsep), que é a opção por omissão do livro; os blocos do utilizador dhcpcd e da variante privsep foram omitidos. O /etc/sysconfig/ifconfig.eth0 escrito na F6 foi reescrito segundo o modelo do livro, sem os marcadores <insert ...>: ONBOOT=yes, IFACE=eth0, SERVICE=dhcpcd, DHCP_START=\"-b -q -h \$HOSTNAME\", DHCP_STOP=\"-k\" (o -h envia o nome ianinjapelagestao ao servidor DHCP). Os exemplos de IP estático e de resolv.conf.head (OpenDNS) não foram aplicados."
decisao "BLFS: OpenSSH — chaves de host e arranque manual" \
"O bootscript sshd do BLFS não gera chaves de host, mas o 'make install' do OpenSSH gera-as (ssh-keygen -A) — ficariam iguais em todas as cópias da ISO, permitindo ataques man-in-the-middle entre máquinas que arrancam a mesma imagem. As chaves geradas na construção são apagadas e ao bloco 'start' de /etc/rc.d/init.d/sshd foi acrescentada uma linha '/usr/bin/ssh-keygen -A' (cria só as chaves em falta, logo antes de lançar o daemon). Os links S30sshd dos níveis 2-5 criados por 'make install-sshd' foram removidos (mantêm-se os K30sshd): a ISO é pública e tem contas com senha fixa da construção (ninja com sudo sem senha), por isso o sshd não arranca sozinho — ativa-se com '/etc/rc.d/init.d/sshd start' (isto também evita gerar chaves RSA a cada arranque, lento em QEMU sem KVM). Aplicou-se 'PermitRootLogin no' e 'UsePAM yes' (recomendações do livro); a autenticação por senha mantém-se ativa (o bloco que a desativa foi omitido, pois a ISO não traz chaves autorizadas) — entra-se como ninja e usa-se sudo."
decisao "BLFS: utilizador ninja e sudo sem senha" \
"O utilizador ninja (senha de scripts/senhas.local, shell /bin/bash) é criado com 'useradd -m' só depois de /etc/skel estar povoado, de forma idempotente. Tem sudo através de /etc/sudoers.d/ninja (modo 0440, validado com visudo -c -f) com a regra 'ninja ALL=(ALL:ALL) NOPASSWD: ALL' em vez de 'ALL' com senha: os testes automáticos (F11) executam 'sudo -u ninja sudo -n true', que exige NOPASSWD. O ficheiro /etc/sudoers.d/00-sudo do livro (secure_path e grupo wheel com senha) também foi criado. A senha do root definida no Cap. 8 mantém-se; o Shadow reinstalado com PAM não altera /etc/shadow."
decisao "BLFS: ficheiros de arranque do Bash, /etc/skel e prompt" \
"Aplicada a página 'The Bash Shell Startup Files' (substitui o /etc/profile do Cap. 9.7 pelo do BLFS + /etc/profile.d). Desvios: em /etc/profile.d/i18n.sh o marcador <ll>_<CC>.<charmap> passou a pt_PT.UTF-8 (C.UTF-8 na consola linux, como no livro); em /etc/bashrc o prompt passou a '\\u@\\h [ \\w ]' (ex.: ninja@ianinjapelagestao, a vermelho para root e verde para utilizadores). Os ficheiros pessoais (~/.bash_profile, ~/.profile, ~/.bashrc, ~/.bash_logout) foram criados para o root e copiados para /etc/skel (diretório 0755 do root, ficheiros 0600, conforme 'Configuring for Adding Users')."
decisao "BLFS: pacotes opcionais Git e Lynx" \
"Git 2.50.1 e Lynx 2.9.2 foram incluídos porque não trazem dependências novas (Git usa cURL/OpenSSL/Expat/Python já presentes; Lynx usa OpenSSL/ncurses/zlib/bzip2). Do Git omitiu-se a documentação (gerá-la exige asciidoc/xmlto; os tarballs pré-gerados git-manpages/git-htmldocs não têm MD5 no livro e ocupariam espaço na ISO). No Lynx aplicaram-se as três alterações de lynx.cfg do livro (LOCALE_CHARSET, DEFAULT_EDITOR:vi, PERSISTENT_COOKIES)."

aviso=$( (grep -l 'AVISO-TESTE' $P/logs/f8-*.log 2>/dev/null || true) | xargs -r -n1 basename | sed 's/^f8-//;s/\.log$//' | tr '\n' ' ')
if [ -n "$aviso" ]; then
  etapa_fim F8 aviso "$TOTAL passos BLFS; testes com falhas (tolerados, ver logs): $aviso"
else
  etapa_fim F8 ok "$TOTAL passos BLFS: certificados, PAM/Shadow/Sudo, dhcpcd, Wget/cURL, OpenSSH, nano, utilitários, Git, Lynx, utilizador ninja"
fi
