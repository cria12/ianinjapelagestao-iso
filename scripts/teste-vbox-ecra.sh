#!/bin/bash
# senhas das contas live: scripts/senhas.local (fora do Git)
. "$(dirname "$0")/senhas.local" || { echo "falta scripts/senhas.local"; exit 1; }
# Corre no Git Bash do Windows: teste no VirtualBox pelo ecrã (teclado virtual + capturas), como um utilizador.
# Uso: teste-vbox-ecra.sh <bios|efi> <iso> <dir-capturas>
# Com a interface gráfica (F8d) o sistema arranca no nível 5: o LightDM mostra o ecrã de início de
# sessão (lightdm-gtk-greeter) no vt7. Captura-se o greeter, entra-se como ninja, captura-se o
# ambiente Xfce, a pesquisa (Super+Espaço) e um terminal; depois passa-se à consola de texto
# (Ctrl+Alt+F1) para os testes de sempre (sistema, rede, IA, chat do ninja, sudo) e volta-se ao ecrã
# gráfico (Ctrl+Alt+F7) antes de desligar.
# Placa gráfica VMSVGA (driver vmwgfx do kernel, módulo; Mesa svga com 3D ou llvmpipe sem 3D).
# 3D opcional: VBOX_3D=1 teste-vbox-ecra.sh ...  (--accelerate-3d on; por omissão desligado)
set -uo pipefail
modo=$1; iso=$2; out=$3
VBM="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
vm=ianinja-ecra-$modo
mkdir -p "$out"
cap() { "$VBM" controlvm $vm screenshotpng "$(cygpath -w "$out/$modo-$1.png")" >/dev/null 2>&1; echo "captura $modo-$1 ($(date +%T))"; }
esc() { MSYS_NO_PATHCONV=1 "$VBM" controlvm $vm keyboardputstring "$1" >/dev/null; }
tecla() { "$VBM" controlvm $vm keyboardputscancode "$@" >/dev/null; }   # códigos PC/AT (set 1)
enter() { tecla 1c 9c; }
linha() { esc "$1"; enter; }
# combinações (carregar ... soltar pela ordem inversa)
ctrl_alt_f1() { tecla 1d 38 3b bb b8 9d; }    # consola de texto tty1
ctrl_alt_f7() { tecla 1d 38 41 c1 b8 9d; }    # de volta ao ecrã gráfico (vt7)
alt_f1()      { tecla 38 3b bb b8; }          # entre consolas de texto
alt_f2()      { tecla 38 3c bc b8; }
super_espaco() { tecla e0 5b 39 b9 e0 db; }   # Super (Windows esquerda) + Espaço: pesquisa rápida
ctrl_alt_t()  { tecla 1d 38 14 94 b8 9d; }    # terminal (atalho por omissão do Xfce)
escape()      { tecla 01 81; }
d3=off; [ "${VBOX_3D:-0}" = 1 ] && d3=on
"$VBM" controlvm $vm poweroff >/dev/null 2>&1; sleep 2; "$VBM" unregistervm $vm --delete >/dev/null 2>&1
"$VBM" createvm --name $vm --ostype Linux_64 --register >/dev/null || exit 1
"$VBM" modifyvm $vm --memory 4096 --cpus 4 --firmware $modo --nic1 nat --audio-enabled off \
  --boot1 dvd --boot2 none --boot3 none --boot4 none --graphicscontroller vmsvga --vram 128 \
  --accelerate-3d $d3 --mouse usbtablet || exit 1
"$VBM" storagectl $vm --name SATA --add sata --portcount 1 || exit 1
"$VBM" storageattach $vm --storagectl SATA --port 0 --device 0 --type dvddrive --medium "$(cygpath -w "$iso")" || exit 1
# assistente de 1.º arranque (bloco 09) desligado (este teste entra pelo lightdm-gtk-greeter como
# ninja): a 1.ª cadeia OEM do SMBIOS tipo 11 (por omissão "vboxVer_<versão>") passa a
# "ianinja.assistente=0", lida pelo contas.py em /sys/firmware/dmi/entries/11-*/raw.
# Para ver o assistente: VBOX_ASSISTENTE=1 teste-vbox-ecra.sh ...
if [ "${VBOX_ASSISTENTE:-0}" != 1 ]; then
  dmi=pcbios; [ "$modo" = efi ] && dmi=efi
  "$VBM" setextradata $vm "VBoxInternal/Devices/$dmi/0/Config/DmiOEMVBoxVer" "ianinja.assistente=0" || exit 1
fi
"$VBM" startvm $vm --type headless || exit 1
# o GRUB espera 5 s (timeout=5): capturar logo, antes de arrancar o kernel
sleep 4; cap 01-grub
# entrada por omissão do GRUB (com interface gráfica): o LightDM aparece depois do arranque completo
sleep 154; cap 02-greeter
# ecrã de início de sessão: o greeter lista os utilizadores com UID >= 1000 (só o ninja; o root não
# aparece) e põe o cursor na senha. Letras iguais em pt e us, por isso o teclado pt do X não atrapalha.
linha "$SENHA_NINJA"; sleep 60; cap 03-ambiente
super_espaco; sleep 6; cap 04-pesquisa; escape; sleep 2
ctrl_alt_t; sleep 12
# no X o teclado é pt; o keyboardputstring envia teclas US: só letras e espaços até ao setxkbmap us
linha "setxkbmap us"; sleep 2
linha "clear; grep PRETTY /etc/os-release; uname -r; xrandr | head -n 3; free -m | head -n 2"; sleep 5; cap 05-terminal
linha "exit"; sleep 3
# consola de texto (o agetty de tty1 continua ativo no nível 5)
ctrl_alt_f1; sleep 5; cap 06-consola
linha root; sleep 4; linha "$SENHA_ROOT"; sleep 6
# o teclado da consola é pt-latin1; o keyboardputstring do VirtualBox envia códigos de tecla US
linha "loadkeys us"; sleep 3
linha "clear; grep PRETTY /etc/os-release; uname -r; ip -4 -br addr; grep zram /proc/swaps; free -m | head -2; runlevel; pidof lightdm Xorg lightdm-gtk-greeter; grep -c 'Fatal server error' /var/log/Xorg.0.log"; sleep 5; cap 07-sistema
linha "clear; wget -q --spider https://www.linuxfromscratch.org && echo REDE_OK || echo REDE_FALHOU; lspci | head -12"; sleep 15; cap 08-rede
linha "clear; time ia-perguntar 'Qual e a capital de Portugal? Responde numa frase.'"; sleep 150; cap 09-ia
# chat que arranca sozinho para o ninja: consola 2 (Alt+F2)
alt_f2; sleep 4
linha ninja; sleep 4; linha ninja; sleep 40; cap 10-chat-ninja
linha "Diz ola em uma frase."; sleep 120; cap 11-chat-resposta
linha "/sair"; sleep 5; linha "loadkeys us 2>/dev/null; sudo -n true && echo SUDO_OK"; sleep 5; cap 12-sudo
# de volta ao ecrã gráfico (a sessão do ninja continua aberta)
ctrl_alt_f7; sleep 6; cap 13-volta-grafico
# desligar a partir da consola do root
ctrl_alt_f1; sleep 3
linha "poweroff"; sleep 60
st=$("$VBM" showvminfo $vm --machinereadable | grep '^VMState=')
echo "estado final: $st"
"$VBM" controlvm $vm poweroff >/dev/null 2>&1; sleep 3
"$VBM" unregistervm $vm --delete >/dev/null 2>&1
