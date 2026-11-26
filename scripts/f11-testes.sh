#!/bin/bash
# F11 — Testes automáticos da ISO em QEMU headless (BIOS e UEFI + persistência)
# Sem /dev/kvm os timeouts do expect passam a >= 10 min e timeouts contam como LENTO (não como falha).
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F11)" = ok ] && exit 0
etapa_inicio F11
carregar_senhas   # exporta SENHA_ROOT/SENHA_NINJA para os testes .exp
ISO=$P/output/ianinjapelagestao-12.4-x86_64.iso
NCRIT=20         # critérios por modo (bios/uefi): 7 originais + zram + IA + módulos automáticos
                 # + interface gráfica (12 LightDM, 13 Xorg/greeter, 14 fonte Inter e tema)
                 # + aplicações da F8e (15 instaladores, 16 programação, 17 Flatpak/Loja,
                 #   18 drivers/Vulkan, 19 face-finder) + 20 rede NetworkManager
                 # + 21 assistente desligado pelo SMBIOS (o 11 é a persistência, à parte)
NASS=4           # critérios do modo assistente-bios (assistente ativo, é o greeter, cria conta, autentica)
IMG=$P/logs/11-dados-teste.img
IMG_NTFS=$P/logs/11-disco-ntfs-teste.img
IMG_PEN=$P/logs/11-pen-teste.img
trap 'rm -f $IMG $IMG_NTFS $IMG_PEN' EXIT
if [ -e /dev/kvm ] && [ -w /dev/kvm ]; then
  registo "F11: /dev/kvm disponível — QEMU com aceleração KVM"
else
  registo "F11: /dev/kvm NÃO disponível — QEMU em emulação TCG; timeouts >= 10 min; lentidão não conta como falha"
  decisao "Testes F11 sem KVM" \
