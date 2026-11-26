#!/bin/bash
# Orquestrador: corre todas as etapas por ordem; cada etapa salta o que já está em progresso.json.
# Uso (em segundo plano): tmux new -d -s build 'bash /root/ianinjapelagestao/scripts/run-all.sh'
set -uo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
exec >> $P/logs/run-all.log 2>&1
# uma só instância: duas a correr ao mesmo tempo pisam-se (ex.: mesmo diretório temporário)
exec 9> $P/logs/run-all.lock
flock -n 9 || { echo "===== run-all já em execução noutra instância — esta sai $(date)"; exit 0; }
echo "===== run-all iniciado $(date) (pid $$)"
echo $$ > $P/logs/run-all.pid
trap 'rm -f $P/logs/run-all.pid' EXIT
for id in "${ETAPA_IDS[@]}"; do
  e=$(etapa_estado "$id")
  [ "$e" = ok ] || [ "$e" = aviso ] && continue
  s=$(script_etapa "$id")   # F8 -> f08-*.sh, F8b -> f08b-*.sh
  if [ -z "$s" ]; then
    echo "===== run-all em pausa: script da etapa $id ainda não existe $(date)"
    exit 2
  fi
  echo "----- $(date) $s"
  if ! bash "$s"; then
    echo "===== run-all PAROU em $s $(date)"
    registo "Orquestrador parado em $id ($(basename "$s")) — ver logs/run-all.log"
    exit 1
  fi
done
echo "===== run-all terminou $(date)"
