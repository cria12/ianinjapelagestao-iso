# ianinjapelagestao 12.4

Distribuição Linux construída do zero seguindo o **Linux From Scratch 12.4 (System V)** e o
**Beyond Linux From Scratch 12.4**, entregue como **ISO live híbrida (BIOS + UEFI)**.

- Ficheiro: `output/ianinjapelagestao-12.4-x86_64.iso` (2.2G; dentro dela `live/rootfs.squashfs` com 2.2G)
- SHA-256: `4b4ce4975c4a712caca433dc75dbaaf2049a58920a9882e895f2922af927fa10`
- Rótulo do volume: `IANINJAPELAGESTAO`
- Interface gráfica Xfce 4.20 com aspeto ao estilo do macOS (ver *Interface gráfica*)

## Como funciona
O GRUB carrega o kernel Linux 6.16.1 e um initramfs que procura o volume `IANINJAPELAGESTAO`,
monta `live/rootfs.squashfs` (xz) só-leitura e por cima uma camada de escrita em RAM (OverlayFS).
**Tudo o que alterar perde-se ao desligar** (a menos que exista um disco de dados `IANINJA-DADOS`:
ver `/usr/share/doc/ianinjapelagestao/README` no sistema).
O sistema arranca no nível 5 (SysVinit): o LightDM mostra o ecrã de início de sessão no `vt7`;
as consolas de texto `tty1`–`tty6` e a consola série `ttyS0` continuam com login.

## Requisitos
- **RAM:** mínimo 2 GB (interface gráfica sem IA); recomendado 4 GB (interface gráfica + modelo de IA local).
- CPU x86-64; placa gráfica com driver KMS no kernel (Intel, AMD, NVIDIA/nouveau, VMware/VirtualBox
  VMSVGA, QEMU std/virtio). Sem aceleração 3D o Mesa desenha por CPU (llvmpipe).

## Contas
O sistema live tem as contas `root` e `ninja` (o `ninja` tem sudo sem senha, `/etc/sudoers.d/ninja`).
As senhas **não estão no repositório**: na construção vêm de `scripts/senhas.local`
(ver `scripts/senhas.local.exemplo`); se esse ficheiro não existir, são geradas senhas aleatórias.
No primeiro arranque o assistente cria a sua própria conta e esconde o `ninja`.

