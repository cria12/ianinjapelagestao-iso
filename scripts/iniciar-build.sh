#!/bin/bash
# Arranca o orquestrador numa sessão tmux (sobrevive ao fecho do terminal) e espera que termine.
P=/root/ianinjapelagestao
if [ -f $P/logs/run-all.pid ] && kill -0 "$(cat $P/logs/run-all.pid)" 2>/dev/null; then
  echo "run-all já em execução (pid $(cat $P/logs/run-all.pid))"
else
  tmux kill-session -t build 2>/dev/null
  tmux new-session -d -s build "bash $P/scripts/run-all.sh"
  sleep 2
fi
# espera (para notificação de fim)
while [ -f $P/logs/run-all.pid ] && kill -0 "$(cat $P/logs/run-all.pid)" 2>/dev/null; do sleep 30; done
tail -3 $P/logs/run-all.log
tail -4 $P/logs/registo.log
