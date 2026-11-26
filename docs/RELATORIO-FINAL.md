# ianinjapelagestao 12.4 — Relatório final

- Início: 2026-11-04 19:26 · Fim: 2026-11-19 19:09 · **Duração total: 359h43**
- Host: WSL2 Ubuntu 24.04 em Windows 11, 12 núcleos, 11 GB RAM atribuídos
- ISO: `output/ianinjapelagestao-12.4-x86_64.iso` — **2.2G** — SHA-256 `4b4ce4975c4a712caca433dc75dbaaf2049a58920a9882e895f2922af927fa10`
- Pacotes: 108 do LFS (Cap. 5–8, contando passagens múltiplas) + passos BLFS: 34 (F8, base) + 8 (F8b, IA) + 14 (F8c, drivers e firmware) + 124 (F8d, interface gráfica) + 120 (F8e, aplicações, drivers, programação e loja)

## Tempo por etapa

| Etapa | Nome | Estado | Duração | Notas |
|---|---|---|---|---|
| F0 | Preparação do host | ok | 2 min | version-check OK; host WSL2 Ubuntu 24.04, 12 núcleos |
| F1 | Imagem, fontes e utilizador lfs (Cap. 2-4) | ok | 7 min | lfs.img montada, 95 pacotes/patches com MD5 OK, utilizador lfs criado |
| F2 | Cross-toolchain (Cap. 5) | ok | 10 min | 5 pacotes; sanity check Glibc OK |
| F3 | Ferramentas temporárias (Cap. 6) | ok | 13 min | 17 pacotes |
| F4 | Chroot e ferramentas adicionais (Cap. 7) | ok | 8 min | 8 pacotes/secções; backup em backup-cap7.tar.xz (496M) |
| F5 | Sistema base (Cap. 8) | aviso | 11h43 | 82 pacotes/secções; testes com falhas (tolerados, ver logs): Python acl e2fsprogs glibc libelf perl procps-ng tar util-linux  |
| F6 | Configuração do sistema + identidade (Cap. 9) | ok | 1 min | bootscripts, rede dhcpcd/eth0, inittab+ttyS0, pt-latin1, pt_PT.UTF-8, identidade da distro |
| F7 | Kernel e boot (Cap. 10) | ok | 30 min | kernel 6.16.1 (base Arch 6.16.1.arch1-1) com todas as opções pedidas; 6256 módulos (137M); fstab live |
| F8 | Pacotes BLFS | ok | 9 min | 34 passos BLFS: certificados, PAM/Shadow/Sudo, dhcpcd, Wget/cURL, OpenSSH, nano, utilitários, Git, Lynx, utilizador ninja |
| F8b | Inteligência artificial (llama.cpp + modelo) | ok | 4 min | CMake 4.1.0, llama.cpp b12121 (todas as variantes CPU), Qwen2.5-1.5B Q4_K_M; ia-perguntar em 1.369117816 s no chroot |
| F8c | Drivers e firmware | ok | 3h15 | firmware 20261019 (3937 ficheiros, 790M, .xz), regdb 2026.09.03, microcódigo 18M; libnl, wpa_supplicant, iw, alsa-lib, alsa-utils, ligar-wifi |
| F8d | Interface gráfica (Xorg + Xfce, estilo macOS) | ok | 18h30 | 124 passos: Xorg, Mesa, GTK3, Xfce 4.20, LightDM e tema ao estilo do macOS |
| F8e | Aplicações, drivers, programação, loja e face-finder | ok | 317h53 | 120 passos: aplicações (instalar-aplicacoes), drivers, Python/Node.js, loja Flatpak e face-finder |
| F9 | Sistema live (initramfs + SquashFS) | ok | 3 min | initrd 24M, rootfs.squashfs 2.2G |
| F10 | Geração da ISO | ok | 1 min | ISO 2.2G, sha256 4b4ce4975c4a712c… |
| F11 | Testes automáticos (QEMU BIOS/UEFI) | ok | 10 min | BIOS 20/20, UEFI 20/20, persistência OK, persistencia-ficheiro 5/5, persistencia-pen 8/8, assistente-bios 4/4, pen-bios 4/4, pen-uefi 4/4, disco-bios 4/4, disco-uefi 4/4 |
| F12 | Entrega | ok | 1 min | README, relatório e cópia para o Windows |