"Neste host /dev/kvm não existe (ou não é acessível). O QEMU corre em emulação por software (TCG), muito mais lento: todos os timeouts do expect passam a ser no mínimo 600 s e um timeout é registado como LENTO (inconclusivo por lentidão) em vez de FAIL. Só um resultado observado incorreto (ex.: login recusado, wget a falhar) conta como falha."
fi
decisao "Testes F11: zram, IA e persistência" \
"Aos 7 critérios originais (iguais) juntam-se: 8 'zram ativo' (/dev/zram* em /proc/swaps) e 9 'IA responde' (ia-perguntar \"Responde apenas com a palavra OK.\" como root na consola série; passa se imprimir uma linha não vazia antes de o prompt voltar; timeout 180 s com KVM e 900 s sem KVM, onde conta como LENTO). Os modos BIOS e UEFI passam a ter 9 critérios. A VM passa de -m 2048 -smp 2 para -m 4096 -smp 4 (um modelo de 1,5 B em Q4 ocupa ~1-1,5 GiB mais o KV cache, e o llama.cpp usa vários threads); com KVM usa -cpu host (o llama.cpp vê AVX2/AVX-512 do host), sem KVM -cpu max,la57=off (TCG emula AVX2; la57 desligado por compatibilidade com o OVMF). O critério 10 'persistência' corre à parte, só em BIOS: um ficheiro-imagem de 1 GiB formatado diretamente com mkfs.ext4 -L IANINJA-DADOS (sem tabela de partições nem loop — o blkid encontra o rótulo no disco inteiro /dev/vda) é ligado como disco virtio; no 1.º arranque confirma-se a mensagem 'persistência: IANINJA-DADOS (/dev/vda)', escreve-se /root/marcador-persistencia e desliga-se; no 2.º arranque confirma-se que o marcador existe. A imagem é apagada no fim (e também se o script sair a meio)."
decisao "Testes F11: módulos carregados automaticamente" \
"Com o kernel de drivers em módulos (base Arch, F7) acrescentou-se o critério 10 'Módulos carregados automaticamente (snd_hda_intel via udev)' aos modos BIOS e UEFI, que passam a ter 10 critérios: a VM ganha uma placa de som HDA (-device intel-hda -device hda-duplex), cujo driver snd_hda_intel é módulo; depois do login confirma-se, sem nada carregar à mão, que 'lsmod' o mostra (espera até 20 s) e que /lib/modules/\$(uname -r)/kernel existe (o comando mostra também o número de módulos carregados e /proc/asound/cards). Escolheu-se a placa de som porque a rede (e1000) tem de continuar embutida para o critério 5 não depender de módulos, e o som não tem driver embutido nenhum. O teste de persistência passa a ser o critério 11 (sem placa de som, igual ao anterior)."
decisao "Testes F11: interface gráfica" \
"Com o nível 5 por omissão (F8d) o login de teste continua a ser pela ttyS0: o agetty da ttyS0 (e os de tty1-6) está ativo nos níveis 2345 e o LightDM usa o vt7, pelo que os critérios 1-11 não mudam. A VM passa a ter -vga std explícito (placa bochs, cujo driver DRM bochs é módulo carregado pelo udev e dá KMS ao Xorg com o driver modesetting; -nographic só tira a janela, a placa existe) e, nos modos BIOS e UEFI, o monitor do QEMU num socket unix (logs/11-monitor-<modo>.sock; com -monitor explícito a série fica sozinha no stdio). Novos critérios nos modos BIOS e UEFI, que passam a ter 13: 12 'LightDM a correr no nível 5' (pidof lightdm, mostrando runlevel e a linha id: do inittab); 13 'Xorg arrancou (modesetting, sem Fatal server error) e greeter ativo' (pidof Xorg ou X, /var/log/Xorg.0.log — ou /var/log/lightdm/x-0.log — com o módulo modesetting carregado e sem 'Fatal server error', e pidof lightdm-gtk-greeter); 14 'Fonte Inter e tema WhiteSur-Light' (fc-list : family começa por Inter e existe /usr/share/themes/WhiteSur-Light/gtk-3.0). Para 12-13 espera-se até 180 s com KVM e 600 s sem KVM (sem KVM o Xorg e o greeter demoram minutos a arrancar): não terem aparecido conta como timeout (LENTO sem KVM, FAIL com KVM); 'Fatal server error' é sempre FAIL. Correm antes do critério 9 (IA), cuja carga não deve atrasar o X. Se o critério 13 passar, tira-se uma captura do greeter pelo monitor (comando screendump, em PPM, enviado com socat) e converte-se para logs/11-ecra-<modo>.png com scripts/ppm-para-png.py (só a biblioteca padrão do Python: o host não tem ImageMagick, netpbm nem PIL, e não se instalou nada); a captura é só informativa (linha INFO) e nunca falha o teste. O teste de persistência (critério 11) mantém o monitor no stdio, como antes."
decisao "Testes F11: aplicações da F8e" \
"Com a F8e (aplicações, programação, drivers, face-finder e Loja) os modos BIOS e UEFI passam de 13 para 18 critérios, em 5 grupos, todos sem rede obrigatória e depois do critério 14 (antes da IA): 15 'Instaladores' (como ninja: instalar-aplicacoes -l e instalar-ferramentas -l correm; /usr/local/bin/instalar-tudo-click.sh executável e com sintaxe válida; /etc/xdg/autostart/instalar-tudo-default.desktop com Exec= para ele); 16 'Programação' (node --version, npm --version, python3 -I -c 'import sqlite3, requests, numpy, cv2', gdb --version, e o prefixo global do npm do ninja é ~/.npm-global); 17 'Flatpak' (flatpak --version, bwrap --version, flathub em flatpak remotes --system, uma sandbox bwrap --unshare-all como ninja — namespaces de utilizador do kernel arrancado, que o chroot da F8e não pôde testar — e loja --verificar como ninja); 18 'Drivers' (vulkaninfo --summary mostra o lavapipe/llvmpipe, a única ICD Vulkan que funciona no QEMU sem GPU; info-hardware corre; instalar-driver-nvidia -l sai com 0 e diz 'nenhuma' sem erros; bluetoothctl --version; headsetcontrol --help; xfce4-screenshooter --version, ou --help se não houver ecrã); 19 'face-finder' (corre em /usr/share/face-finder/fotos, resultados.json com total_rostos >= 1 e nenhuma imagem ilegível, relatorio.html criado). Cada verificação corre com timeout (120 s com KVM, 900 s sem KVM) e a saída fica no log; um comando em falta dá FAIL do grupo sem prender o teste. A VM já tem rede NAT do QEMU (-nic user, critério 5): o acesso ao Flathub (wget --spider de dl.flathub.org) é só INFO."
decisao "Testes F11: rede pelo NetworkManager e assistente de 1.º arranque" \
"Com os blocos 08 (NetworkManager no lugar do bootscript network/dhcpcd) e 09 (Assistente de configuração como greeter do LightDM) da F8e, os modos BIOS e UEFI passam de 18 para 20 critérios: 20 'Rede: NetworkManager liga o cabo sozinho' (a VM tem -nic user,model=e1000: pidof NetworkManager; nenhum link S..network em rc3.d, rc5.d nem no nível atual; nm-online -s -t 60; nmcli -t -f STATE general = connected; eth0:connected em nmcli -t -f DEVICE,STATE device; IP 10.0.2.x em eth0; nameserver no /etc/resolv.conf; /etc/xdg/autostart/nm-applet.desktop existe — o teste não abre sessão Xfce, só chega ao greeter, por isso o nm-applet em si não é testado) e 21 'Assistente desligado pela cadeia SMBIOS' (ianinja-assistente --estado como root diz exatamente 'desligado (ianinja.assistente=0 nas cadeias OEM do SMBIOS)'; a VM recebe -smbios type=11,value=ianinja.assistente=0 para o greeter fazer exec do lightdm-gtk-greeter e os critérios 12-13 continuarem certos). O critério 5 (DHCP + wget) espera agora até 120 s pelo IP, que passa a vir do NetworkManager (S33). Novo modo assistente-bios (BIOS, SEM a cadeia SMBIOS), 4 critérios: o estado é 'ativo'; o greeter do LightDM é o assistente (pgrep -f assistente.py com o lightdm a correr; se aparecer o lightdm-gtk-greeter é FAIL), com captura do ecrã em logs/11-ecra-assistente-bios.png só informativa; uma conta de ensaio ('ensaio', senha_root=false, sem autologin) criada pelo mesmo caminho do greeter (su lightdm -> sudo -n /usr/libexec/ianinja-assistente/aplicar criar, JSON no stdin) fica no grupo wheel, com senha e com o estado 'configurado'; e autentica com a senha (su ensaio a partir do ninja, que não é root, por isso a senha é pedida) e recusa uma senha errada. Tudo na camada de escrita em RAM; qualquer passo falha limpo (FAIL, ou LENTO sem KVM) sem prender os seguintes."
falhas=""; lentos=""; resumo=""
for modo in bios uefi; do
  registo "Teste QEMU $modo — log: logs/11-teste-$modo.log"
  expect $P/scripts/teste-qemu.exp $modo $ISO $P/logs/11-teste-$modo.log $P/logs/11-resultado-$modo.txt \
    > /dev/null 2>&1 || true
  pkill -f "qemu-system-x86_64.*$(basename $ISO)" 2>/dev/null || true
  rm -f $P/logs/11-monitor-$modo.sock
  r=$P/logs/11-resultado-$modo.txt
  n_pass=$(grep -c '^PASS' $r || true)
  n_fail=$(grep -c '^FAIL' $r || true)
  n_lento=$(grep -c '^LENTO' $r || true)
  registo "Teste $modo: $n_pass/$NCRIT aprovados, $n_fail falhas, $n_lento lentos $(grep -E '^(FAIL|LENTO)' $r | cut -c7- | tr '\n' ';' || true)"
  if [ "$n_fail" -gt 0 ]; then falhas="$falhas $modo"
  elif [ "$n_pass" -lt $NCRIT ]; then lentos="$lentos $modo"; fi
  m=$(echo $modo | tr a-z A-Z)
  resumo="$resumo${resumo:+, }$m $n_pass/$NCRIT"
