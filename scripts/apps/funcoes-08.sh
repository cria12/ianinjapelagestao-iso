# F8e — funções do bloco 8 (rede): wpa_supplicant com D-Bus, configuração do NetworkManager e
# verificação. Lido por scripts/f08e-apps.sh. Correm sob corre_passo (sem errexit): cada comando
# termina com || return 1. Ver scripts/apps/decisoes-08.txt.

REDE_D=$P/scripts/apps/rede
REDE_KV=6.16.1

# rede_fontes — o URL do newt no livro (releases.pagure.org) responde 404 desde 2026; o mesmo
# tarball existe no espelho do BLFS (anduin.linuxfromscratch.org). Descarrega-se de lá com o
# SHA-256 fixado (calculado em 2026-11-12; o MD5 coincide com o do livro), e o "pacote general/newt"
# encontra-o já em /sources e volta a confirmar o MD5 do livro.
rede_fontes() {
  baixar https://anduin.linuxfromscratch.org/BLFS/newt/newt-0.52.25.tar.gz newt-0.52.25.tar.gz \
    ef0ca9ee27850d1a5c863bb7ff9aa08096c9ed312ece9087b30f3a426828de82 || return 1
  echo "cca66ed1d8774fb9e3f6a33525de416d  $LFS/sources/newt-0.52.25.tar.gz" | md5sum -c || return 1
}

# rede_wpa_supplicant_dbus — a F8c compilou o wpa_supplicant sem D-Bus (blocos 2 e 5 da página
# omitidos em scripts/book-overrides.txt), mas o NetworkManager só fala com ele por D-Bus
# (fi.w1.wpa_supplicant1, ativado a pedido pelo dbus-daemon). Os overrides são por página e os
# da F8c não se mudam, por isso (como no mesa-vulkan do bloco 3) gera-se uma cópia do script da
# página com os blocos 2 e 5 ativos e sem os blocos 6 a 10 (o serviço "wpa" e o ifconfig.wlan0
# já foram instalados pela F8c), corrida com o run-blfs.sh e o mesmo tarball (MD5 do livro).
rede_wpa_supplicant_dbus() {
  local tb g=$LFS/sources/ianinja/gen/blfs/basicnet/wpa_supplicant-dbus.sh
  $FETCH fetch $BLFS $LFS/sources basicnet/wpa_supplicant || return 1
  tb=$($FETCH tarball $BLFS basicnet/wpa_supplicant) || return 1
  python3 $S/gen-scripts.py blfs $BLFS basicnet/wpa_supplicant > /dev/null || return 1
  mkdir -p $(dirname $g) || return 1
  python3 -I - $S/gen/blfs/basicnet/wpa_supplicant.sh $g <<'PYEOF' || return 1
import re, sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
partes = re.split(r"(?m)^(?=# --- bloco \d+)", t)
out = [partes[0]]
for p in partes[1:]:
    n = int(re.match(r"# --- bloco (\d+)", p).group(1))
    if n in (2, 5):
        linhas = p.splitlines()
        corpo = [re.sub(r"^#   ?", "", l) for l in linhas[1:] if l.startswith("#")]
        out.append("# --- bloco %d (ativado pela F8e: interface D-Bus para o NetworkManager)\n" % n
                   + "echo '>>> bloco %d'\n" % n + "\n".join(corpo).rstrip() + "\n\n")
    elif n <= 4:
        out.append(p)
s = "".join(out)
for obrig in ("CONFIG_CTRL_IFACE_DBUS_NEW=y", "fi.w1.wpa_supplicant1.service",
              "dbus-wpa_supplicant.conf", "make BINDIR=/usr/sbin"):
    if obrig not in s:
        sys.exit("falta '%s' no script gerado" % obrig)
if "install-service-wpa" in s or "ifconfig.wlan0" in s:
    sys.exit("os blocos 7/8 não deviam estar no script")
open(dst, "w", encoding="utf-8").write(s)
print(s)
PYEOF
  in_chroot "bash /sources/ianinja/run-blfs.sh basicnet/wpa_supplicant-dbus $tb" || return 1
  in_chroot "set -e
    ldd /usr/sbin/wpa_supplicant | grep -q libdbus-1
    grep -q '^Exec=/usr/sbin/wpa_supplicant -u' /usr/share/dbus-1/system-services/fi.w1.wpa_supplicant1.service
    test -f /etc/dbus-1/system.d/wpa_supplicant.conf
    wpa_supplicant -h 2>&1 | grep -q -- '-u = enable DBus'
    echo 'wpa_supplicant com D-Bus: OK'" || return 1
}