## Testes automáticos (F11, QEMU headless)

### BIOS

```
INFO  aceleração KVM ativa
PASS  GRUB mostra o menu ianinjapelagestao
PASS  Kernel arranca e o initramfs monta o SquashFS/overlay
PASS  Banner do /etc/issue e prompt login:
PASS  Login root e /etc/os-release mostra ianinjapelagestao
PASS  eth0 com IP via DHCP e wget https funciona
PASS  sudo -u ninja sudo -n true
PASS  zram ativo (swap em /proc/swaps)
PASS  Módulos carregados automaticamente (snd_hda_intel via udev)
PASS  LightDM a correr no nível 5 (pidof lightdm)
PASS  Xorg arrancou (modesetting, sem Fatal server error) e greeter ativo
INFO  captura do ecrã do greeter: /root/ianinjapelagestao/logs/11-ecra-bios.png (/root/ianinjapelagestao/logs/11-ecra-bios.png: 1280x800)
PASS  Fonte Inter (fc-list) e tema /usr/share/themes/WhiteSur-Light
PASS  Instaladores: instalar-aplicacoes -l, instalar-ferramentas -l, instalar-tudo-click.sh e autostart
PASS  Programação: node e npm, python3 (sqlite3, requests, numpy, cv2) e gdb
PASS  Flatpak: flatpak e bwrap, remote flathub do sistema, sandbox bwrap como ninja e loja --verificar
INFO  Flathub acessível pela rede (dl.flathub.org) — só informativo
PASS  Drivers: vulkaninfo (lavapipe), info-hardware, instalar-driver-nvidia -l, bluetoothctl, headsetcontrol e xfce4-screenshooter
PASS  face-finder encontra rostos nas fotografias incluídas (/usr/share/face-finder/fotos)
PASS  Rede: NetworkManager liga o cabo sozinho (eth0 connected, IP 10.0.2.x, resolv.conf, sem S..network, autostart do nm-applet)
PASS  Assistente de 1.º arranque desligado pela cadeia SMBIOS (ianinja-assistente --estado)
PASS  IA responde (ia-perguntar)
INFO  resposta da IA: OK
PASS  poweroff encerra limpo
```

Captura do ecrã de início de sessão: `logs/11-ecra-bios.png`

### UEFI

```
INFO  aceleração KVM ativa
PASS  GRUB mostra o menu ianinjapelagestao
PASS  Kernel arranca e o initramfs monta o SquashFS/overlay
PASS  Banner do /etc/issue e prompt login:
PASS  Login root e /etc/os-release mostra ianinjapelagestao
PASS  eth0 com IP via DHCP e wget https funciona
PASS  sudo -u ninja sudo -n true
PASS  zram ativo (swap em /proc/swaps)
PASS  Módulos carregados automaticamente (snd_hda_intel via udev)
PASS  LightDM a correr no nível 5 (pidof lightdm)
PASS  Xorg arrancou (modesetting, sem Fatal server error) e greeter ativo
INFO  captura do ecrã do greeter: /root/ianinjapelagestao/logs/11-ecra-uefi.png (/root/ianinjapelagestao/logs/11-ecra-uefi.png: 1280x800)
PASS  Fonte Inter (fc-list) e tema /usr/share/themes/WhiteSur-Light
PASS  Instaladores: instalar-aplicacoes -l, instalar-ferramentas -l, instalar-tudo-click.sh e autostart
PASS  Programação: node e npm, python3 (sqlite3, requests, numpy, cv2) e gdb
PASS  Flatpak: flatpak e bwrap, remote flathub do sistema, sandbox bwrap como ninja e loja --verificar
INFO  Flathub acessível pela rede (dl.flathub.org) — só informativo
PASS  Drivers: vulkaninfo (lavapipe), info-hardware, instalar-driver-nvidia -l, bluetoothctl, headsetcontrol e xfce4-screenshooter
PASS  face-finder encontra rostos nas fotografias incluídas (/usr/share/face-finder/fotos)
PASS  Rede: NetworkManager liga o cabo sozinho (eth0 connected, IP 10.0.2.x, resolv.conf, sem S..network, autostart do nm-applet)
PASS  Assistente de 1.º arranque desligado pela cadeia SMBIOS (ianinja-assistente --estado)
PASS  IA responde (ia-perguntar)
INFO  resposta da IA: OK
PASS  poweroff encerra limpo
```