done

# 11. Persistência (só BIOS): disco de dados ext4 IANINJA-DADOS num ficheiro-imagem
registo "Teste QEMU persistência (BIOS + disco IANINJA-DADOS) — log: logs/11-teste-persistencia.log"
r=$P/logs/11-resultado-persistencia.txt
rm -f $IMG
if truncate -s 1G $IMG && $(type -P mkfs.ext4) -q -F -L IANINJA-DADOS $IMG > $P/logs/11-mkfs-dados.log 2>&1; then
  expect $P/scripts/teste-qemu.exp persistencia $ISO $P/logs/11-teste-persistencia.log $r $IMG \
    > /dev/null 2>&1 || true
  pkill -f "qemu-system-x86_64.*$(basename $ISO)" 2>/dev/null || true
else
  echo "FAIL  Persistência: não foi possível criar a imagem de teste (ver logs/11-mkfs-dados.log)" > $r
fi
rm -f $IMG
p_pass=$(grep -c '^PASS' $r || true)
p_fail=$(grep -c '^FAIL' $r || true)
if [ "$p_fail" -gt 0 ]; then
  falhas="$falhas persistência"; p_estado=FALHOU
elif [ "$p_pass" -lt 1 ]; then
  lentos="$lentos persistência"; p_estado=LENTO
