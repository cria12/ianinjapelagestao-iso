#!/bin/bash
# Biblioteca comum: estado (progresso.json), ETAPAS.md e registo.
# Deve ser "source"-ada pelos scripts de etapa (correm como root no host).

P=/root/ianinjapelagestao
export LFS=/mnt/lfs
STATE=$P/progresso.json
ETAPAS=$P/ETAPAS.md
REGISTO=$P/logs/registo.log
mkdir -p "$P/logs"

ETAPA_IDS=(F0 F1 F2 F3 F4 F5 F6 F7 F8 F8b F8c F8d F8e F9 F10 F11 F12)
declare -A ETAPA_NOME=(
  [F0]="Preparação do host"
  [F1]="Imagem, fontes e utilizador lfs (Cap. 2-4)"
  [F2]="Cross-toolchain (Cap. 5)"
  [F3]="Ferramentas temporárias (Cap. 6)"
  [F4]="Chroot e ferramentas adicionais (Cap. 7)"
  [F5]="Sistema base (Cap. 8)"
  [F6]="Configuração do sistema + identidade (Cap. 9)"
  [F7]="Kernel e boot (Cap. 10)"
  [F8]="Pacotes BLFS"
  [F8b]="Inteligência artificial (llama.cpp + modelo)"
  [F8c]="Drivers e firmware"
  [F8d]="Interface gráfica (Xorg + Xfce, estilo macOS)"
  [F8e]="Aplicações, drivers, programação, loja e face-finder"
  [F9]="Sistema live (initramfs + SquashFS)"
  [F10]="Geração da ISO"
  [F11]="Testes automáticos (QEMU BIOS/UEFI)"
  [F12]="Entrega"
)

agora() { date '+%Y-%m-%d %H:%M'; }

_jq_inplace() { # _jq_inplace <filtro jq> [args...]
  local tmp; tmp=$(mktemp)
  jq "$@" "$STATE" > "$tmp" && mv "$tmp" "$STATE"
}

# Acrescenta ao progresso.json as etapas de ETAPA_IDS que ainda lá não estão (ex.: F8b, criada
# depois de o estado existir), sem alterar as existentes.
estado_completar() {
  [ -s "$STATE" ] || return 0
  local id
  for id in "${ETAPA_IDS[@]}"; do
    jq -e --arg id "$id" '.etapas|has($id)' "$STATE" >/dev/null && continue
    _jq_inplace --arg id "$id" --arg n "${ETAPA_NOME[$id]}" \
      '.etapas[$id]={nome:$n, estado:"pendente", inicio:"", fim:"", inicio_ts:0, fim_ts:0, notas:""}'
  done
}

estado_init() {
  [ -s "$STATE" ] && { estado_completar; return 0; }
  local now; now=$(agora)
  local etapas='{}'
  for id in "${ETAPA_IDS[@]}"; do
    etapas=$(jq --arg id "$id" --arg n "${ETAPA_NOME[$id]}" \
      '. + {($id): {nome:$n, estado:"pendente", inicio:"", fim:"", inicio_ts:0, fim_ts:0, notas:""}}' <<<"$etapas")
  done
  jq -n --arg now "$now" --argjson e "$etapas" \
    '{inicio:$now, atualizado:$now, etapa_atual:"F0", passo:"", tentativas:0, etapas:$e, passos_concluidos:[]}' > "$STATE"
  : > "$REGISTO"
  render_etapas
}

registo() { # registo "mensagem"
  echo "- $(agora) — $*" >> "$REGISTO"
  echo "[$(agora)] $*"
  render_etapas
}

log() { registo "$@"; }

# Espaço livre no C: do Windows (o disco virtual do WSL e a ISO final vivem lá)
disco_c() {
  local livre total
  read -r total livre < <(df -BG --output=size,avail /mnt/c 2>/dev/null | tail -1 | tr -d G)
  [ -n "$livre" ] || return 0
  _jq_inplace --arg l "$livre" --arg t "$total" --arg h "$(agora)" '.disco_c={livre_gb:$l, total_gb:$t, medido:$h}'
  if [ "$livre" -lt 60 ]; then
    echo "- $(agora) — ⚠️ Pouco espaço no C: ${livre} GB livres (mínimo recomendado: 60 GB)" >> "$REGISTO"
  fi
}