Captura do ecrã de início de sessão: `logs/11-ecra-uefi.png`

### Persistência

```
INFO  aceleração KVM ativa
INFO  arranque 1: persistência ligada em /dev/vda
INFO  arranque 1: marcador escrito em /root/marcador-persistencia
INFO  arranque 2: persistência ligada em /dev/vda
PASS  Persistência IANINJA-DADOS (2 arranques: marcador em /root sobrevive)
```

## Test suites obrigatórias (Cap. 8)

- Test suite Glibc: 4 FAIL (livro documenta falhas conhecidas): io/tst-lchmod misc/tst-preadvwritev2 misc/tst-preadvwritev64v2 nss/tst-nss-files-hosts-getent 
- Test suite Binutils: 0 falhas inesperadas
- Test suite gmp: 199 testes passaram, 0 falhas
- Test suite mpfr: 198 testes passaram, 0 falhas
- Test suite mpc: 74 testes passaram, 0 falhas
- Test suite GCC: 8 falhas inesperadas (resumo em logs/08-gcc.log)

## Pacotes com falhas de testes toleradas

- 08-Python.log
- 08-acl.log
- 08-e2fsprogs.log
- 08-glibc.log
- 08-libelf.log
- 08-perl.log
- 08-procps-ng.log
- 08-tar.log
- 08-util-linux.log

## Passos F8 — pacotes BLFS (base)

- bash-profile
- bootscripts
- cpio
- curl
- dhcpcd
- dosfstools
- efibootmgr
- efivar
- git
- hwdata
- libidn2
- libpsl
- libtasn1
- libunistring
- libusb
- limpeza
- linux-pam
- lynx
- make-ca
- nano
- openssh
- p11-kit
- pciutils
- popt
- shadow
- skel-ninja
- sshd-chaves
- sudo
- sudoers-ninja
- tree
- usbutils
- verificacao
- wget
- which

## Passos F8b — inteligência artificial

- autoarranque
- cmake
- comandos
- llama-fonte
- llama
- modelo-baixar
- modelo-instalar
- verificacao

## Passos F8c — drivers e firmware

- alsa-lib
- alsa-utils
- bootscripts
- firmware
- fontes
- host-ferramentas
- iw
- libnl
- ligar-wifi
- limpar-tmp
- limpeza
- microcodigo
- verificacao
- wpa_supplicant

## Passos F8d — interface gráfica (pela ordem da build)

