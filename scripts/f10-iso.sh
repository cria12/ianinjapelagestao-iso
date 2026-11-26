#!/bin/bash
# F10 — Geração da ISO híbrida (BIOS + UEFI) com grub-mkrescue/xorriso
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F10)" = ok ] && exit 0
etapa_inicio F10
ISO=$P/output/ianinjapelagestao-12.4-x86_64.iso
for f in boot/vmlinuz boot/initrd.img live/rootfs.squashfs; do
  [ -s $P/iso-root/$f ] || { etapa_fim F10 falhou "falta iso-root/$f"; exit 1; }
done

# zswap.enabled=0 (bloco 10, scripts/apps/decisoes-10.txt): a swap é a zram (já comprimida em RAM);
# o zswap (ligado por omissão no kernel) comprimia as mesmas páginas duas vezes e reservava RAM.

cat > $P/iso-root/boot/grub/grub.cfg << "EOF"
serial --unit=0 --speed=115200
terminal_input console serial
terminal_output console serial

set default=0
set timeout=5
menuentry "ianinjapelagestao 12.4 (Live)" {
    linux /boot/vmlinuz quiet net.ifnames=0 zswap.enabled=0 console=ttyS0,115200 console=tty0
    initrd /boot/initrd.img
}
menuentry "ianinjapelagestao 12.4 (Live - modo gráfico de compatibilidade)" {
    # nomodeset: sem drivers DRM nativos; o simpledrm usa a imagem que o firmware/GRUB deixou
    # (GOP no UEFI; no BIOS o GRUB liga um modo VESA, senão o kernel ficava em modo de texto VGA)
    insmod all_video
    if [ "$grub_platform" = "pc" ]; then set gfxpayload=1024x768x32,1024x768,auto; else set gfxpayload=keep; fi
    linux /boot/vmlinuz net.ifnames=0 zswap.enabled=0 nomodeset console=ttyS0,115200 console=tty0
    initrd /boot/initrd.img
}
menuentry "ianinjapelagestao 12.4 (Live - modo texto, sem interface gráfica)" {
    linux /boot/vmlinuz quiet net.ifnames=0 zswap.enabled=0 console=ttyS0,115200 console=tty0 3
    initrd /boot/initrd.img
}
menuentry "ianinjapelagestao 12.4 (Live - modo seguro/verbose)" {
    linux /boot/vmlinuz net.ifnames=0 zswap.enabled=0 nomodeset console=ttyS0,115200 console=tty0 3
    initrd /boot/initrd.img
}
menuentry "ianinjapelagestao (sem persistência)" {
    linux /boot/vmlinuz quiet net.ifnames=0 zswap.enabled=0 persistencia=nao console=ttyS0,115200 console=tty0
    initrd /boot/initrd.img
}
EOF
decisao "GRUB: ecrã como consola principal (tty0 por último)" \
"Em todas as entradas a ordem passou a 'console=ttyS0,115200 console=tty0'. O kernel escreve as suas mensagens em todas as consolas, mas o /dev/console (stdin/stdout do /init do initramfs, dos bootscripts e da shell de emergência) é a ÚLTIMA console=; antes era a ttyS0, e num PC real qualquer falha do initramfs ou mensagem dos bootscripts ia para a porta série e o ecrã ficava preto. Agora vai para o ecrã; o /init escreve também na ttyS0 (função diz do scripts/live-init.sh), por isso os testes F11 continuam a ver 'persistência: ...', 'raiz overlay pronta' e 'FALHA NO ARRANQUE LIVE' na série; o banner e o login: da série vêm do agetty da ttyS0 (inittab), que não depende do /dev/console. O 'quiet' fica na entrada principal: só esconde as mensagens informativas do kernel (os erros do kernel continuam a aparecer); as mensagens do /init (a procurar o volume, progresso a cada 5 s, persistência, raiz pronta) e os [ OK ] dos bootscripts do LFS aparecem sempre no ecrã, por isso o arranque mostra progresso em vez de um ecrã preto, sem centenas de linhas do kernel; para ver tudo há as entradas sem quiet (compatibilidade e modo seguro)."