etapa_inicio() { # etapa_inicio F2 "nota"
  disco_c
  local id=$1 nota=${2:-}
  _jq_inplace --arg id "$id" --arg t "$(agora)" --argjson ts "$(date +%s)" --arg n "$nota" \
    '.etapa_atual=$id | .etapas[$id].estado="curso" | .tentativas=0
     | (if .etapas[$id].inicio=="" then .etapas[$id].inicio=$t | .etapas[$id].inicio_ts=$ts else . end)
     | (if $n!="" then .etapas[$id].notas=$n else . end)'
  registo "Início da etapa $id — ${ETAPA_NOME[$id]}"
}

etapa_fim() { # etapa_fim F2 ok|aviso|falhou "nota"
  local id=$1 est=$2 nota=${3:-}
  _jq_inplace --arg id "$id" --arg e "$est" --arg t "$(agora)" --argjson ts "$(date +%s)" --arg n "$nota" \
    '.etapas[$id].estado=$e | .etapas[$id].fim=$t | .etapas[$id].fim_ts=$ts
     | (if $n!="" then .etapas[$id].notas=$n else . end)'
  registo "Fim da etapa $id (${est}) ${nota}"
}

etapa_nota() { # etapa_nota F5 "12/80 pacotes"
  _jq_inplace --arg id "$1" --arg n "$2" '.etapas[$id].notas=$n'
  render_etapas
}

etapa_estado() { jq -r --arg id "$1" '.etapas[$id].estado // "pendente"' "$STATE"; }

