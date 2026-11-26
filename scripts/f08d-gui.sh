#!/bin/bash
# F8d — Interface gráfica: Xorg, Mesa, GTK3, Xfce 4.20 e LightDM (BLFS 12.4, System V), com um
# aspeto ao estilo do macOS (tema WhiteSur, barra superior + dock, fonte Inter).
# Páginas do livro pela ordem de scripts/gui/ordem.txt (dependências Required + Recommended,
# resolvidas por scripts/blfs-deps.py a partir do HTML do livro); overrides por bloco em
# scripts/book-overrides.d/gui-*.txt. Os passos vêm de scripts/gui/passos-NN.txt (formato id|comando)
# e as funções próprias de scripts/gui/funcoes-NN.sh. Downloads no host (MD5 do livro ou SHA-256
# fixado); compilação no chroot como root, como na F8.
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
estado_init
[ "$(etapa_estado F8d)" = ok ] && exit 0
montar_lfs
montar_kernfs > /dev/null
etapa_inicio F8d

S=$P/scripts
G=$S/gui
BLFS=$P/book/blfs
FETCH="python3 $S/blfs-fetch.py"
BS_TB=blfs-bootscripts-20250225.tar.xz   # já descarregado e verificado na F8
BS_DIR=${BS_TB%.tar.xz}

# Passos e páginas
mapfile -t PASSOS < <(echo "copia-seguranca|copia_seguranca"; cat $G/passos-0[1-9].txt | sed 's/[[:space:]]*#.*$//' | grep -v '^[[:space:]]*$')
mapfile -t PAGINAS < <(printf '%s\n' "${PASSOS[@]}" | awk -F'|' '{split($2,a," "); if (a[1] ~ /^(pacote|pacote_rede|pagina_config|pagina_rede)$/) print a[2]}' | sort -u)
python3 $S/gen-scripts.py blfs $BLFS "${PAGINAS[@]}" > /dev/null
mkdir -p $LFS/sources/ianinja/gen
rm -rf $LFS/sources/ianinja/gen/blfs
cp -r $S/gen/blfs $LFS/sources/ianinja/gen/
cp $S/run-blfs.sh $S/blfs-env.sh $LFS/sources/ianinja/
chmod -R a+rX $LFS/sources/ianinja

# --- funções (correm dentro de corre_passo: errexit não se aplica, por isso || return 1)

# pacote <cap/pagina[@secao]> [opções do blfs-fetch] — download+MD5 no host, build no chroot
pacote() {
  local page=$1 tb; shift
  $FETCH fetch $BLFS $LFS/sources "$page" "$@" || return 1
  tb=$($FETCH tarball $BLFS "$page") || return 1
  in_chroot "bash /sources/ianinja/run-blfs.sh $page $tb"
}

# pagina_config <cap/pagina> — páginas sem tarball (só configuração, ou listas descarregadas no chroot)
pagina_config() {
  in_chroot "bash /sources/ianinja/run-blfs.sh $1 -"
}

# O /etc/resolv.conf do chroot é um marcador (gerido pelo dhcpcd no arranque); para downloads
# feitos DENTRO do chroot copia-se temporariamente o do host e repõe-se no fim (como na F8).
RESOLV_BAK=$LFS/etc/resolv.conf.f8d-orig
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

pacote_rede()  { com_rede pacote "$@"; }
pagina_rede()  { com_rede pagina_config "$@"; }

# baixar <url> <ficheiro em $LFS/sources> <sha256> — reutiliza se já existir com a soma certa
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

# bootscripts <alvo...> — "make install-<alvo>" no diretório do blfs-bootscripts (extraído e apagado)
bootscripts() {
  in_chroot "set -e; cd /sources; rm -rf $BS_DIR; tar -xf $BS_TB; cd $BS_DIR; for a in $*; do make install-\$a; done; cd /sources; rm -rf $BS_DIR"
}

for f in $G/funcoes-0[1-9].sh; do
  [ -r "$f" ] && source "$f"
done