decisao "GRUB: modo gráfico de compatibilidade (nomodeset)" \
"Nova entrada (a 2.ª) 'ianinjapelagestao 12.4 (Live - modo gráfico de compatibilidade)', para PCs em que o driver DRM nativo da placa (nouveau em NVIDIA recentes com GSP, i915/xe, amdgpu sem firmware certo...) deixa o ecrã preto: 'nomodeset' (sem ' 3', arranca com interface gráfica e sem quiet). Com nomodeset o kernel 6.16 não carrega os drivers DRM nativos (incluindo o nouveau, por isso não é preciso nouveau.modeset=0) mas mantém os de firmware: CONFIG_SYSFB_SIMPLEFB=y faz do framebuffer do firmware um simple-framebuffer e CONFIG_DRM_SIMPLEDRM=y dá-lhe um /dev/dri/card0, onde o Xorg com o driver modesetting funciona (sem aceleração; o Mesa usa o llvmpipe). CONFIG_DRM_EFIDRM e CONFIG_DRM_VESADRM (novos no 6.16) não estão ligados; não fazem falta porque o simpledrm cobre os formatos comuns (XRGB8888, RGB565, RGB888) do GOP e do VESA, e ligá-los obrigaria a recompilar o kernel (F7) e tudo o que depende dele — fica como melhoria possível; se o formato não for suportado o kernel usa o efifb/vesafb (=y) e há consola de texto e o aviso do ianinja-dm. No UEFI o GOP já é um framebuffer (gfxpayload=keep); no BIOS o GRUB arrancaria o kernel em modo de texto VGA (sem framebuffer, o Xorg falhava — era por isso que o modo seguro tinha ' 3'), por isso a entrada faz insmod all_video e set gfxpayload=1024x768x32,1024x768,auto, e o kernel recebe um modo VESA linear. O título não contém '(Live)', que os testes F11 procuram para a entrada 0."
decisao "GRUB também na consola série" \
"Ao grub.cfg da Secção F10 foram acrescentadas 3 linhas (serial --unit=0 --speed=115200; terminal_input/terminal_output console serial) para o menu aparecer tanto no ecrã como em ttyS0 — necessário para os testes automáticos headless (F11) verificarem o menu. As entradas de menu são exatamente as do prompt."

decisao "GRUB: entrada sem persistência" \
"Acrescentada a entrada 'ianinjapelagestao (sem persistência)' (a última do menu) (igual à 1.ª mais persistencia=nao): arranca com camada de escrita em tmpfs mesmo que exista um disco IANINJA-DADOS — útil para testar sem tocar nos dados ou para recuperar de uma camada de escrita estragada. As duas entradas originais e as linhas da consola série ficam iguais; a entrada por omissão continua a ser a 0 ('ianinjapelagestao 12.4 (Live)'), que é a que os testes F11 esperam ver e arrancam por timeout (com persistência automática se houver disco de dados)."

decisao "GRUB: modo texto e modo seguro sem interface gráfica" \
"Com a interface gráfica (F8d) o /etc/inittab arranca no nível 5 (LightDM no vt7). Acrescentou-se ao grub.cfg (o mesmo ficheiro serve o arranque BIOS e o UEFI do grub-mkrescue) a entrada 'ianinjapelagestao 12.4 (Live - modo texto, sem interface gráfica)', igual à normal mais ' 3' no fim da linha do kernel: o kernel não reconhece o '3' e passa-o como argumento ao /init do initramfs, que o entrega ao /sbin/init no switch_root (\"\$@\"), e o SysVinit arranca no nível 3 (só consolas de texto, sem LightDM). A entrada 'modo seguro/verbose' também passou a ter ' 3': com nomodeset os drivers DRM nativos (bochs, virtio-gpu, vmwgfx, i915, amdgpu...) não carregam, o Xorg com o driver modesetting não encontra um ecrã utilizável e o LightDM ficaria a reiniciar o X em ciclo. A entrada por omissão continua a ser a 0 ('ianinjapelagestao 12.4 (Live)', agora com interface gráfica), cujo texto exato os testes F11 procuram; os títulos novos não contêm a cadeia '(Live)' e por isso não a confundem. A entrada 'sem persistência' arranca com interface gráfica, como a normal."

mkiso() {
  local sq extra=""
  mkdir -p $P/output
  rm -f $ISO $ISO.sha256
  # um ficheiro >= 4 GiB numa ISO9660 exige o nível 3 (vários extents); só se usa quando é preciso
  sq=$(stat -c %s $P/iso-root/live/rootfs.squashfs)
  if [ "$sq" -ge 4294967296 ]; then extra="-iso-level 3"; echo "rootfs.squashfs com $sq bytes: ISO9660 nível 3"; fi
  grub-mkrescue -o $ISO $P/iso-root -- -volid IANINJAPELAGESTAO $extra
  cd $P/output && sha256sum $(basename $ISO) > $(basename $ISO).sha256
  xorriso -indev $ISO -pvd_info 2>/dev/null | grep -i 'Volume Id'
}
NO_RETRY=1 corre_passo f10-iso-$(date +%s) $P/logs/f10-iso.log mkiso
grep -q IANINJAPELAGESTAO $P/logs/f10-iso.log || { etapa_fim F10 falhou "rótulo do volume incorreto"; exit 1; }
etapa_fim F10 ok "ISO $(du -h $ISO | cut -f1), sha256 $(cut -c1-16 $ISO.sha256)…"