# script_etapa <id>: script da etapa — F8 -> scripts/f08-*.sh, F8b -> scripts/f08b-*.sh, F8c -> f08c-*.sh, F8d -> f08d-*.sh
# (número com 2 dígitos + sufixo opcional; "f08-*" não apanha "f08b-*")
script_etapa() {
  local num=${1#F} n suf
  n=${num%%[!0-9]*}; suf=${num#"$n"}
  ls $P/scripts/f$(printf '%02d' "$((10#$n))")${suf}-*.sh 2>/dev/null | head -1 || true
}

passo_feito() { jq -e --arg p "$1" '.passos_concluidos|index($p)!=null' "$STATE" >/dev/null; }

passo_marcar() { # passo_marcar id
  _jq_inplace --arg p "$1" '.passos_concluidos += [$p] | .passos_concluidos |= unique | .passo="" | .tentativas=0'
}

passo_atual() { # passo_atual id tentativa
  _jq_inplace --arg p "$1" --argjson t "${2:-1}" '.passo=$p | .tentativas=$t'
}

# corre_passo <id> <logfile> <comando...> — idempotente, até 3 tentativas
corre_passo() {
  local id=$1 lf=$2; shift 2
  if passo_feito "$id"; then return 0; fi
  local t
  for t in 1 2 3; do
    passo_atual "$id" "$t"
    registo "→ $id (tentativa $t) — log: ${lf#$P/}"
    if "$@" > "$lf" 2>&1; then
      passo_marcar "$id"
      registo "✔ $id concluído"
      return 0
    fi
    registo "✘ $id falhou na tentativa $t (ver ${lf#$P/})"
    [ -n "${NO_RETRY:-}" ] && break
  done
  return 1
}

_dur() { # segundos -> texto
  local s=$1
  [ "$s" -le 0 ] && { echo "—"; return; }
  if [ "$s" -lt 3600 ]; then echo "$(( (s+59)/60 )) min"; else printf '%dh%02d\n' $((s/3600)) $(((s%3600)/60)); fi
}

render_etapas() {
  [ -s "$STATE" ] || return 0
  estado_completar
  _jq_inplace --arg t "$(agora)" '.atualizado=$t'
  local total=${#ETAPA_IDS[@]} feitas=0 frac=0 linhas="" id
  for id in "${ETAPA_IDS[@]}"; do
    local e ini fim its fts notas icon dur
    e=$(jq -r --arg id "$id" '.etapas[$id].estado' "$STATE")
    ini=$(jq -r --arg id "$id" '.etapas[$id].inicio' "$STATE")
    fim=$(jq -r --arg id "$id" '.etapas[$id].fim' "$STATE")
    its=$(jq -r --arg id "$id" '.etapas[$id].inicio_ts' "$STATE")
    fts=$(jq -r --arg id "$id" '.etapas[$id].fim_ts' "$STATE")
    notas=$(jq -r --arg id "$id" '.etapas[$id].notas' "$STATE")
    case $e in
      pendente) icon="⏳ Pendente" ;;
      curso)    icon="🔄 Em curso" ;;
      ok)       icon="✅ Concluída"; feitas=$((feitas+1)) ;;
      aviso)    icon="⚠️ Concluída c/ aviso"; feitas=$((feitas+1)) ;;
      falhou)   icon="❌ Falhou" ;;
    esac
    dur="—"; [ "$fts" -gt 0 ] && dur=$(_dur $((fts-its)))
    [ "$e" = curso ] && fim="—"
    linhas+="| $id | ${ETAPA_NOME[$id]} | $icon | $ini | $fim | $dur | $notas |"$'\n'
  done
  local pct=$(( feitas*100/total ))
  {
    echo "# ianinjapelagestao — Etapas do Projeto"
    echo "Início: $(jq -r .inicio "$STATE") | Última atualização: $(agora) | Progresso global: ${pct} %"
    echo
    jq -r 'if .disco_c then "Espaço livre no C: (Windows): **\(.disco_c.livre_gb) GB** de \(.disco_c.total_gb) GB (medido em \(.disco_c.medido))\n" else empty end' "$STATE"
    jq -r 'if .estimativa then "Estimativa de conclusão: **\(.estimativa)**\n" else empty end' "$STATE"
    echo "Etapa atual: **$(jq -r .etapa_atual "$STATE")** · Passo: \`$(jq -r .passo "$STATE")\` · Tentativa: $(jq -r .tentativas "$STATE")"
    echo
    echo "| # | Etapa | Estado | Início | Fim | Duração | Notas |"
    echo "|---|-------|--------|--------|-----|---------|-------|"
    printf '%s' "$linhas"
    echo
    echo "Legenda: ⏳ Pendente · 🔄 Em curso · ✅ Concluída · ⚠️ Concluída c/ aviso · ❌ Falhou"
    echo
    echo "## Registo detalhado"
    cat "$REGISTO"
  } > "$ETAPAS.tmp" && mv "$ETAPAS.tmp" "$ETAPAS"
}

decisao() { # decisao "título" "texto"
  local f=$P/docs/DECISOES.md
  [ -s "$f" ] || printf '# ianinjapelagestao — Decisões tomadas autonomamente\n\n' > "$f"
  grep -qF "## $1" "$f" 2>/dev/null && return 0
  printf '## %s\n_%s_\n\n%s\n\n' "$1" "$(agora)" "$2" >> "$f"
}

lfs_montado() { mountpoint -q "$LFS"; }

# Copia os scripts gerados para $LFS/sources/ianinja (visível no host e no chroot)
preparar_runner() {
  local B=$P/book/lfs/12.4 S=$P/scripts
  python3 $S/gen-scripts.py lfs $B $(cat $S/lfs-pages.txt) > /dev/null
  python3 $S/map-tarballs.py $B $LFS/sources < $S/lfs-pages.txt > $S/tarballs.txt
  if grep -q ' ERRO$' $S/tarballs.txt; then echo "páginas sem tarball:"; grep ' ERRO$' $S/tarballs.txt; return 1; fi
  mkdir -p $LFS/sources/ianinja
  rm -rf $LFS/sources/ianinja/gen
  cp -r $S/gen $S/run-pkg.sh $S/tarballs.txt $LFS/sources/ianinja/
  chmod -R a+rX $LFS/sources/ianinja
  carregar_senhas && install -m600 $S/senhas.local $LFS/sources/ianinja/senhas.local
}