# rede_configurar — o NetworkManager passa a gerir todas as placas:
#  - tiram-se os links [SK]NNnetwork de rc0-6 (o livro: "remove S20network"); o script
#    /etc/rc.d/init.d/network e os /etc/sysconfig/ifconfig.* ficam, com ONBOOT="no" e um aviso;
#  - /etc/NetworkManager/conf.d/50-ianinja.conf (resolv.conf, MAC na procura, poupança de energia);
#  - ligar-wifi passa a usar o nmcli (mesmas opções; sem argumentos abre o nmtui-connect);
#  - regra udev que ejeta o "CD do driver" dos adaptadores Wi-Fi USB Realtek (0bda:1a2b);
#  - info-hardware (bloco 3) reinstalado com a secção de rede nova (USB/PCI, driver, firmware).
rede_configurar() {
  local f
  [ -x $LFS/etc/rc.d/init.d/networkmanager ] || { echo "falta /etc/rc.d/init.d/networkmanager (passo nm-bootscript)"; return 1; }
  rm -fv $LFS/etc/rc.d/rc[0-6S].d/[SK][0-9][0-9]network || return 1
  for f in $LFS/etc/sysconfig/ifconfig.*; do
    [ -f "$f" ] || continue
    grep -q 'NetworkManager' "$f" || sed -i '1i # ianinjapelagestao: as placas de rede são geridas pelo NetworkManager (F8e, bloco 8); este\n# ficheiro do bootscript network do LFS já não é usado no arranque (links S20network retirados).' "$f" || return 1
    sed -i 's/^ONBOOT=.*/ONBOOT="no"/' "$f" || return 1
  done
  install -v -D -m644 $REDE_D/50-ianinja.conf $LFS/etc/NetworkManager/conf.d/50-ianinja.conf || return 1
  install -v -m755 $REDE_D/ligar-wifi $LFS/usr/bin/ligar-wifi || return 1
  install -v -m644 $REDE_D/70-ianinja-wifi-modo-cd.rules $LFS/usr/lib/udev/rules.d/ || return 1
  install -v -m755 $P/scripts/apps/drivers/info-hardware $LFS/usr/bin/info-hardware || return 1
  in_chroot "set -e
    bash -n /usr/bin/ligar-wifi; bash -n /usr/bin/info-hardware
    ligar-wifi -h > /dev/null
    info-hardware > /dev/null
    install -v -d -m700 /etc/NetworkManager/system-connections
    install -v -d -m755 /var/lib/NetworkManager
    id ninja | grep -q netdev
    udevadm verify /usr/lib/udev/rules.d/70-ianinja-wifi-modo-cd.rules 2> /dev/null || true" || return 1
}

