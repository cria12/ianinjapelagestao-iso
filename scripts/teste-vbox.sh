#!/bin/bash
# Corre no Git Bash do Windows: cria uma VM VirtualBox descartável, arranca a ISO e testa-a por expect (WSL).
# Uso: teste-vbox.sh <bios|efi> <iso-windows> [porta]
set -uo pipefail
modo=$1; iso=$2; porta=${3:-2323}
VBM="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
vm=ianinja-teste-$modo
P=//wsl.localhost/Ubuntu-24.04/root/ianinjapelagestao
"$VBM" controlvm $vm poweroff >/dev/null 2>&1; sleep 2
"$VBM" unregistervm $vm --delete >/dev/null 2>&1
"$VBM" createvm --name $vm --ostype Linux_64 --register >/dev/null || exit 1
"$VBM" modifyvm $vm --memory 4096 --cpus 4 --firmware $modo --nic1 nat --audio-enabled off \
  --uart1 0x3F8 4 --uart-mode1 tcpserver $porta --boot1 dvd --boot2 none --boot3 none --boot4 none --graphicscontroller vmsvga --vram 128 || exit 1
"$VBM" storagectl $vm --name SATA --add sata --portcount 1 || exit 1
"$VBM" storageattach $vm --storagectl SATA --port 0 --device 0 --type dvddrive --medium "$(cygpath -w "$iso")" || exit 1
# assistente de 1.º arranque (bloco 09) desligado, como no QEMU (-smbios type=11): a 1.ª cadeia OEM
# do SMBIOS tipo 11 do VirtualBox (por omissão "vboxVer_<versão>") passa a "ianinja.assistente=0",
# que o contas.py procura em /sys/firmware/dmi/entries/11-*/raw. Firmware bios -> pcbios, efi -> efi.
dmi=pcbios; [ "$modo" = efi ] && dmi=efi
"$VBM" setextradata $vm "VBoxInternal/Devices/$dmi/0/Config/DmiOEMVBoxVer" "ianinja.assistente=0" || exit 1
"$VBM" startvm $vm --type headless || exit 1
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- expect /root/ianinjapelagestao/scripts/teste-vbox.exp $porta \
  /root/ianinjapelagestao/logs/vbox-teste-$modo.log /root/ianinjapelagestao/logs/vbox-resultado-$modo.txt
rc=$?
"$VBM" controlvm $vm screenshotpng "$(cygpath -w /c/Users/User/Documents/ianinjapelagestao_iso/vbox/ecra-$modo.png)" >/dev/null 2>&1
sleep 5
"$VBM" controlvm $vm poweroff >/dev/null 2>&1; sleep 3
"$VBM" unregistervm $vm --delete >/dev/null 2>&1
cat $P/logs/vbox-resultado-$modo.txt
exit $rc
