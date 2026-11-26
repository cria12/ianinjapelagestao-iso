#!/bin/bash
set -e
source /root/ianinjapelagestao/scripts/lib.sh
cp $STATE $P/logs/progresso.json.antes-drivers
for id in F7 F9 F10 F11 F12; do
  _jq_inplace --arg id "$id" '.etapas[$id].estado="pendente" | .etapas[$id].inicio="" | .etapas[$id].fim="" | .etapas[$id].inicio_ts=0 | .etapas[$id].fim_ts=0 | .etapas[$id].notas=""'
done
estado_completar
render_etapas
registo "Drivers: F7 (kernel base Arch, módulos), F8c (nova: firmware + Wi-Fi + som), F9-F12 repostas a pendente"
jq -r '.etapas | to_entries[] | .key + " " + .value.estado' $STATE
rm -rf /root/dl-arch /tmp/bs /tmp/lfw /mnt/lfs/root/config-teste /mnt/lfs/root/kernel-opcoes.txt
df -h /mnt/lfs | tail -1
