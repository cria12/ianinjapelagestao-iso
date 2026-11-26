#!/bin/bash
sync; echo 1 > /proc/sys/vm/drop_caches; free -m | sed -n 2p; tail -c 300 /root/ianinjapelagestao/logs/10-kernel.log