# rede_verificar — no chroot, sem arrancar serviços (só comandos que terminam logo)
rede_verificar() {
  in_chroot "set -e
falha() { echo \"FALTA: \$*\"; exit 1; }
KV=$REDE_KV
for c in NetworkManager nmcli nmtui nmtui-connect nm-online nm-applet nm-connection-editor wpa_supplicant wpa_cli ligar-wifi info-hardware iw rfkill eject; do
  p=\$(type -P \$c) || falha \"programa \$c\"
  printf '%-22s %s\n' \$c \$p
done
for f in /usr/sbin/NetworkManager /usr/bin/nmcli /usr/bin/nmtui /usr/bin/nm-applet /usr/bin/nm-connection-editor \
         /usr/sbin/wpa_supplicant /usr/lib/libnm.so.0 /usr/lib/libnma.so.0 /usr/lib/libnewt.so.0.52 /usr/lib/libndp.so.0; do
  [ -e \$f ] || falha \$f
  ! ldd \$f | grep 'not found' || falha \"bibliotecas de \$f\"
done
for f in /etc/rc.d/init.d/networkmanager /etc/rc.d/rc3.d/S33networkmanager /etc/rc.d/rc5.d/S33networkmanager \
         /etc/rc.d/rc0.d/K28networkmanager /etc/rc.d/rc6.d/K28networkmanager /etc/rc.d/rc5.d/S29dbus \
         /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/conf.d/polkit.conf /etc/NetworkManager/conf.d/50-ianinja.conf \
         /usr/share/polkit-1/rules.d/org.freedesktop.NetworkManager.rules /usr/share/polkit-1/actions/org.freedesktop.NetworkManager.policy \
         /usr/share/dbus-1/system.d/org.freedesktop.NetworkManager.conf /usr/share/dbus-1/system-services/fi.w1.wpa_supplicant1.service \
         /etc/dbus-1/system.d/wpa_supplicant.conf /etc/xdg/autostart/nm-applet.desktop /usr/share/applications/nm-connection-editor.desktop \
         /usr/lib/udev/rules.d/85-nm-unmanaged.rules /usr/lib/udev/rules.d/70-ianinja-wifi-modo-cd.rules \
         /usr/lib/firmware/regulatory.db; do
  [ -e \$f ] || falha \$f
  echo \"ok \$f\"
done
if ls /etc/rc.d/rc?.d/ | grep -qx '[SK][0-9][0-9]network'; then falha 'ainda há links S/K network (lutariam com o NetworkManager)'; fi
grep -q '^auth-polkit=true' /etc/NetworkManager/conf.d/polkit.conf || falha 'auth-polkit'
NetworkManager --print-config > /tmp/nm-config.txt 2>&1 || { cat /tmp/nm-config.txt; falha 'NetworkManager --print-config'; }
for k in 'plugins=keyfile' 'rc-manager=file' 'wifi.powersave=2' 'wifi.scan-rand-mac-address=no'; do
  grep -q \"^\$k\" /tmp/nm-config.txt || { cat /tmp/nm-config.txt; falha \"configuração \$k\"; }
done
rm -f /tmp/nm-config.txt
nmcli --version
grep -q '^Exec=nm-applet' /etc/xdg/autostart/nm-applet.desktop || falha 'Exec do nm-applet'
! grep -q '^Hidden=true' /etc/xdg/autostart/nm-applet.desktop || falha 'nm-applet escondido no autostart'
desktop-file-validate /etc/xdg/autostart/nm-applet.desktop || true
if type -P node > /dev/null; then
  node -e 'new Function(require(\"fs\").readFileSync(process.argv[1], \"utf8\"))' /usr/share/polkit-1/rules.d/org.freedesktop.NetworkManager.rules || falha 'sintaxe da regra polkit'
fi
grep -q 'isInGroup(\"netdev\")' /usr/share/polkit-1/rules.d/org.freedesktop.NetworkManager.rules || falha 'regra netdev'
id ninja | grep -q '(netdev)' || falha 'ninja no grupo netdev'
ldd /usr/sbin/wpa_supplicant | grep -q libdbus-1 || falha 'wpa_supplicant sem D-Bus'
ligar-wifi -h > /dev/null
# drivers Wi-Fi/rede USB do kernel (módulos .ko.zst) e firmware (.xz) dos mais comuns
for m in cfg80211 mac80211 rtw88_usb rtw88_8821au rtw88_8812au rtw88_8814au rtw88_8821cu rtw88_8822bu rtw88_8822cu rtw88_8723du \
         rtl8xxxu rtl8192cu mt7601u mt76x0u mt76x2u mt7663u mt7921u mt7925u ath9k_htc carl9170 rt2800usb rt73usb brcmfmac ath10k_usb \
         ath6kl_usb zd1211rw mwifiex_usb iwlwifi rtw89_pci r8152 ax88179_178a cdc_ether cdc_ncm rndis_host; do
  modinfo -k \$KV -F filename \$m > /dev/null 2>&1 || falha \"módulo \$m\"
done
echo 'módulos Wi-Fi/rede USB: ok'
for m in rtw88_8821a rtw88_8812a rtw88_8814a rtw88_8821c rtw88_8822b rtw88_8822c rtw88_8723d rtl8xxxu rtl8192cu mt7601u mt76x0u mt76x2u \
         mt7921u mt7925u ath9k_htc carl9170 rt2800usb r8152; do
  n=0; ok=0
  for f in \$(modinfo -k \$KV -F firmware \$m); do
    n=\$((n+1)); { [ -e /usr/lib/firmware/\$f.xz ] || [ -e /usr/lib/firmware/\$f ]; } && ok=\$((ok+1))
  done
  echo \"firmware \$m: \$ok/\$n\"
  [ \$ok -gt 0 ] || falha \"firmware de \$m\"
done
# ids USB populares -> driver (modules.alias do depmod)
for a in 0BDA:8812:rtw88_8812au 0BDA:A811:rtw88_8821au 0BDA:8813:rtw88_8814au 0BDA:C811:rtw88_8821cu 0BDA:B812:rtw88_8822bu \
         0BDA:C812:rtw88_8822cu 0BDA:D723:rtw88_8723du 0BDA:8179:rtl8xxxu 2357:010C:rtl8xxxu 148F:7601:mt7601u 0E8D:7612:mt76x2u \
         0E8D:7961:mt7921u 0E8D:7925:mt7925u 0CF3:9271:ath9k_htc 148F:5370:rt2800usb; do
  IFS=: read -r v p m <<< \"\$a\"
  modprobe -S \$KV -R \"usb:v\${v}p\${p}d0000dc00dsc00dp00icFFiscFFipFFin00\" 2> /dev/null | grep -qx \$m || falha \"alias \$v:\$p -> \$m\"
done
echo 'aliases USB: ok'
echo 'rede: verificação OK'" || return 1
}
