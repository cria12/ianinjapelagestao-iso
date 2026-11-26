# F8e — funções do bloco 3 (drivers e periféricos): headers do kernel para módulos externos,
# Mesa com Vulkan, vulkaninfo, comando instalar-driver-nvidia, OpenRazer, hidapi + HeadsetControl,
# Blueman, xfce4-screenshooter, info-hardware. Lido por scripts/f08e-apps.sh.
# Correm sob corre_passo (sem errexit): cada comando termina com || return 1. Ver decisoes-03.txt.

DRV_KV=6.16.1
DRV_D=$P/scripts/apps/drivers
# Downloads fora do livro: "ficheiro|url|sha256" (SHA-256 calculado na descarga de 2026-11-06)
DRV_FONTES=(
  "openrazer-3.12.4.tar.gz|https://github.com/openrazer/openrazer/archive/v3.12.4/openrazer-3.12.4.tar.gz|99a79465f0501102be47c9ad46ae2df3588f642b4394aef79f96176d74239d1c"
  "pyudev-0.24.5-py3-none-any.whl|https://files.pythonhosted.org/packages/5f/56/0baea14a1c772ce3df2c5d3a57802b31bcdee555f11dc8d18d23a927d14f/pyudev-0.24.5-py3-none-any.whl|a9c62d04a83472fb05ad5e014ef85933e5cf2fef193caf8b77bb7a9e8ded4812"
  "daemonize-2.5.0-py2.py3-none-any.whl|https://files.pythonhosted.org/packages/45/ad/1b20db02287afd40d3130a218ac5ce2f7d2ab581cfda29bada5e1c4bee17/daemonize-2.5.0-py2.py3-none-any.whl|9b6b91311a9d934ff3f5f766666635ca280d3de8e7137e4cd7d3f052543b989f"
  "setproctitle-1.3.8.tar.gz|https://files.pythonhosted.org/packages/49/b0/6b8a516c5a9e9630bd5293db78314ac012f690305fe93beadea388626efb/setproctitle-1.3.8.tar.gz|cafe209d064a6efb88cb45a03e97981ff8832802b2b5d009dde0197a3b7b41c8"
  "hidapi-0.15.0.tar.gz|https://github.com/libusb/hidapi/archive/hidapi-0.15.0/hidapi-0.15.0.tar.gz|5d84dec684c27b97b921d2f3b73218cb773cf4ea915caee317ac8fc73cef8136"
  "HeadsetControl-4.2.0.tar.gz|https://github.com/Sapd/HeadsetControl/archive/4.2.0/HeadsetControl-4.2.0.tar.gz|74c86457c51ffb325353ef6e708b47584db99193c1625bef960ae99c68b0b76c"
  "Vulkan-Tools-1.4.321.tar.gz|https://github.com/KhronosGroup/Vulkan-Tools/archive/v1.4.321/Vulkan-Tools-1.4.321.tar.gz|f5f75413d21d1508b746a3d0594961d64c7155ee5f4f28245b9547c1b4697d8d"
  "blueman-2.4.6.tar.xz|https://github.com/blueman-project/blueman/releases/download/2.4.6/blueman-2.4.6.tar.xz|c712a737f9855906684c074d166d4f10c7f165378af96612818bbffcfbf8e566"
  "xfce4-screenshooter-1.11.3.tar.xz|https://archive.xfce.org/src/apps/xfce4-screenshooter/1.11/xfce4-screenshooter-1.11.3.tar.xz|1f6a14f7d1b0c440f31e24a8cc4fe2996185357fa786f0c2cdfe564ef673a710"
)

drivers_fontes() {
  local l f u s
  for l in "${DRV_FONTES[@]}"; do
    IFS='|' read -r f u s <<< "$l"
    baixar "$u" "$f" "$s" || return 1
  done
}

