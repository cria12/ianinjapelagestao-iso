#!/bin/bash
# F5 — Sistema base (LFS Cap. 8), dentro do chroot, na ordem do livro
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F5)" = ok ] && exit 0
montar_lfs
montar_kernfs > /dev/null
etapa_inicio F5
preparar_runner

# Test suites obrigatórias: GMP, MPFR e MPC sem falhas; Glibc, GCC e Binutils com resumo registado
verifica_testes() {
  local page=$1 lf=$P/logs/08-${1#*/}.log
  case ${page#*/} in
    gmp|mpfr|mpc)
      if grep -Eq '^# (FAIL|ERROR): +[1-9]' "$lf" || grep -q 'AVISO-TESTE' "$lf"; then
        registo "✘ test suite obrigatória de ${page#*/} com falhas"; return 1
      fi
      registo "Test suite ${page#*/}: $(grep -E '^# PASS:' "$lf" | awk '{s+=$3} END{print s}') testes passaram, 0 falhas" ;;
    glibc)
      registo "Test suite Glibc: $(grep -cE '^FAIL:' "$lf" || true) FAIL (livro documenta falhas conhecidas): $(grep -E '^FAIL:' "$lf" | awk '{print $2}' | tr '\n' ' ' | cut -c1-300)" ;;
    binutils)
      registo "Test suite Binutils: $(grep -E '^# of unexpected failures' "$lf" | awk '{s+=$NF} END{print s+0}') falhas inesperadas" ;;
    gcc)
      registo "Test suite GCC: $(grep -E '^# of unexpected failures' "$lf" | awk '{s+=$NF} END{print s+0}') falhas inesperadas (resumo em logs/08-gcc.log)" ;;
  esac
}

mapfile -t pages < <(grep '^chapter08/' $P/scripts/lfs-pages.txt)
total=${#pages[@]}; n=0
for page in "${pages[@]}"; do
  n=$((n+1))
  if ! passo_feito "$page"; then
    corre_paginas F5 chroot 08 "$page" || exit 1
    verifica_testes "$page" || { etapa_fim F5 falhou "test suite obrigatória falhou em $page"; exit 1; }
  fi
  etapa_nota F5 "$n/$total pacotes/secções — último: ${page#*/}"
done
aviso=$(grep -l 'AVISO-TESTE' $P/logs/08-*.log 2>/dev/null | xargs -r -n1 basename | sed 's/^08-//;s/\.log$//' | tr '\n' ' ')
if [ -n "$aviso" ]; then
  etapa_fim F5 aviso "$total pacotes/secções; testes com falhas (tolerados, ver logs): $aviso"
else
  etapa_fim F5 ok "$total pacotes/secções"
fi