# Cópia de segurança do sistema antes da interface gráfica (PAM, inittab e /usr mudam muito):
# lfs-antes-f8d.img, esparsa, com o sistema de ficheiros congelado durante a cópia (consistente).
# Repor: desmontar /mnt/lfs e copiar lfs-antes-f8d.img por cima de lfs.img.
copia_seguranca() {
  local b=$P/lfs-antes-f8d.img
  [ -s "$b" ] && { echo "já existe: $b"; return 0; }
  sync || return 1
  fsfreeze -f $LFS || return 1
  cp --sparse=always $P/lfs.img $b.part; local rc=$?
  fsfreeze -u $LFS
  [ $rc = 0 ] || { rm -f $b.part; return 1; }
  mv -v $b.part $b && du -sh $b
}

# As etapas seguintes (live, ISO, testes, entrega) têm de ser refeitas com a interface gráfica
refazer_seguintes() {
  local id
  for id in F9 F10 F11 F12; do
    _jq_inplace --arg id "$id" '.etapas[$id] |= (.estado="pendente" | .inicio="" | .fim="" | .inicio_ts=0 | .fim_ts=0 | .notas="refazer após F8d")'
  done
  _jq_inplace '.passos_concluidos |= map(select(test("^f(9|10|11|12)-") | not))'
}

TOTAL=${#PASSOS[@]}
n=0
for linha in "${PASSOS[@]}"; do
  n=$((n+1))
  nome=${linha%%|*}
  read -r -a cmd <<< "${linha#*|}"
  corre_passo "f8d-$nome" "$P/logs/f8d-$nome.log" "${cmd[@]}" \
    || { etapa_fim F8d falhou "falhou em $nome ($n/$TOTAL) — ver logs/f8d-$nome.log"; exit 1; }
  etapa_nota F8d "$n/$TOTAL — último: $nome"
done

# --- Decisões (desvios ao livro): scripts/gui/decisoes-NN.txt, parágrafos "## Título" + texto
decisao "Interface gráfica: Xorg + Xfce 4.20 com aspeto ao estilo do macOS" \
"Pedido: uma interface gráfica moderna, ao estilo do macOS. Escolheu-se o Xfce 4.20 do BLFS sobre o Xorg (com Mesa e LightDM) em vez do GNOME ou do KDE: é o ambiente completo mais leve do livro (cabe numa ISO live e corre em VMs sem aceleração 3D, com o llvmpipe do Mesa), mantém tudo dentro do BLFS 12.4 System V, e o seu painel e gestor de janelas permitem reproduzir o aspeto do macOS (barra superior, dock, botões de janela à esquerda, compositor com sombras) com temas livres. Wayland não é usado: nenhum compositor Wayland adequado está no BLFS e o Xfce 4.20 é uma sessão X11. A lista de páginas foi resolvida automaticamente das dependências Required + Recommended das páginas-alvo (scripts/blfs-deps.py, scripts/gui/resolver.sh); foram cortadas recomendações sem utilidade num ambiente de trabalho e muito pesadas (TeX Live, GTK4, GStreamer, PulseAudio, GEGL/Graphviz, Vala, XScreenSaver, Vulkan, DocBook) — lista em scripts/gui/resolver.sh. Ciclos de dependências resolvidos à mão como o livro indica (FreeType recompilado depois do HarfBuzz; driver xf86-input-libinput depois do Xorg-Server; gdk-pixbuf antes do librsvg; GTK3 antes do adwaita-icon-theme) — ver scripts/gui/ordem.txt."
for f in $G/decisoes-0[1-9].txt; do
  [ -r "$f" ] || continue
  python3 - "$f" <<'EOF' | while IFS=$'\t' read -r titulo texto; do decisao "$titulo" "$texto"; done
import sys, re
t = open(sys.argv[1], encoding="utf-8").read()
for m in re.finditer(r"^## (.+?)\n(.*?)(?=^## |\Z)", t, re.S | re.M):
    print(m.group(1).strip() + "\t" + re.sub(r"\s*\n\s*", " ", m.group(2).strip()))
EOF
done

aviso=$( (grep -l 'AVISO-TESTE' $P/logs/f8d-*.log 2>/dev/null || true) | xargs -r -n1 basename | sed 's/^f8d-//;s/\.log$//' | tr '\n' ' ')
refazer_seguintes
if [ -n "$aviso" ]; then
  etapa_fim F8d aviso "$TOTAL passos (Xorg, Mesa, GTK3, Xfce, LightDM, tema); testes com falhas (tolerados, ver logs): $aviso"
else
  etapa_fim F8d ok "$TOTAL passos: Xorg, Mesa, GTK3, Xfce 4.20, LightDM e tema ao estilo do macOS"
fi