# Senhas do root e do ninja: vêm de scripts/senhas.local (fora do Git, modo 600).
# Se o ficheiro não existir, é criado com senhas aleatórias. Exporta SENHA_ROOT e SENHA_NINJA.
carregar_senhas() {
  local f=$P/scripts/senhas.local
  if [ ! -f "$f" ]; then
    ( umask 077
      printf 'SENHA_ROOT=%s\nSENHA_NINJA=%s\n' \
        "$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)" \
        "$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)" > "$f" )
    echo "senhas novas geradas em $f"
  fi
  . "$f"
  [ -n "$SENHA_ROOT" ] && [ -n "$SENHA_NINJA" ] || { echo "faltam SENHA_ROOT/SENHA_NINJA em $f"; return 1; }
  export SENHA_ROOT SENHA_NINJA
}

# Executar como lfs com o ambiente do Cap. 4.4 (equivalente a "su - lfs")
as_lfs() {
  runuser -u lfs -- env -i HOME=/home/lfs TERM=xterm bash -c 'source ~/.bashrc; "$@"' _ "$@"
}

# Executar dentro do chroot com o ambiente do Cap. 7.4
in_chroot() {
  chroot "$LFS" /usr/bin/env -i \
    HOME=/root TERM=xterm PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash -c "$*"
}

montar_kernfs() {
  mkdir -pv $LFS/{dev,proc,sys,run}
  mountpoint -q $LFS/dev  || mount -v --bind /dev $LFS/dev
  mountpoint -q $LFS/dev/pts || mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
  mountpoint -q $LFS/proc || mount -vt proc proc $LFS/proc
  mountpoint -q $LFS/sys  || mount -vt sysfs sysfs $LFS/sys
  mountpoint -q $LFS/run  || mount -vt tmpfs tmpfs $LFS/run
  if [ -h $LFS/dev/shm ]; then
    install -v -d -m 1777 $LFS$(realpath /dev/shm)
  else
    mountpoint -q $LFS/dev/shm || mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
  fi
}

desmontar_kernfs() {
  mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
  mountpoint -q $LFS/dev/pts && umount $LFS/dev/pts
  for d in sys proc run dev; do mountpoint -q $LFS/$d && umount $LFS/$d; done
  return 0
}

# corre_paginas <etapa> <modo: lfs|chroot|host> <prefixo-log> <paginas...>
corre_paginas() {
  local etapa=$1 modo=$2 pref=$3; shift 3
  local total=$# n=0 page nome
  for page in "$@"; do
    n=$((n+1)); nome=${page#*/}
    case $modo in
      lfs)    corre_passo "$page" "$P/logs/$pref-$nome.log" as_lfs bash $LFS/sources/ianinja/run-pkg.sh "$page" ;;
      chroot) corre_passo "$page" "$P/logs/$pref-$nome.log" in_chroot "bash /sources/ianinja/run-pkg.sh $page" ;;
      host)   corre_passo "$page" "$P/logs/$pref-$nome.log" bash -c "export LFS=$LFS; cd $LFS/sources && bash -e $LFS/sources/ianinja/gen/lfs/$page.sh" ;;
    esac || { etapa_fim "$etapa" falhou "falhou em $page ($n/$total) — ver logs/$pref-$nome.log"; return 1; }
    etapa_nota "$etapa" "$n/$total — último: $nome"
  done
}

montar_lfs() {
  lfs_montado && return 0
  mkdir -p "$LFS"
  # dispositivo loop novo: o mount -o loop reutiliza um loop já associado à imagem (ex. uma montagem
  # só de leitura que ficou noutro namespace) e montaria só de leitura
  local d; d=$(losetup -f --show "$P/lfs.img") || return 1
  mount "$d" "$LFS" || { losetup -d "$d"; return 1; }
}
