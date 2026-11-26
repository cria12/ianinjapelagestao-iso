#!/bin/bash
# F0 — Preparação do host
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
command -v jq >/dev/null || { dpkg --configure -a; apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq jq; }
estado_init
[ "$(etapa_estado F0)" = ok ] && exit 0
etapa_inicio F0

decisao "Host de construção: WSL2 (Ubuntu 24.04) em Windows 11" \
"O computador do dono do projeto é Windows 11 (12 núcleos, 16 GB RAM). O prompt assume um host Linux, por isso foi instalada a distribuição Ubuntu-24.04 no WSL2 já presente (kernel 6.18 da Microsoft, com suporte a loop, squashfs, overlay e /dev/kvm). O ficheiro %USERPROFILE%\\.wslconfig foi criado com memory=12GB, swap=8GB, processors=12 e vmIdleTimeout/instanceIdleTimeout=-1 para que a VM não seja desligada durante a compilação. Em /etc/wsl.conf: systemd=true, utilizador por omissão root e appendWindowsPath=false (o PATH do Windows tem espaços e parêntesis que poluiriam o ambiente). O projeto vive em /root/ianinjapelagestao (ext4 do WSL); a ISO e os documentos finais são copiados para C:\\Users\\User\\Documents\\ianinjapelagestao_iso."

decisao "Transcrição dos comandos do livro" \
"Os comandos de cada pacote são extraídos automaticamente do HTML oficial do LFS/BLFS 12.4 (blocos <pre class=\"userinput\"> e <pre class=\"root\">) por scripts/extract-book.py, em vez de reescritos à mão — garante transcrição literal e sem erros de cópia. Blocos interativos ou só explicativos (passwd, su - lfs, exec bash --login, tzselect, vim -c ':options', exemplos de make -j32, etc.) são listados explicitamente em scripts/book-overrides.txt com o motivo. Blocos de test suite correm com tolerância a falhas (o livro documenta falhas conhecidas) e os resultados ficam nos logs."

decisao "Errata LFS/BLFS 12.4" \
"Errata consultada em $(date +%F): a única alteração com impacto é a troca de ftp.gnu.org/gnu por ftpmirror.gnu.org, já refletida na wget-list-sysv publicada (versão de dez/2025). A errata do BLFS não afeta os pacotes escolhidos."

pkgs=(build-essential bison gawk texinfo m4 python3 patch wget curl xz-utils bzip2 gzip tar file
      xorriso squashfs-tools mtools dosfstools grub-common grub-pc-bin grub-efi-amd64-bin
      qemu-system-x86 ovmf expect tmux jq ntfs-3g exfatprogs)
decisao "Rede do WSL em modo mirrored" \
"Com a rede NAT por omissão do WSL2 as transferências ficavam a ~50 KB/s (no Windows: ~2,5 MB/s). Foi definido networkingMode=mirrored em .wslconfig, o que elevou a velocidade para 1,5–4 MB/s."
corre_passo f0-apt $P/logs/00-apt.log bash -c "export DEBIAN_FRONTEND=noninteractive; dpkg --configure -a; apt-get update && apt-get install -y ${pkgs[*]}"
ln -sf bash /bin/sh

# version-check.sh tal como no livro (Cap. 2.2)
python3 $P/scripts/extract-book.py $P/book/lfs/12.4/chapter02/hostreqs.html \
  | sed -e '0,/^cat > version-check.sh << "EOF"$/d' -e '/^EOF$/,$d' > $P/scripts/version-check.sh
[ -s $P/scripts/version-check.sh ] || { echo "version-check.sh vazio"; exit 1; }
bash $P/scripts/version-check.sh > $P/logs/00-version-check.log 2>&1 || true
if grep -qE 'ERROR|FATAL' $P/logs/00-version-check.log; then
  etapa_fim F0 falhou "version-check com erros"
  exit 1
fi
etapa_fim F0 ok "version-check OK; host WSL2 Ubuntu 24.04, $(nproc) núcleos"