- xorg7
- util-macros
- xorgproto
- libXau
- xcb-proto
- libXdmcp
- libxcb
- libpng
- pixman
- docutils
- icu
- libxml2
- libxslt
- pcre2
- glib2
- freetype2
- graphite2
- harfbuzz
- freetype2-harfbuzz
- fontconfig
- x7lib
- libxcvt
- libdrm
- Mako
- cython
- libyaml
- PyYAML
- llvm
- spirv-headers
- spirv-tools
- spirv-llvm-translator
- libclc
- mesa
- mesa-vgem
- xbitmaps
- xcb-util
- x7app
- xcursor-themes
- x7font
- xkeyboard-config
- dbus
- dbus-bootscript
- elogind
- duktape
- polkit
- libtirpc
- libepoxy
- xorg-server
- xorg-teclado
- libevdev
- mtdev
- libinput
- xorg-libinput-driver
- xinit
- at-spi2-core
- fribidi
- cairo
- pango
- libssh2
- sqlite
- rust
- cargo-c
- nasm
- yasm
- libjpeg
- shared-mime-info
- libtiff
- gdk-pixbuf
- librsvg
- pixbuf-loaders
- hicolor-icon-theme
- iso-codes
- wayland
- wayland-protocols
- libxkbcommon
- gtk3
- adwaita-icon-theme
- startup-notification
- libwnck
- libdisplay-info
- xfce4-dev-tools
- libxfce4util
- xfconf
- libxfce4ui
- libxfce4windowing
- desktop-file-utils
- exo
- garcon
- xfce4-panel
- xfce4-session
- xfwm4
- libnotify
- libgudev
- thunar
- xfdesktop
- libogg
- libvorbis
- sound-theme-freedesktop
- libcanberra
- libxklavier
- xfce4-settings
- fast_float
- vte
- xfce4-terminal
- xfce4-appfinder
- tumbler
- xfce4-notifyd
- itstool
- libgpg-error
- libgcrypt
- lightdm
- lightdm-bootscript
- lightdm-runlevel5
- TTF-and-OTF-fonts
- tema-descarregar
- tema-docklike
- tema-gtk
- tema-icones
- tema-cursores
- tema-fontes
- tema-config
- tema-verificar
- machine-id

## Passos F8e — aplicações, drivers, programação, loja e face-finder (pela ordem da build)

- nspr
- nss
- nettle
- gnutls
- xdg-utils
- cups
- cups-bootscript
- cups-sem-arranque
- libsecret
- instalar-aplicacoes
- verificar-bibliotecas
- libarchive
- pyproject-metadata
- meson_python
- numpy
- opencv
- pycairo
- pygobject3
- libexif
- ristretto
- facefinder-downloads
- facefinder-instalar
- facefinder-verificar
- drv-fontes
- kernel-headers
- vulkan-headers
- vulkan-loader
- glslang
- mesa-vulkan
- vulkaninfo
- nvidia-a-pedido
- patchelf
- dbus-python
- openrazer
- hidapi
- headsetcontrol
- libical
- bluez
- bluez-bootscript
- blueman
- screenshooter
- info-hardware
- drv-verificar
- python3-sqlite3
- setuptools_scm
- charset-normalizer
- idna
- editables
- pathspec
- pluggy
- trove-classifiers
- hatchling
- hatch-vcs
- urllib3
- requests
- iniconfig
- pygments
- pytest
- six
- nodejs
- gdb
- valgrind
- prog-ambiente
- prog-verificar
- libseccomp
- bubblewrap
- xdg-dbus-proxy
- fuse3
- libassuan
- libksba
- npth
- pinentry
- gnupg
- gpgme
- libxmlb
- appstream
- json-glib
- pyparsing
- ostree
- flatpak
- gstreamer
- gst-plugins-base
- pipewire
- gsettings-desktop-schemas
- xdg-desktop-portal
- xdg-desktop-portal-gtk
- flathub
- loja
- loja-verificar
- vte-gnutls
- icones-sessao
- rede-fontes
- wpa-dbus
- libndp
- slang
- newt
- networkmanager
- nm-bootscript
- gcr
- libnma
- nm-applet
- rede-configurar
- rede-verificar
- assistente-instalar
- assistente-verificar
- otim-bluetooth
- otim-xfce
- otim-strip
- otim-verificar
- persistencia-instalar
- persistencia-verificar
- lua
- wireplumber
- sbc
- pipewire-bluetooth
- v4l-utils
- gnome-keyring
- correcoes-12
- correcoes-12-verificar

## Decisões tomadas