## Gravar numa pen USB
- **Windows:** [Rufus](https://rufus.ie) → escolher a ISO → *modo de imagem DD* (quando perguntar) → Iniciar.
  Ou [balenaEtcher](https://etcher.balena.io) → Flash from file → escolher a pen → Flash.
- **Linux:** `sudo dd if=ianinjapelagestao-12.4-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync`
  (confirme `/dev/sdX` com `lsblk` — o conteúdo da pen é apagado).

Arranque o PC pela pen (menu de boot da BIOS/UEFI; desative o *Secure Boot*, o GRUB não está assinado).

## Testar numa máquina virtual
- **QEMU (BIOS):** `qemu-system-x86_64 -enable-kvm -m 4096 -smp 2 -vga std -cdrom ianinjapelagestao-12.4-x86_64.iso -boot d -nic user,model=e1000`
  (`-vga virtio` também funciona; sem KVM tire `-enable-kvm`, mas o arranque gráfico demora vários minutos)
- **QEMU (UEFI):** acrescentar `-bios /usr/share/ovmf/OVMF.fd`
- **VirtualBox:** Nova VM → Tipo *Linux*, Versão *Other Linux (64-bit)*, 4096 MB RAM (mínimo 2048), sem disco →
  Definições → Ecrã → Controlador gráfico **VMSVGA**, memória de vídeo 128 MB (*Ativar aceleração 3D* é
  opcional) → Armazenamento → unidade ótica → escolher a ISO → (opcional: Sistema → *Ativar EFI*) → Iniciar.
  Rede: NAT com adaptador *Intel PRO/1000*.

Menu do GRUB:
| Entrada | O que faz |
|---|---|
| *ianinjapelagestao 12.4 (Live)* | por omissão: interface gráfica (LightDM + Xfce) |
| *Live - modo gráfico de compatibilidade* | `nomodeset` com interface gráfica sobre a imagem do firmware (simpledrm, sem aceleração): para PCs em que o ecrã fica preto com o driver normal da placa |
| *Live - modo texto, sem interface gráfica* | nível 3: só consolas de texto (`3` na linha do kernel) |
| *Live - modo seguro/verbose* | `nomodeset`, mensagens completas, modo texto (sem KMS o Xorg não arranca) |
| *sem persistência* | interface gráfica, ignora o disco de dados `IANINJA-DADOS` |

A consola série `ttyS0` (115200) também tem login.

## Interface gráfica
Ambiente de trabalho **Xfce 4.20** sobre o **Xorg** (driver modesetting, Mesa), com o gestor de
sessões **LightDM** (ecrã *lightdm-gtk-greeter*) e um aspeto ao estilo do macOS: tema **WhiteSur**
(GTK, janelas, ícones e cursores), barra superior e dock em baixo, botões das janelas à esquerda,
fonte **Inter** (e JetBrains Mono no terminal), papel de parede e logótipo próprios.

- **Entrar:** no ecrã de início de sessão escolha `ninja` e escreva a senha definida em `scripts/senhas.local`.
  O `root` não aparece na lista (use `sudo` no terminal, ou uma consola de texto).
- **Consolas de texto:** `Ctrl+Alt+F1` … `Ctrl+Alt+F6` (login de texto normal);
  voltar ao ambiente gráfico: `Ctrl+Alt+F7`.
- **Pesquisa rápida de aplicações:** `Super+Espaço` (tecla Windows + Espaço).
- **Sem interface gráfica:** entrada *modo texto* do GRUB (ou carregar `e` no GRUB e acrescentar ` 3`
  à linha `linux`); com o sistema já arrancado: `sudo telinit 3` (voltar: `sudo telinit 5`).
- **Problemas:** `/var/log/Xorg.0.log` e `/var/log/lightdm/`; se o ecrã ficar preto, use o *modo gráfico de compatibilidade*
  (ou o *modo seguro*, só texto). Se o X falhar 3 vezes seguidas o sistema volta sozinho à consola
  `tty1` com um aviso (registo `/var/log/ianinja-dm.log`; tentar outra vez: `sudo ianinja-dm repor`).
- Teclado português no X (`setxkbmap us` para americano).

## O que está incluído
- **Sistema base LFS 12.4 (Cap. 5–8):** 108 pacotes/secções (passagens múltiplas contam à parte), entre eles Glibc 2.42, GCC 15.2.0, Binutils 2.45,
  Bash 5.3, Coreutils 9.7, Perl 5.42, Python 3.13.7, OpenSSL 3.5.2, Vim, GRUB 2.12, Udev (systemd 257.8),
  SysVinit 3.14, Kbd, IPRoute2, E2fsprogs.
- **BLFS 12.4 (F8):** 34 passos — bootscripts BLFS, make-ca/p11-kit (certificados), Linux-PAM, Shadow com PAM,
  Sudo, dhcpcd, Wget, cURL, OpenSSH, Nano, cpio, dosfstools, efivar, efibootmgr, pciutils, usbutils, which, tree
  (lista exata em `docs/RELATORIO-FINAL.md`).
- **Interface gráfica (F8d, BLFS 12.4, 124 passos):** Xorg-Server 21.1 + bibliotecas, aplicações e tipos de letra
  do Xorg, Mesa (iris/crocus/i915, radeonsi/r600/r300, nouveau, svga, virgl, llvmpipe) com LLVM/Clang,
  libinput, D-Bus, elogind, Polkit, GLib, GTK3, Pango, Cairo, HarfBuzz, librsvg, Xfce 4.20 (painel, xfwm4,
  Thunar, xfdesktop, terminal, appfinder, notificações), xfce4-docklike-plugin (dock), LightDM +
  lightdm-gtk-greeter; temas WhiteSur (GTK, ícones, cursores), fontes Inter, JetBrains Mono, DejaVu e Liberation.
- **Drivers e firmware (F8c, 14 passos):** kernel com drivers em módulos (carregados pelo udev), linux-firmware,
  microcódigo do CPU, Wi-Fi (libnl, wpa_supplicant, iw, `ligar-wifi`), som ALSA (alsa-lib, alsa-utils).
- **IA local (F8b, 8 passos):** llama.cpp com um modelo pequeno (Qwen2.5-1.5B): `ia-perguntar`, e um chat
  automático quando o `ninja` entra numa consola de texto `tty1`–`tty6` (`Ctrl+C` ou `/sair` volta à shell).
- **Aplicações, drivers, programação e loja (F8e, 120 passos):** NSPR/NSS, libcups, libsecret e
  xdg-utils para as aplicações instaladas a pedido (VS Code, Chrome, Claude Code, Codex); headers do kernel,
  Vulkan (Mesa com anv/hasvk/radv/lavapipe, vulkaninfo), OpenRazer, hidapi + HeadsetControl, BlueZ + Blueman,
  xfce4-screenshooter; Python com sqlite3/requests/pytest, Node.js 22 + npm, GDB, Valgrind; OSTree + Flatpak,
  xdg-desktop-portal(-gtk) e a Loja (Flathub); OpenCV, NumPy, PyGObject, Ristretto e o projeto face-finder
  (ver *Aplicações, drivers e loja*).
- Locale `pt_PT.UTF-8` (+ `en_US.UTF-8`), fuso `Europe/Lisbon`, teclado `pt-latin1`, hostname `ianinjapelagestao`.
- Rede automática: `dhcpcd` em `eth0` (nomes clássicos com `net.ifnames=0`).

## Aplicações, drivers e loja
O que a ISO não pode levar por licença (VS Code, Google Chrome, Claude Code, Codex) instala-se no 1.º
uso, a partir dos sites oficiais (com Internet; SHA-256 verificado); o resto já vem no sistema.
**Numa sessão live sem disco de dados `IANINJA-DADOS` tudo o que instalar fica na RAM e perde-se ao
desligar** — no 1.º arranque o assistente pergunta onde guardar os dados (partição nova na própria pen, ficheiro no
disco do Windows ou uma partição formatada); na consola: `sudo ianinja-persistencia listar` e `criar <id>`.

### VS Code, Google Chrome, Claude Code e Codex
- **Assistente automático:** no 1.º início de sessão, com Internet e se faltar alguma das quatro, abre-se
  um terminal com `instalar-aplicacoes tudo` (aceite cada licença). Pergunta uma só vez por pasta
  pessoal; para voltar a perguntar: `instalar-tudo-click.sh --agora`.
- **Atalho *Instalar aplicações*** fixado na dock (e no menu *Sistema*): abre o menu num terminal.
- **Linha de comandos:**
  ```
  instalar-aplicacoes                 # menu
  instalar-aplicacoes vscode          # Visual Studio Code  -> /opt/vscode, comando code
  instalar-aplicacoes chrome          # Google Chrome       -> /opt/google/chrome, comando google-chrome
  instalar-aplicacoes claude          # Claude Code         -> ~/.local/bin/claude (instalador oficial, sem sudo)
  instalar-aplicacoes codex           # Codex CLI + ripgrep -> /usr/local/bin/codex e /usr/local/bin/rg
  instalar-aplicacoes tudo            # as quatro
  instalar-aplicacoes -l              # estado (instalada? versão? onde?)
  ```
  Repetir o comando atualiza para a versão mais recente; `-f <app>` reinstala, `-s <app>` não pergunta
  nada. Espaço necessário: VS Code ~1,7 GB, Chrome ~0,9 GB, Claude Code ~0,8 GB, Codex ~0,5 GB.
- No fim da instalação do Chrome, ele passa a ser o **navegador predefinido** (xdg-mime, xdg-settings e
  as aplicações preferidas do Xfce).

### Loja (Flatpak + Flathub)
- Atalho **Loja** na dock (antes de *Instalar aplicações*) e no menu *Sistema*; ou o comando `loja`.
- *Descobrir* (destaques, populares e categorias), pesquisa, página de cada aplicação com
  *Instalar*/*Abrir*/*Remover* e barra de progresso, *Instaladas*, *Atualizações* e *Aplicações
  oficiais* (VS Code, Chrome, Claude Code e Codex, pelo `instalar-aplicacoes`).
- Instala só para o utilizador (`flatpak --user`, sem sudo), em `~/.local/share/flatpak`. No terminal:
  `flatpak install --user flathub <id>`. As aplicações instaladas aparecem no menu do Xfce (as primeiras
  podem pedir para sair e voltar a entrar). Os textos das aplicações vêm do Flathub (quase sempre em inglês).
- Sem persistência a Loja mostra uma faixa de aviso e pergunta antes da 1.ª instalação: use
  `sudo ianinja-persistencia listar` e `sudo ianinja-persistencia criar <id>` para as aplicações ficarem no disco de dados.

### Drivers e periféricos
- **Intel e AMD:** Mesa com OpenGL e **Vulkan** (anv/hasvk para Intel, radv para AMD; lavapipe por CPU em
  máquinas virtuais ou sem GPU suportada). Ver: `vulkaninfo --summary`.
- **NVIDIA:** por omissão o nouveau (livre). O driver oficial instala-se a pedido (Internet; ~2,6 GB
  livres durante a instalação):
  ```
  instalar-driver-nvidia -l           # placas, série recomendada e estado
  instalar-driver-nvidia              # deteta, pergunta e instala
  instalar-driver-nvidia --ativar     # troca já o nouveau pelo nvidia (reinicia a sessão gráfica)
  ```
  Turing (GTX 16xx, RTX 20xx) e mais recentes: série 620 com os módulos abertos; Maxwell, Pascal e Volta
  (GTX 750 a 1080 Ti): série 580; Kepler e anteriores: fica o nouveau. O atalho *Instalar driver NVIDIA*
  só aparece no menu quando há placa NVIDIA. Depois da instalação a NVIDIA passa a placa principal e o
  OpenGL de uma placa Intel/AMD do mesmo computador deixa de funcionar (nos portáteis híbridos os ecrãs
  ligados à Intel/AMD mostram a imagem desenhada pela NVIDIA).
- **Razer (OpenRazer):** módulos do kernel e serviço `openrazer-daemon`, que arranca sozinho na sessão
  gráfica quando há um periférico Razer ligado (o `ninja` já está no grupo `plugdev`). Comando `openrazer`:
  `openrazer -l` (dispositivos, bateria, brilho), `openrazer brilho <0-100> [N]`, `openrazer cor <RRGGBB> [N]`,
  `openrazer efeito espectro|respirar|onda|reativo|desligar [N] [RRGGBB]`.
- **HyperX, SteelSeries, Logitech, Corsair…:** headsets e placas de som USB funcionam com o ALSA;
  bateria, sidetone, luzes, equalizador e desligar automático com `headsetcontrol` (`headsetcontrol -h`
  mostra as opções). O OpenRGB não está incluído (é Qt).
- **Bluetooth:** BlueZ + **Blueman** (applet no painel, `blueman-manager`; na consola `bluetoothctl`).
  Teclados, ratos e comandos funcionam; **os headsets Bluetooth emparelham, mas sem som**: o áudio
  Bluetooth (A2DP/HFP) precisa de um servidor de som (PipeWire ou PulseAudio), que não está na ISO.
- **`info-hardware`** (atalho *Informação do hardware*): placas gráficas e driver em uso, OpenGL, Vulkan,
  som, periféricos gaming, OpenRazer, Bluetooth e Wi-Fi; `info-hardware -c` lista também todos os
  dispositivos PCI e USB.
- **Capturas de ecrã:** `Print` = ecrã inteiro, `Shift+Print` = região (xfce4-screenshooter);
  `Alt+Print` (janela) mantém-se.

### Programação
- Já incluído: GCC/G++, Make, CMake, Meson, Ninja, Git, Perl, LLVM/Clang, **Python 3.13** (pip, venv,
  sqlite3, requests, pytest), **Node.js 22 + npm**, **GDB** (com Python) e **Valgrind**.
- **Python:** `python3 -m venv .venv`, `. .venv/bin/activate`, `pip install <pacote>`; fora de um venv,
  `pip install` sem sudo instala na pasta pessoal (`~/.local`).
- **npm:** `npm install -g <pacote>` funciona **sem sudo** (vai para `~/.npm-global`, já no PATH);
  `sudo npm install -g` instala para todos.
- **A pedido** (atalho *Instalar ferramentas de programação* no menu *Desenvolvimento*, ou no terminal):
  ```
  instalar-ferramentas rust           # rustup: rustc, cargo, rustfmt, clippy -> ~/.cargo e ~/.rustup
  instalar-ferramentas go             # Go (go.dev)                           -> /usr/local/go
  instalar-ferramentas java           # OpenJDK LTS (Eclipse Temurin)         -> /opt/jdk
  instalar-ferramentas tudo
  instalar-ferramentas -l             # estado (inclui o que já vem no sistema)
  ```
  Repetir atualiza; `-f` reinstala, `-s` não pergunta. Nas sessões novas o PATH já inclui `~/.cargo/bin`
  e `~/go/bin`, e o `JAVA_HOME` fica definido.

### Face Finder (projeto de exemplo)
Programa em Python + OpenCV que **encontra e marca rostos** em fotografias (modelo YuNet; funciona sem
rede). Deteção não é reconhecimento: diz *onde* há rostos, não *quem* são.
- Projeto em `~/Projetos/face-finder` (código, modelo, 12 fotografias de licença livre, testes e
  configuração do VS Code); pode alterá-lo à vontade — o comando do sistema usa a cópia em
  `/usr/share/face-finder`.
- Interface gráfica: menu **Face Finder** (ou `face-finder-gui`).
- Linha de comandos:
  ```
  cd ~/Projetos/face-finder
  face-finder fotos -o saida --abrir        # marca os rostos e abre as imagens no Ristretto
  face-finder fotos --limiar 0.6            # mais sensível (mais rostos e mais enganos)
  python3 -m unittest discover -s tests -v  # testes do projeto
  ```
  Em `saida/` ficam as imagens `<nome>_rostos.jpg`, o `resultados.json` e o `relatorio.html`.
  Mais em `~/Projetos/face-finder/README.md`; no VS Code, abra a pasta e use *Executar e depurar*.

## Comandos úteis
```
ip addr                         # ver IP
loadkeys us                     # teclado americano
/etc/rc.d/init.d/sshd start     # ativar SSH
cat /etc/os-release
```

## Como foi construído
Num WSL2 (Ubuntu 24.04), numa imagem de disco montada em `/mnt/lfs`, por etapas que o
`scripts/run-all.sh` corre por ordem (estado em `progresso.json`, registo em `logs/registo.log`):

| Etapa | Script | O que faz |
|---|---|---|
| F0 | `scripts/f00-host.sh` | Preparação do host |
| F1 | `scripts/f01-preparacao.sh` | Imagem, fontes e utilizador lfs (Cap. 2-4) |
| F2 | `scripts/f02-cross-toolchain.sh` | Cross-toolchain (Cap. 5) |
| F3 | `scripts/f03-ferramentas-temp.sh` | Ferramentas temporárias (Cap. 6) |
| F4 | `scripts/f04-chroot.sh` | Chroot e ferramentas adicionais (Cap. 7) |
| F5 | `scripts/f05-sistema-base.sh` | Sistema base (Cap. 8) |
| F6 | `scripts/f06-configuracao.sh` | Configuração do sistema + identidade (Cap. 9) |
| F7 | `scripts/f07-kernel.sh` | Kernel e boot (Cap. 10) |
| F8 | `scripts/f08-blfs.sh` | Pacotes BLFS |
| F8b | `scripts/f08b-ia.sh` | Inteligência artificial (llama.cpp + modelo) |
| F8c | `scripts/f08c-drivers.sh` | Drivers e firmware |
| F8d | `scripts/f08d-gui.sh` | Interface gráfica (Xorg + Xfce, estilo macOS) |
| F8e | `scripts/f08e-apps.sh` | Aplicações, drivers, programação, loja e face-finder |
| F9 | `scripts/f09-live.sh` | Sistema live (initramfs + SquashFS) |
| F10 | `scripts/f10-iso.sh` | Geração da ISO |
| F11 | `scripts/f11-testes.sh` | Testes automáticos (QEMU BIOS/UEFI) |
| F12 | `scripts/f12-entrega.sh` | Entrega |

A interface gráfica (F8d) e os drivers/firmware (F8c) foram acrescentados depois da primeira ISO (só
consola); a F8d é construída a partir das páginas do BLFS listadas em `scripts/gui/ordem.txt`.
A F8e (aplicações, drivers, programação, loja e face-finder) veio a seguir, com o mesmo método: passos em
`scripts/apps/passos-0*.txt` e decisões em `scripts/apps/decisoes-0*.txt` (copiadas para `docs/DECISOES.md`).
Ver `ETAPAS.md` (etapas e registo), `docs/DECISOES.md` (decisões tomadas), `docs/RELATORIO-FINAL.md`
(tempos, testes e lista de pacotes), `docs/previsao-interface.html` (pré-visualização da interface),
`scripts/` (um script por etapa) e `logs/` (um log por pacote/passo; capturas do ecrã de início de
sessão dos testes em `logs/11-ecra-*.png`).
