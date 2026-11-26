# scripts/gui/funcoes-03.sh — funções próprias do bloco 3 da F8d (Xfce, LightDM, tipos de letra).
# Carregado por scripts/f08d-gui.sh. As funções correm sob corre_passo (sem errexit):
# cada comando termina em "|| return 1". Downloads no host para $LFS/sources, verificados por SHA-256.

# --- tipos de letra (x/TTF-and-OTF-fonts): versões fixadas; SHA-256 calculadas com sha256sum
DEJAVU_VER=2.37
DEJAVU_TB=dejavu-fonts-ttf-$DEJAVU_VER.tar.bz2
DEJAVU_URL=https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/$DEJAVU_TB
DEJAVU_SHA256=fa9ca4d13871dd122f61258a80d01751d603b4d3ee14095d65453b4e846e17d7
LIBERATION_VER=2.1.5
LIBERATION_TB=liberation-fonts-ttf-$LIBERATION_VER.tar.gz
# ligação oficial publicada na página da release 2.1.5 do projeto (anexo do GitHub)
LIBERATION_URL=https://github.com/liberationfonts/liberation-fonts/files/7261482/$LIBERATION_TB
LIBERATION_SHA256=7191c669bf38899f73a2094ed00f7b800553364f90e2637010a69c0e268f25d0

# baixar <url> <ficheiro em $LFS/sources> <sha256> — cópia da função de scripts/f08b-ia.sh,
# definida só se o script da etapa ainda não a tiver
if ! declare -F baixar > /dev/null; then
baixar() {
  local url=$1 f=$LFS/sources/$2 sha=$3
  if [ -f "$f" ] && echo "$sha  $f" | sha256sum -c --status; then
    echo "já descarregado e verificado: $f"; return 0
  fi
  rm -f "$f"
  wget -nv -c -O "$f.part" "$url" || return 1
  echo "$sha  $f.part" | sha256sum -c || { echo "SHA-256 errado em $f.part (apagado)"; rm -f "$f.part"; return 1; }
  mv -v "$f.part" "$f"
}
fi

# DejaVu (fallback universal, inclui DejaVu Sans Mono) + Liberation (métricas compatíveis com
# Arial/Times New Roman/Courier New). Instaladas em /usr/share/fonts/<família> + fc-cache.
fontes_ttf() {
  baixar $DEJAVU_URL $DEJAVU_TB $DEJAVU_SHA256 || return 1
  baixar $LIBERATION_URL $LIBERATION_TB $LIBERATION_SHA256 || return 1
  in_chroot "set -e
    cd /sources
    rm -rf dejavu-fonts-ttf-$DEJAVU_VER liberation-fonts-ttf-$LIBERATION_VER
    tar -xf $DEJAVU_TB
    tar -xf $LIBERATION_TB
    install -v -d -m755 /usr/share/fonts/dejavu /usr/share/fonts/liberation
    install -v -m644 dejavu-fonts-ttf-$DEJAVU_VER/ttf/*.ttf /usr/share/fonts/dejavu
    install -v -m644 liberation-fonts-ttf-$LIBERATION_VER/*.ttf /usr/share/fonts/liberation
    install -v -D -m644 dejavu-fonts-ttf-$DEJAVU_VER/LICENSE /usr/share/doc/dejavu-fonts-$DEJAVU_VER/LICENSE
    install -v -D -m644 liberation-fonts-ttf-$LIBERATION_VER/LICENSE /usr/share/doc/liberation-fonts-$LIBERATION_VER/LICENSE
    rm -rf dejavu-fonts-ttf-$DEJAVU_VER liberation-fonts-ttf-$LIBERATION_VER
    fc-cache -f
    fc-list : family | sort -u
    fc-match sans-serif; fc-match monospace
    fc-list | grep -q /usr/share/fonts/dejavu/DejaVuSansMono.ttf
    fc-list | grep -q /usr/share/fonts/liberation/LiberationSans-Regular.ttf" || return 1
}

# Runlevel 5 por omissão: o init lança o LightDM pela linha "dm:5:respawn:/etc/rc.d/init.d/xdm"
# (acrescentada pelo make install-lightdm do passo lightdm-bootscript); o LightDM usa o vt7.
# Os agetty de tty1-6 e ttyS0 estão no inittab para os runlevels 2345, por isso continuam ativos.
lightdm_runlevel5() {
  local f=$LFS/etc/inittab rc=$LFS/etc/rc.d l n t
  grep -q '^dm:5:respawn:/etc/rc.d/init.d/xdm' $f || { echo "falta dm:5 em /etc/inittab (passo lightdm-bootscript)"; return 1; }
  # o make install-lightdm só tira o "#" e deixa um espaço inicial: normaliza a linha
  sed -i 's|^[[:space:]]*DISPLAY_MANAGER=/usr/bin/lightdm|DISPLAY_MANAGER=/usr/bin/lightdm|' $LFS/etc/sysconfig/xdm || return 1
  grep -q '^DISPLAY_MANAGER=/usr/bin/lightdm' $LFS/etc/sysconfig/xdm || { echo "DISPLAY_MANAGER não é o lightdm"; return 1; }
  [ -x $LFS/etc/rc.d/init.d/xdm ] || return 1
  # serviços do runlevel 3 também no 5 (hoje são iguais; garante-o para os que outros passos acrescentem)
  for l in $rc/rc3.d/S*; do
    [ -e "$l" ] || continue
    n=${l##*/}
    [ -e $rc/rc5.d/$n ] || ln -sv "$(readlink "$l")" $rc/rc5.d/$n || return 1
  done
  sed -i 's/^id:[0-9]:initdefault:/id:5:initdefault:/' $f || return 1
  grep -qx 'id:5:initdefault:' $f || { echo "id:5:initdefault: não ficou em /etc/inittab"; return 1; }
  # os logins de texto (consola e série, usados pelos testes) têm de continuar no runlevel 5
  for t in 1 2 3 4 5 6 S0; do
    grep -Eq "^$t:[0-9]*5[0-9]*:respawn:/sbin/agetty" $f || { echo "agetty '$t' não ativo no runlevel 5"; return 1; }
  done
  grep -E '^(id|dm|[1-6]|S0):' $f
}