- Host de construção: WSL2 (Ubuntu 24.04) em Windows 11
- Transcrição dos comandos do livro
- Errata LFS/BLFS 12.4
- Rede do WSL em modo mirrored
- Partição LFS em ficheiro de imagem
- Backup do Cap. 7 sem /sources
- Stripping (8.85): ignorar erros do strip
- Nomes de rede e consola série
- fstab e bootscripts para sistema live
- Configuração do kernel
- BLFS: compilação como root dentro do chroot
- BLFS: blfs-bootscripts sem MD5 no livro
- BLFS: certificados (make-ca) e DNS no chroot
- BLFS: dependências recomendadas instaladas
- BLFS: configuração do dhcpcd
- BLFS: OpenSSH — chaves de host e arranque manual
- BLFS: utilizador ninja e sudo sem senha
- BLFS: ficheiros de arranque do Bash, /etc/skel e prompt
- BLFS: pacotes opcionais Git e Lynx
- initramfs live
- GRUB também na consola série
- IA: llama.cpp b12121 (só CPU)
- IA: variantes do backend CPU (GGML_BACKEND_DL + GGML_CPU_ALL_VARIANTS)
- IA: cURL/HTTPS e interface web do llama.cpp
- IA: CMake do BLFS com bibliotecas internas
- IA: modelo predefinido Qwen2.5-1.5B-Instruct Q4_K_M (Apache 2.0)
- IA: comandos ia-* e servidor
- IA: chat automático no login do ninja
- Kernel afinado para IA no CPU (llama.cpp) e persistência
- Afinação de memória e CPU em tempo de execução (IA)
- Persistência em pen USB (IANINJA-DADOS)
- GRUB: entrada sem persistência
- Testes F11: zram, IA e persistência
- Kernel: configuração base do Arch Linux e drivers em módulos
- Drivers: nova etapa F8c (firmware e espaço de utilizador)
- Firmware: linux-firmware 20261019 em .xz, deduplicado
- Firmware: wireless-regdb 2026.09.03
- Firmware: microcódigo Intel e AMD (carregamento precoce)
- Drivers: carregamento automático de módulos pelo udev
- Wi-Fi: libnl, wpa_supplicant, iw e ligar-wifi
- Som: alsa-lib e alsa-utils
- Bluetooth: só drivers do kernel
- Interface gráfica: Xorg + Xfce 4.20 com aspeto ao estilo do macOS
- F8d — Base gráfica: páginas, ordem e passos acrescentados
- F8d — Listas do Xorg (bibliotecas, aplicações, tipos de letra)
- F8d — GLib com GObject Introspection
- F8d — FreeType antes e depois do HarfBuzz
- F8d — LLVM com Clang, sem compiler-rt nem testes
- F8d — Mesa: drivers escolhidos
- F8d — Mesa: módulo vgem no arranque
- F8d — D-Bus: bootscript, machine-id e testes
- F8d — elogind e PAM
- F8d — Polkit
- F8d — Xorg-Server, xinit e teclado
- F8d — Rust: LLVM do sistema, /opt/rustc e rede no chroot
- F8d — Rust: test suite omitida
- F8d — cargo-c e librsvg: crates descarregadas no chroot
- F8d — gdk-pixbuf antes do librsvg: cache dos loaders regenerada
- F8d — GTK3: X11 + Wayland, sem páginas de manual
- F8d — Documentação opcional e Gi-DocGen
- F8d — shared-mime-info sem xdgmime
- F8d — SQLite: opções do livro e módulo sqlite3 do Python
- F8d — Testes de Wayland, libxkbcommon, GTK3 e at-spi2-core
- Xfce: documentação e sessão pelo LightDM
- xfce4-session: sem ~/.xinitrc
- libnotify, VTE e xfce4-notifyd: blocos omitidos
- VTE sem GnuTLS, GTK-4 e Vala
- alsa-lib fora deste bloco
- libcanberra: patch do livro, sem GStreamer/PulseAudio/GTK2
- libgpg-error e libgcrypt acrescentadas antes do LightDM
- LightDM: utilizador, Xorg e greeter
- LightDM: PAM
- LightDM: configuração funcional e arranque no runlevel 5
- Tipos de letra: DejaVu e Liberation
- xfce4-terminal sem página de manual
- Tema: aspeto ao estilo do macOS com temas livres WhiteSur
- Tema GTK: variantes pré-geradas, sem sassc
- Ícones e cursores: sem ferramentas em falta; logótipo da Apple substituído
- Dock: xfce4-docklike-plugin 0.5.1
- Painéis: barra superior e dock em /etc/xdg/xfce4/panel/default.xml
- Janelas, fontes e definições GTK
- Papel de parede, logótipo e ambiente de trabalho
- Atalho Super+Espaço (pesquisa rápida) e terminal
- Ecrã de início de sessão (lightdm-gtk-greeter)
- Configuração para todos os utilizadores
- Live: Rust e caches do cargo fora do SquashFS
- Sistema live com interface gráfica
- GRUB: modo texto e modo seguro sem interface gráfica
- Testes F11: módulos carregados automaticamente
- Testes F11: interface gráfica
- VS Code, Google Chrome, Claude Code e Codex instalados no 1.º uso (não vão na ISO)
- Origem das transferências e verificação
- Dependências: o que o ldd mostrou em falta
- Páginas do BLFS acrescentadas e cortes
- CUPS instalado mas sem arrancar
- libsecret sem Vala nem páginas de manual
- xdg-utils sem xmlto
- Sandbox do Chromium (Chrome e VS Code)
- Instalar tudo no 1.º início de sessão
- OpenCV sem as dependências multimédia recomendadas
- OpenCV: WITH_IPP=OFF, sem G-API e sem opencv_contrib
- NumPy antes do OpenCV; testes sem rede omitidos
- libarchive instalada por ser requerida pelo opencv
- PyGObject e PyCairo para a interface gráfica do face-finder
- Ristretto e libexif
- Modelo YuNet com URL fixada e SHA-256
- Fotografias de licença livre do Wikimedia Commons
- User-Agent próprio para os downloads do Wikimedia
- Projeto em ~/Projetos/face-finder e programa em /usr/share/face-finder
- F8e — Drivers: headers do kernel para módulos externos
- F8e — Vulkan: Mesa recompilado com anv, hasvk, radv e lavapipe
- F8e — Aceleração de vídeo (VA-API/VDPAU) não incluída
- F8e — NVIDIA: driver oficial a pedido (instalar-driver-nvidia)
- F8e — Razer: OpenRazer 3.12.4
- F8e — HyperX e outros periféricos gaming
- F8e — Bluetooth: BlueZ 5.83 e Blueman 2.4.6
- F8e — xfce4-screenshooter e teclas Print
- F8e — info-hardware
- Patchelf antes do dbus-python
- Ambiente de programação: o que entra na ISO e o que fica a pedido
- Python: só o módulo _sqlite3, sem recompilar o interpretador
- Certificados para pip, venv e requests
- Módulos Python escolhidos
- Node.js com as bibliotecas internas
- npm install -g sem sudo
- GDB e Valgrind
- Rust a pedido com o rustup (o /opt/rustc continua fora da ISO)
- Go e Java a pedido
- O comando instalar-ferramentas
- Verificação no chroot
- Pygments antes do pytest
- Loja de aplicações = Flatpak + Flathub, com uma Loja gráfica própria
- API do Flathub e cache
- Progresso das instalações
- Sessão live: aviso e persistência
- Pacotes do BLFS acrescentados
- OSTree e Flatpak compilados de fonte
- Remote Flathub
- Aspeto das aplicações Flatpak
- Requisitos do kernel
- xdg-dbus-proxy sem página de manual
- Testes F11: aplicações da F8e
- initramfs: mensagens no ecrã e espera de 60 s
- Interface gráfica vigiada (ianinja-dm)
- GRUB: ecrã como consola principal (tty0 por último)
- GRUB: modo gráfico de compatibilidade (nomodeset)
- initramfs: ISO9660 no disco inteiro (pen USB gravada em modo imagem)
- ianinja-dm: níveis de recurso do Xorg antes de desistir
- Testes F11: arranque como pen USB e como disco
- F8e — VTE recompilada com GnuTLS
- Ícones do diálogo "Terminar sessão" pré-desenhados em PNG
- Inherits do WhiteSur: Adwaita,hicolor
- Verificador de ícones no sistema
- F8e — Rede: NetworkManager em vez do bootscript network (dhcpcd)
- F8e — Rede: opções de compilação e configuração do NetworkManager
- F8e — Rede: polkit e grupo netdev
- F8e — Rede: wpa_supplicant recompilado com D-Bus
- F8e — Rede: Gcr, libnma e network-manager-applet
- F8e — Rede: ligar-wifi passa a usar o nmcli
- F8e — Rede: drivers de adaptadores Wi-Fi USB
- F8e — Rede: info-hardware
- Assistente de configuração no lugar do ecrã de entrada (greeter do LightDM)
- Fluxo, validação e o que é criado
- sudo do novo utilizador COM senha
- Parte privilegiada pelo sudo do utilizador lightdm
- O utilizador ninja depois da configuração e caminho de recuperação
- Live sem persistência, "Experimentar sem criar conta" e autologin
- Desligar o assistente: ianinja.assistente=0 (linha do kernel ou SMBIOS) para os testes
- Robustez: o assistente nunca impede o ecrã de entrada
- Modo de texto
- Verificação na construção sem tocar nas contas reais
- Otimizações: medição de partida
- Strip dos executáveis e bibliotecas (passo otim-strip)
- SquashFS: exclusões só da imagem (F9, exclusoes_live)
- SquashFS: zstd nível 19 com blocos de 1 MiB
- zswap desligado (zswap.enabled=0 no GRUB)
- Bluetooth só com adaptador (passo otim-bluetooth)
- Compositor desligado em modo de recurso; miniaturas limitadas (passo otim-xfce)
- O que ficou de fora e porquê
- Testes F11: rede pelo NetworkManager e assistente de 1.º arranque
- F11 assistente-bios: o su pede "Palavra-passe:" e a recusa é em português
- Página onde guardar os dados
- Guardar os dados automaticamente: um backend, três destinos
- Tipo "pen": partição a seguir à imagem na própria pen (sfdisk sobre a GPT da ISO híbrida)
- Tipo "ficheiro": ianinja-dados.img numa partição existente
- Tipo "particao" e o ia-criar-persistencia como invólucro
- Migração da camada de escrita atual
- Arranque: ntfs3 e exfat como módulos no initramfs, sem recompilar o kernel
- Reiniciar sem logind nem ConsoleKit: ação "reiniciar" do aplicar
- Testes F11: persistencia-ficheiro e persistencia-pen (scripts/teste-persistencia.exp)
- Riscos conhecidos
- initramfs: persistência em ficheiro (NTFS/exFAT/FAT/ext4) e na própria pen
- Testes F11: persistência em ficheiro (disco NTFS) e na própria pen
- F8e bloco 12 — driver NVIDIA: /usr/sbin no PATH do instalar-driver-nvidia
- F8e bloco 12 — áudio: WirePlumber do BLFS e lançador do PipeWire
- F8e bloco 12 — áudio Bluetooth: SBC e PipeWire recompilado
- F8e bloco 12 — GNOME Keyring (org.freedesktop.secrets)
- F8e bloco 12 — v4l-utils