# drivers_kernel_headers — a F7 apaga as fontes do kernel e o link /lib/modules/$KV/build; para
# compilar módulos externos (OpenRazer aqui; NVIDIA no 1.º uso) recompila-se o MESMO kernel 6.16.1
# com a MESMA configuração (/boot/config-6.16.1; confirma-se que o olddefconfig não muda nada) só
# para obter o Module.symvers e os ficheiros gerados, e instala-se a árvore mínima de headers (a
# lista do pacote linux-headers do Arch) em /usr/src/linux-headers-6.16.1, com o link build.
# Não se instala nada do kernel recompilado (bzImage e módulos ficam os da F7).
drivers_kernel_headers() {
  [ -f $LFS/boot/config-$DRV_KV ] || { echo "falta /boot/config-$DRV_KV (F7)"; return 1; }
  [ -f $LFS/sources/linux-$DRV_KV.tar.xz ] || { echo "falta /sources/linux-$DRV_KV.tar.xz"; return 1; }
  in_chroot "set -e
KV=$DRV_KV; H=/usr/src/linux-headers-\$KV
cd /sources; rm -rf linux-\$KV; tar -xf linux-\$KV.tar.xz; cd linux-\$KV
make mrproper
cp -v /boot/config-\$KV .config
make olddefconfig
diff <(grep '^CONFIG_' /boot/config-\$KV) <(grep '^CONFIG_' .config)
make
test -s Module.symvers
[ \"\$(cat include/config/kernel.release)\" = \"\$KV\" ]
rm -rf \$H; install -d \$H
install -Dt \$H -m644 .config Makefile Module.symvers System.map
install -Dt \$H/kernel -m644 kernel/Makefile
install -Dt \$H/arch/x86 -m644 arch/x86/Makefile
cp -a scripts \$H/
install -Dt \$H/tools/objtool tools/objtool/objtool
cp -a include \$H/
cp -a arch/x86/include \$H/arch/x86/
install -Dt \$H/arch/x86/kernel -m644 arch/x86/kernel/asm-offsets.s
install -Dt \$H/drivers/md -m644 drivers/md/*.h
install -Dt \$H/net/mac80211 -m644 net/mac80211/*.h
install -Dt \$H/drivers/media/i2c -m644 drivers/media/i2c/msp3400-driver.h
install -Dt \$H/drivers/media/usb/dvb-usb -m644 drivers/media/usb/dvb-usb/*.h
install -Dt \$H/drivers/media/dvb-frontends -m644 drivers/media/dvb-frontends/*.h
install -Dt \$H/drivers/media/tuners -m644 drivers/media/tuners/*.h
install -Dt \$H/drivers/iio/common/hid-sensors -m644 drivers/iio/common/hid-sensors/*.h
find . -name 'Kconfig*' -exec install -Dm644 {} \$H/{} \\;
find \$H -type f \\( -name '*.o' -o -name '.*.cmd' -o -name '*.a' \\) -delete
find -L \$H -type l -delete
rm -rf \$H/Documentation
find \$H/scripts \$H/tools -type f -perm -u+x | while read -r f; do
  head -c4 \"\$f\" | grep -q ELF && strip --strip-unneeded \"\$f\" || true
done
chown -R root:root \$H
ln -sfnv \$H /lib/modules/\$KV/build
cd /sources; rm -rf linux-\$KV
# teste: um módulo mínimo compila e fica com o vermagic do kernel instalado
rm -rf /tmp/teste-mod; mkdir /tmp/teste-mod; cd /tmp/teste-mod
printf '%s\n' '#include <linux/module.h>' 'MODULE_LICENSE(\"GPL\");' 'static int __init t_init(void) { return 0; }' 'module_init(t_init);' > t.c
echo 'obj-m := t.o' > Kbuild
make -C /lib/modules/\$KV/build M=\$PWD modules
a=\$(modinfo -F vermagic t.ko); b=\$(modinfo -k \$KV -F vermagic nouveau)
echo \"vermagic teste: \$a | nouveau: \$b\"
[ \"\$a\" = \"\$b\" ]
cd /; rm -rf /tmp/teste-mod
echo \"HEADERS_TAMANHO:\$(du -sh \$H | cut -f1)\"" || return 1
}

# drivers_mesa_vulkan — reinstala o Mesa 25.1.8 da F8d com os drivers Vulkan (anv, hasvk, radv,
# lavapipe) e a camada device-select. Os overrides são por página (x/mesa já tem o replace da F8d),
# por isso gera-se uma cópia do script da página (x/mesa-vulkan.sh) com só a opção vulkan-drivers
# trocada, e corre-se com o run-blfs.sh e o mesmo tarball/patch (verificados pelo MD5 do livro).
drivers_mesa_vulkan() {
  local tb g=$LFS/sources/ianinja/gen/blfs/x/mesa-vulkan.sh
  $FETCH fetch $BLFS $LFS/sources x/mesa --extra mesa-add_xdemos-4 || return 1
  tb=$($FETCH tarball $BLFS x/mesa) || return 1
  python3 $S/gen-scripts.py blfs $BLFS x/mesa > /dev/null || return 1
  mkdir -p $(dirname $g) || return 1
  sed 's|-D vulkan-drivers=""|-D vulkan-drivers=intel,intel_hasvk,amd,swrast -D vulkan-layers=device-select|' \
    $S/gen/blfs/x/mesa.sh > $g || return 1
  grep -q 'vulkan-drivers=intel,intel_hasvk,amd,swrast' $g || { echo "opção vulkan-drivers não encontrada em gen/blfs/x/mesa.sh"; return 1; }
  in_chroot "bash /sources/ianinja/run-blfs.sh x/mesa-vulkan $tb" || return 1
  in_chroot "set -e
    for f in intel intel_hasvk radeon lvp; do ls -l /usr/share/vulkan/icd.d/\${f}_icd.x86_64.json; done
    ls /usr/share/vulkan/implicit_layer.d/
    ls -l /usr/lib/libvulkan_intel.so /usr/lib/libvulkan_radeon.so /usr/lib/libvulkan_lvp.so
    ldconfig" || return 1
}

# vulkaninfo (Vulkan-Tools; não está no BLFS): só o vulkaninfo, sem vkcube nem ICD de teste
drivers_vulkan_tools() {
  in_chroot "set -e
cd /sources; rm -rf Vulkan-Tools-1.4.321; tar -xf Vulkan-Tools-1.4.321.tar.gz; cd Vulkan-Tools-1.4.321
w=OFF; pkg-config --exists wayland-client && w=ON
cmake -B build -G Ninja -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release \
  -D BUILD_CUBE=OFF -D BUILD_ICD=OFF -D BUILD_TESTS=OFF -D BUILD_WSI_WAYLAND_SUPPORT=\$w
ninja -C build
ninja -C build install
cd /sources; rm -rf Vulkan-Tools-1.4.321
# teste sem GPU nem ecrã: o lavapipe (CPU) tem de aparecer
VK_DRIVER_FILES=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json vulkaninfo --summary 2> /dev/null | grep -i -E 'llvmpipe|deviceName' || echo 'AVISO-TESTE: vulkaninfo não listou o lavapipe no chroot'" || return 1
}

# instalar-driver-nvidia (a pedido) + regra udev que mostra o atalho só quando há placa NVIDIA
drivers_nvidia_comando() {
  local L=$LFS/usr/lib/instalar-driver-nvidia
  install -v -m755 $DRV_D/instalar-driver-nvidia $LFS/usr/bin/instalar-driver-nvidia || return 1
  install -v -d -m755 $L $LFS/usr/share/instalar-driver-nvidia || return 1
  install -v -m755 $DRV_D/trocar-driver $DRV_D/prime-saida $DRV_D/mostrar-atalho $L/ || return 1
  install -v -m644 $P/scripts/apps/raiz/usr/share/instalar-driver-nvidia/instalar-driver-nvidia.desktop \
    $LFS/usr/share/instalar-driver-nvidia/ || return 1
  install -v -m644 $DRV_D/90-ianinja-nvidia.rules $LFS/usr/lib/udev/rules.d/ || return 1
  rm -f $LFS/usr/share/applications/instalar-driver-nvidia.desktop   # só aparece com placa NVIDIA
  in_chroot "set -e
    for f in /usr/bin/instalar-driver-nvidia /usr/lib/instalar-driver-nvidia/*; do bash -n \$f; done
    desktop-file-validate /usr/share/instalar-driver-nvidia/instalar-driver-nvidia.desktop
    udevadm verify /usr/lib/udev/rules.d/90-ianinja-nvidia.rules 2> /dev/null || true
    instalar-driver-nvidia -h > /dev/null
    printf '%s\n' '0000:01:00.0 \"0300\" \"10de\" \"2684\" -ra1 \"1043\" \"88e2\"' > /tmp/lspci-teste
    IDN_LSPCI=/tmp/lspci-teste instalar-driver-nvidia -l | grep -q 'série 620'
    printf '%s\n' '0000:01:00.0 \"0300\" \"10de\" \"1b80\" -ra1 \"1043\" \"85aa\"' > /tmp/lspci-teste
    IDN_LSPCI=/tmp/lspci-teste instalar-driver-nvidia -l | grep -q 'série 580'
    rm -f /tmp/lspci-teste
    for c in gcc make ld curl sha256sum python3 modprobe depmod telinit setsid xrandr lspci; do
      type -P \$c > /dev/null || { echo \"falta \$c\"; exit 1; }
    done
    test -f /lib/modules/$DRV_KV/build/Makefile" || return 1
}

# OpenRazer: módulos do kernel (para o 6.16.1, em /lib/modules/6.16.1/extra), regras udev, grupo
# plugdev (o ninja entra nele) e o serviço Python (openrazer-daemon) com as dependências fora do
# BLFS em wheels fixadas (pyudev, daemonize) ou compiladas da fonte (setproctitle).
drivers_openrazer() {
  install -v -m755 $DRV_D/openrazer $LFS/usr/bin/openrazer || return 1
  install -v -m755 $DRV_D/openrazer-se-houver $LFS/usr/bin/openrazer-se-houver || return 1
  in_chroot "set -e
KV=$DRV_KV
pip3 install --no-index --no-deps --no-user /sources/pyudev-0.24.5-py3-none-any.whl /sources/daemonize-2.5.0-py2.py3-none-any.whl
cd /sources; rm -rf setproctitle-1.3.8; tar -xf setproctitle-1.3.8.tar.gz; cd setproctitle-1.3.8
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir \$PWD
pip3 install --no-index --no-deps --no-user dist/setproctitle-*.whl
cd /sources; rm -rf setproctitle-1.3.8 openrazer-3.12.4; tar -xf openrazer-3.12.4.tar.gz; cd openrazer-3.12.4
make -C /lib/modules/\$KV/build M=\$PWD/driver modules
make -C /lib/modules/\$KV/build M=\$PWD/driver INSTALL_MOD_STRIP=1 INSTALL_MOD_DIR=extra modules_install
depmod -a \$KV
make DESTDIR=/ UDEV_PREFIX=/usr udev_install
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir \$PWD/daemon \$PWD/pylib
pip3 install --no-index --no-deps --no-user --find-links dist openrazer_daemon openrazer
make -C daemon DESTDIR=/ PREFIX=/usr install-resources manpages service
install -v -Dm644 daemon/org.razer.service /usr/share/dbus-1/services/org.razer.service
install -v -d /etc/xdg/autostart
sed -e 's|^Exec=.*|Exec=/usr/bin/openrazer-se-houver|' -e 's|^Icon=.*|Icon=input-keyboard|' \
  install_files/desktop/openrazer-daemon.desktop > /etc/xdg/autostart/openrazer-daemon.desktop
cd /sources; rm -rf openrazer-3.12.4
groupadd -f plugdev
usermod -aG plugdev ninja
id ninja | grep -q plugdev
ls /lib/modules/\$KV/extra/razer{kbd,mouse,kraken,accessory}.ko*
modinfo -k \$KV razermouse | grep -E '^(vermagic|alias)' | head -3
python3 -c 'import openrazer.client, openrazer_daemon.daemon, pyudev, setproctitle, daemonize, dbus, gi; print(\"openrazer: imports OK\")'
openrazer-daemon --help > /dev/null
python3 -c 'import ast,sys; ast.parse(open(\"/usr/bin/openrazer\").read())'
desktop-file-validate /etc/xdg/autostart/openrazer-daemon.desktop || true" || return 1
}

# hidapi (não está no BLFS): requerido pelo HeadsetControl; backends hidraw e libusb
drivers_hidapi() {
  in_chroot "set -e
cd /sources; rm -rf hidapi-hidapi-0.15.0; tar -xf hidapi-0.15.0.tar.gz; cd hidapi-hidapi-0.15.0
cmake -B build -G Ninja -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release -D HIDAPI_WITH_LIBUSB=ON
ninja -C build
ninja -C build install
cd /sources; rm -rf hidapi-hidapi-0.15.0
ls -l /usr/lib/libhidapi-hidraw.so.0 /usr/lib/libhidapi-libusb.so.0" || return 1
}

# HeadsetControl: bateria, sidetone, luzes e equalizador de headsets HyperX, SteelSeries, Logitech,
# Corsair, Roccat... As regras udev geradas (headsetcontrol -u) usam TAG+="uaccess"; acrescenta-se
# GROUP="plugdev", MODE="0660" para funcionar mesmo que o uaccess não se aplique (sem logind).
drivers_headsetcontrol() {
  in_chroot "set -e
cd /sources; rm -rf HeadsetControl-4.2.0; tar -xf HeadsetControl-4.2.0.tar.gz; cd HeadsetControl-4.2.0
cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release -D BUILD_UNIT_TESTS=OFF
make -C build
make -C build install
sed -i 's|TAG+=\"uaccess\"|TAG+=\"uaccess\", GROUP=\"plugdev\", MODE=\"0660\"|' /usr/lib/udev/rules.d/70-headsets.rules
rm -fv /usr/lib/libheadsetcontrol_lib.a; rm -rf /usr/include/headsetcontrol
cd /sources; rm -rf HeadsetControl-4.2.0
headsetcontrol --help > /dev/null
grep -c plugdev /usr/lib/udev/rules.d/70-headsets.rules
grep -qi '0951\|03f0' /usr/lib/udev/rules.d/70-headsets.rules" || return 1
}

# Blueman (gestor de Bluetooth GTK3; não está no BLFS): sem PulseAudio nem plugins de gestores de
# ficheiros que não existem (Caja/Nemo/Nautilus); com o "Enviar para" do Thunar.
drivers_blueman() {
  in_chroot "set -e
cd /sources; rm -rf blueman-2.4.6; tar -xf blueman-2.4.6.tar.xz; cd blueman-2.4.6
mkdir build; cd build
meson setup .. --prefix=/usr --buildtype=release -D pulseaudio=false -D sendto-plugins=[] \
  -D thunar-sendto=true -D policykit=true -D runtime_deps_check=true
ninja
ninja install
cd /sources; rm -rf blueman-2.4.6
ls /etc/xdg/autostart/blueman.desktop /usr/bin/blueman-manager /usr/bin/blueman-applet
python3 -c 'import blueman.Functions; print(\"blueman: import OK\")'
desktop-file-validate /usr/share/applications/blueman-manager.desktop || true" || return 1
}

# xfce4-screenshooter (não está no BLFS 12.4) + teclas: Print -> ecrã inteiro (-f),
# Shift+Print -> região (-r). Os atalhos estão no ficheiro de sistema do libxfce4ui, editado no
# sítio como na F8d (tema_atalho): só se trocam/acrescentam estas duas entradas.
drivers_screenshooter() {
  local f=$LFS/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
  in_chroot "set -e
cd /sources; rm -rf xfce4-screenshooter-1.11.3; tar -xf xfce4-screenshooter-1.11.3.tar.xz; cd xfce4-screenshooter-1.11.3
mkdir build; cd build
meson setup .. --prefix=/usr --buildtype=release -D x11=enabled -D wayland=disabled
ninja
ninja install
cd /sources; rm -rf xfce4-screenshooter-1.11.3
xfce4-screenshooter --help > /dev/null
desktop-file-validate /usr/share/applications/xfce4-screenshooter.desktop || true" || return 1
  [ -f $f ] || { echo "falta $f (instalado pelo libxfce4ui)"; return 1; }
  python3 -I - $f <<'EOF' || return 1
import sys, xml.etree.ElementTree as ET
f = sys.argv[1]
arv = ET.parse(f)
cmds = arv.getroot().find("./property[@name='commands']/property[@name='default']")
if cmds is None:
    sys.exit("secção commands/default não encontrada")
for tecla, cmd in (("Print", "xfce4-screenshooter -f"), ("<Shift>Print", "xfce4-screenshooter -r")):
    p = cmds.find("./property[@name='%s']" % tecla)
    if p is None:
        ET.SubElement(cmds, "property", {"name": tecla, "type": "string", "value": cmd})
        print("acrescentado:", tecla, "->", cmd)
    else:
        print("trocado:", tecla, ":", p.get("value"), "->", cmd)
        p.set("value", cmd)
ET.indent(arv, "  ")
arv.write(f, encoding="UTF-8", xml_declaration=True)
EOF
  grep -n '"Print" type="string" value="xfce4-screenshooter -f"' $f || return 1
  grep -n 'Shift&gt;Print" type="string" value="xfce4-screenshooter -r"' $f || return 1
}

# info-hardware + atalho "Informação do hardware"
drivers_info_hardware() {
  install -v -m755 $DRV_D/info-hardware $LFS/usr/bin/info-hardware || return 1
  install -v -m644 $P/scripts/apps/raiz/usr/share/applications/info-hardware.desktop $LFS/usr/share/applications/ || return 1
  in_chroot "set -e
    bash -n /usr/bin/info-hardware
    desktop-file-validate /usr/share/applications/info-hardware.desktop
    update-desktop-database -q /usr/share/applications
    info-hardware > /dev/null" || return 1
}

# verificação final do bloco
drivers_verificar() {
  in_chroot "set -e
    KV=$DRV_KV
    for f in /usr/bin/{instalar-driver-nvidia,info-hardware,openrazer,openrazer-daemon,headsetcontrol,vulkaninfo,bluetoothctl,blueman-manager,xfce4-screenshooter,glslangValidator} \
             /usr/lib/libvulkan.so.1 /usr/lib/libhidapi-hidraw.so.0 /usr/lib/udev/rules.d/{99-razer,70-headsets,90-ianinja-nvidia}.rules \
             /lib/modules/\$KV/build/Module.symvers /etc/rc.d/init.d/bluetooth; do
      [ -e \$f ] || { echo \"falta \$f\"; exit 1; }
    done
    for f in /usr/bin/vulkaninfo /usr/bin/headsetcontrol /usr/bin/bluetoothd /usr/libexec/bluetooth/bluetoothd /usr/lib/libvulkan_radeon.so /usr/lib/libvulkan_intel.so; do
      [ -e \$f ] || continue
      if ldd \$f | grep 'not found'; then echo \"\$f com bibliotecas em falta\"; exit 1; fi
    done
    modinfo -k \$KV -F vermagic razerkbd
    echo \"drivers: OK — headers \$(du -sh /usr/src/linux-headers-\$KV | cut -f1)\"" || return 1
}