else
  p_estado=OK
fi
registo "Teste persistência: $p_estado $(grep -E '^(FAIL|LENTO)' $r | cut -c7- | tr '\n' ';' || true)"
resumo="$resumo, persistência $p_estado"

# 11b/11c. Persistência escolhida pelo assistente (bloco 11 da F8e): o backend ianinja-persistencia
# pelo caminho do greeter, em vários arranques (scripts/teste-persistencia.exp)
decisao "Testes F11: persistência em ficheiro (disco NTFS) e na própria pen" \
"Dois modos novos, com scripts/teste-persistencia.exp e os ids 'persistencia-ficheiro' (5 critérios) e 'persistencia-pen' (8 critérios), que chamam o backend pelo MESMO caminho do greeter (su lightdm -> sudo -n /usr/libexec/ianinja-assistente/aplicar persistencia-listar / persistencia-criar com JSON no stdin / reiniciar). persistencia-ficheiro: um disco virtio de 4 GiB feito no host com tabela GPT e uma partição NTFS (mkfs.ntfs do ntfs-3g; sem ele, exFAT com mkfs.exfat ou FAT32 com mkfs.vfat — o teste lê o id proposto pelo listar), como o disco do Windows; no 1.º arranque (BIOS, persistência desligada) o listar tem de propor ficheiro:/dev/vdaN; gravam-se um ficheiro em /home/ninja (dono ninja) e uma ligação Wi-Fi do NetworkManager (nmcli con add, com senha) ANTES do criar, porque o criar copia a camada de escrita tal como está nesse momento (o que se altera depois perde-se até reiniciar — por isso o assistente reinicia logo); o criar (1536 MiB) tem de dar PROGRESSO ... 100 e OK, e o 'aplicar reiniciar' reinicia (só permitido depois do OK; com -no-reboot o QEMU termina); no 2.º arranque o initramfs tem de dizer 'persistência: IANINJA-DADOS (ficheiro ianinja/ianinja-dados.img em /dev/vdaN)', o estado --json tem ativo=true e tipo=ficheiro, e o ficheiro e a ligação (com a senha no .nmconnection) têm de lá estar. persistencia-pen: imagem de 8 GiB (esparsa) com a ISO gravada no início, ligada como pen USB (qemu-xhci + usb-storage, bootindex=0), como uma pen gravada em modo imagem; o listar tem de propor pen:/dev/sda (recomendado), o criar cria a partição /dev/sda5 no espaço a seguir à imagem (sfdisk: cópia da GPT movida para o fim da pen + partição nova; partx; mkfs.ext4), e nos 2.º (BIOS) e 3.º (UEFI, OVMF) arranques o initramfs tem de usar /dev/sda5 e os dados têm de lá estar; no UEFI confirma-se ainda que o Xorg e o greeter arrancam (o arranque BIOS e UEFI da pen continua a funcionar com a tabela de partições alterada). As imagens ficam em logs/ e são apagadas no fim (também se o script sair a meio). Os testes antigos (critério 11 com o ext4 por rótulo num disco virtio, pen-*/disco-*) ficam iguais."
# disco "do Windows": GPT + uma partição NTFS (ou exFAT/FAT32 se o host não tiver o mkfs.ntfs)
disco_ntfs() {
  local d fs
  rm -f $IMG_NTFS
  truncate -s 4G $IMG_NTFS || return 1
  printf 'label: gpt\n,,%s\n' EBD0A0A2-B9E5-4433-87C0-68B6B72699C7 | sfdisk -q $IMG_NTFS || return 1
  d=$(losetup -f --show -P $IMG_NTFS) || return 1
  sleep 1
  if [ ! -b ${d}p1 ]; then losetup -d $d; return 1; fi
  if type -P mkfs.ntfs > /dev/null; then fs=ntfs; mkfs.ntfs -q -F -L Windows ${d}p1
  elif type -P mkfs.exfat > /dev/null; then fs=exfat; mkfs.exfat -q -L Windows ${d}p1
  else fs=vfat; mkfs.vfat -F 32 -n WINDOWS ${d}p1; fi
  local rc=$?
  losetup -d $d
  [ $rc = 0 ] && echo "disco de teste: GPT + partição $fs"
  return $rc
}
for modo in persistencia-ficheiro persistencia-pen; do
  r=$P/logs/11-resultado-$modo.txt
  registo "Teste QEMU $modo (persistência pelo assistente, vários arranques) — log: logs/11-teste-$modo.log"
  if [ $modo = persistencia-ficheiro ]; then
    if disco_ntfs > $P/logs/11-mkfs-ntfs.log 2>&1; then
      expect $P/scripts/teste-persistencia.exp ficheiro $ISO $P/logs/11-teste-$modo.log $r $IMG_NTFS > /dev/null 2>&1 || true
    else
      echo "FAIL  Persistência em ficheiro: não foi possível criar o disco NTFS de teste (ver logs/11-mkfs-ntfs.log)" > $r
    fi
    rm -f $IMG_NTFS
    n_crit=5
  else
    rm -f $IMG_PEN
    if truncate -s 8G $IMG_PEN && dd if=$ISO of=$IMG_PEN bs=4M conv=notrunc,sparse status=none; then
      expect $P/scripts/teste-persistencia.exp pen $ISO $P/logs/11-teste-$modo.log $r $IMG_PEN > /dev/null 2>&1 || true
    else
      echo "FAIL  Persistência na pen: não foi possível criar a imagem da pen de teste" > $r
    fi
    rm -f $IMG_PEN
    n_crit=8
  fi
  pkill -f "qemu-system-x86_64.*$(basename $ISO)" 2>/dev/null || true
  pkill -f "qemu-system-x86_64.*11-pen-teste.img" 2>/dev/null || true
  n_pass=$(grep -c '^PASS' $r || true)
  n_fail=$(grep -c '^FAIL' $r || true)
  n_lento=$(grep -c '^LENTO' $r || true)
  registo "Teste $modo: $n_pass/$n_crit aprovados, $n_fail falhas, $n_lento lentos $(grep -E '^(FAIL|LENTO)' $r | cut -c7- | tr '\n' ';' || true)"
  if [ "$n_fail" -gt 0 ]; then falhas="$falhas $modo"
  elif [ "$n_pass" -lt $n_crit ]; then lentos="$lentos $modo"; fi
  resumo="$resumo, $modo $n_pass/$n_crit"