Detalhes em `docs/DECISOES.md`.

## Avisos conhecidos

- O GRUB da ISO não está assinado: em PCs com *Secure Boot* ativo é preciso desativá-lo.
- Sistema live: sem um disco de dados `IANINJA-DADOS` as alterações vivem em RAM e perdem-se ao desligar.
- Interface gráfica só X11 (sem Wayland). Com `nomodeset` o Xorg usa o simpledrm (imagem do firmware, sem aceleração nem mudança de resolução): entrada *modo gráfico de compatibilidade*; o *modo seguro* arranca só em texto.
- Em VMs sem aceleração 3D o Mesa desenha por CPU (llvmpipe): o ambiente funciona, mas mais devagar.
- VS Code, Google Chrome, Claude Code, Codex, o driver oficial da NVIDIA, Rust, Go e Java não vão na ISO (licença ou tamanho): instalam-se a pedido, com Internet (`instalar-aplicacoes`, `instalar-driver-nvidia`, `instalar-ferramentas`).
- Bluetooth sem áudio: os headsets emparelham, mas o A2DP/HFP precisa de PipeWire ou PulseAudio (não incluídos). O CUPS está instalado, mas não arranca nem tem o cups-filters.
- Com o driver oficial da NVIDIA instalado, o OpenGL de outra placa Intel/AMD do mesmo computador deixa de funcionar.
- As chaves de host SSH (se o sshd for ativado) são geradas no arranque e mudam a cada boot.

## Falhas durante a build (corrigidas e retomadas; últimas 20)

- 2026-11-04 20:47 — Fim da etapa F5 (falhou) falhou em chapter08/binutils (1/1) — ver logs/08-binutils.log
- 2026-11-04 20:52 — Fim da etapa F5 (falhou) falhou em chapter08/gmp (1/1) — ver logs/08-gmp.log
- 2026-11-04 22:52 — Fim da etapa F5 (falhou) falhou em chapter08/stripping (1/1) — ver logs/08-stripping.log
- 2026-11-05 17:17 — Fim da etapa F8c (falhou) falhou em firmware (3/14) — ver logs/f8c-firmware.log
- 2026-11-05 17:17 — Fim da etapa F8c (falhou) falhou em firmware (3/14) — ver logs/f8c-firmware.log
- 2026-11-05 17:42 — Fim da etapa F8c (falhou) falhou em firmware (3/14) — ver logs/f8c-firmware.log
- 2026-11-05 19:54 — Fim da etapa F8d (falhou) falhou em xfce4-terminal (105/123) — ver logs/f8d-xfce4-terminal.log
- 2026-11-05 19:57 — Fim da etapa F8d (falhou) falhou em lightdm-runlevel5 (114/124) — ver logs/f8d-lightdm-runlevel5.log
- 2026-11-06 13:54 — Fim da etapa F8e (falhou) falhou em dbus-python (33/88) — ver logs/f8e-dbus-python.log
- 2026-11-06 13:58 — Fim da etapa F8e (falhou) falhou em pytest (58/89) — ver logs/f8e-pytest.log
- 2026-11-06 14:31 — Fim da etapa F8e (falhou) falhou em xdg-dbus-proxy (68/90) — ver logs/f8e-xdg-dbus-proxy.log
- 2026-11-12 08:49 — Fim da etapa F11 (falhou) BIOS 18/18, UEFI 18/18, persistência OK, pen-bios 2/4, pen-uefi 1/4, disco-bios 1/4, disco-uefi 1/4 — critérios falharam em: pen-bios pen-uefi disco-bios disco-uefi (ver logs/11-resultado-*.txt)
- 2026-11-12 19:36 — Fim da etapa F11 (falhou) BIOS 20/20, UEFI 20/20, persistência OK, assistente-bios 3/4, pen-bios 4/4, pen-uefi 4/4, disco-bios 4/4, disco-uefi 4/4 — critérios falharam em: assistente-bios (ver logs/11-resultado-*.txt)
- 2026-11-13 14:06 — Fim da etapa F8e (falhou) falhou em persistencia-instalar (111/112) — ver logs/f8e-persistencia-instalar.log
- 2026-11-13 14:20 — Fim da etapa F11 (falhou) BIOS 20/20, UEFI 20/20, persistência OK, persistencia-ficheiro 5/5, persistencia-pen 6/8, assistente-bios 4/4, pen-bios 4/4, pen-uefi 4/4, disco-bios 4/4, disco-uefi 4/4 — critérios falharam em: persistencia-pen (ver logs/11-resultado-*.txt)