done

# Assistente de 1.º arranque ativo (BIOS, sem a cadeia SMBIOS ianinja.assistente=0)
modo=assistente-bios
r=$P/logs/11-resultado-$modo.txt
registo "Teste QEMU $modo (assistente de 1.º arranque ativo) — log: logs/11-teste-$modo.log"
expect $P/scripts/teste-qemu.exp $modo $ISO $P/logs/11-teste-$modo.log $r > /dev/null 2>&1 || true
pkill -f "qemu-system-x86_64.*$(basename $ISO)" 2>/dev/null || true
rm -f $P/logs/11-monitor-$modo.sock
n_pass=$(grep -c '^PASS' $r || true)
n_fail=$(grep -c '^FAIL' $r || true)
n_lento=$(grep -c '^LENTO' $r || true)
registo "Teste $modo: $n_pass/$NASS aprovados, $n_fail falhas, $n_lento lentos $(grep -E '^(FAIL|LENTO)' $r | cut -c7- | tr '\n' ';' || true)"
if [ "$n_fail" -gt 0 ]; then falhas="$falhas $modo"
elif [ "$n_pass" -lt $NASS ]; then lentos="$lentos $modo"; fi
resumo="$resumo, $modo $n_pass/$NASS"

# 20. A ISO como pen USB (xhci + usb-storage) e como disco (virtio), em BIOS e UEFI
decisao "Testes F11: arranque como pen USB e como disco" \
"Num PC real com a ISO gravada numa pen USB (modo imagem/dd) o initramfs falhava com 'volume com LABEL=IANINJAPELAGESTAO ... não encontrado': o blkid mostrava o rótulo só na partição HFS+ (sda3) que o grub-mkrescue cria na tabela de partições híbrida, e o ISO9660 com live/rootfs.squashfs está no disco inteiro (/dev/sda), que o blkid não lista com o rótulo por ver a tabela de partições. No QEMU e no VirtualBox a ISO entrava sempre como CD (/dev/sr0, sem partições), por isso nenhum teste o apanhou. Novo grupo de testes (scripts/teste-pen.exp), 4 modos: pen-bios e pen-uefi (-device qemu-xhci -device usb-storage,removable=on,bootindex=0, a ISO como disco só-leitura: /dev/sda com sda1..sda4, como numa pen) e disco-bios e disco-uefi (virtio-blk, /dev/vda). Cada modo tem 4 critérios: o GRUB mostra o menu; o initramfs encontra o volume no DISCO INTEIRO (/dev/sdX ou /dev/vdX, não numa partição) e monta a raiz; login root na série; Xorg e lightdm-gtk-greeter a correr (até 180 s com KVM). A ISO é usada diretamente com readonly=on (não é preciso uma cópia)."
NPEN=4
for modo in pen-bios pen-uefi disco-bios disco-uefi; do
  r=$P/logs/11-resultado-$modo.txt
  registo "Teste QEMU $modo (ISO como disco) — log: logs/11-teste-$modo.log"
  expect $P/scripts/teste-pen.exp $modo $ISO $P/logs/11-teste-$modo.log $r > /dev/null 2>&1 || true
  pkill -f "qemu-system-x86_64.*$(basename $ISO)" 2>/dev/null || true
  n_pass=$(grep -c '^PASS' $r || true)
  n_fail=$(grep -c '^FAIL' $r || true)
  registo "Teste $modo: $n_pass/$NPEN aprovados, $n_fail falhas $(grep -E '^(FAIL|LENTO)' $r | cut -c7- | tr '\n' ';' || true)"
  if [ "$n_fail" -gt 0 ]; then falhas="$falhas $modo"
  elif [ "$n_pass" -lt $NPEN ]; then lentos="$lentos $modo"; fi
  resumo="$resumo, $modo $n_pass/$NPEN"
done

if [ -n "$falhas" ]; then
  etapa_fim F11 falhou "$resumo — critérios falharam em:$falhas (ver logs/11-resultado-*.txt)"
  exit 1
fi
if [ -n "$lentos" ]; then
  etapa_fim F11 aviso "$resumo — sem falhas; inconclusivo por lentidão (sem KVM) em:$lentos"
  exit 0
fi
etapa_fim F11 ok "$resumo"
