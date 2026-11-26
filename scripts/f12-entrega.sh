#!/bin/bash
# F12 — Entrega: README, relatório final, desmontagem e cópia para o Windows
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
[ "$(etapa_estado F12)" = ok ] && exit 0
etapa_inicio F12
ISO=$P/output/ianinjapelagestao-12.4-x86_64.iso
WIN=/mnt/c/Users/User/Documents/ianinjapelagestao_iso
SHA=$(cut -d' ' -f1 $ISO.sha256)
[ "$(sha256sum $ISO | cut -d' ' -f1)" = "$SHA" ] || { etapa_fim F12 falhou "a ISO não corresponde a $ISO.sha256"; exit 1; }
TAM=$(du -h $ISO | cut -f1)
[ -f $ISO ] && [ -f $ISO.sha256 ] || { etapa_fim F12 falhou "ISO ou $ISO.sha256 em falta (F10)"; exit 1; }
n_lfs=$(awk '$2!="-"' $P/scripts/tarballs.txt | wc -l)                      # secções do LFS com tarball (passagens múltiplas contam)
n_blfs=$(ls $P/logs/f8-*.log 2>/dev/null | wc -l)                           # passos da F8 (BLFS base)
n_ia=$(ls $P/logs/f8b-*.log 2>/dev/null | wc -l)                            # passos da F8b (IA)
n_drv=$(ls $P/logs/f8c-*.log 2>/dev/null | wc -l)                           # passos da F8c (drivers e firmware)
# passos da F8d: o total registado pela própria etapa ("N passos: ..."), senão os logs (sem a cópia de segurança)
n_gui=$(jq -r '.etapas.F8d.notas // ""' $STATE | grep -o '^[0-9]\+ passos' | grep -o '^[0-9]\+' || true)
[ -n "$n_gui" ] || n_gui=$(ls $P/logs/f8d-*.log 2>/dev/null | grep -v 'f8d-copia-seguranca' | wc -l)
# passos da F8e: idem (total registado pela etapa, senão os logs sem a cópia de segurança)
n_apps=$(jq -r '.etapas.F8e.notas // ""' $STATE | grep -o '^[0-9]\+ passos' | grep -o '^[0-9]\+' || true)
[ -n "$n_apps" ] || n_apps=$(ls $P/logs/f8e-*.log 2>/dev/null | grep -v 'f8e-copia-seguranca' | wc -l)
SQ=$(du -h $P/iso-root/live/rootfs.squashfs 2>/dev/null | cut -f1); SQ=${SQ:-?}

cat > $P/README.md << EOF
# ianinjapelagestao 12.4

Distribuição Linux construída do zero seguindo o **Linux From Scratch 12.4 (System V)** e o
**Beyond Linux From Scratch 12.4**, entregue como **ISO live híbrida (BIOS + UEFI)**.

- Ficheiro: \`output/ianinjapelagestao-12.4-x86_64.iso\` ($TAM; dentro dela \`live/rootfs.squashfs\` com $SQ)
- SHA-256: \`$SHA\`
- Rótulo do volume: \`IANINJAPELAGESTAO\`
- Interface gráfica Xfce 4.20 com aspeto ao estilo do macOS (ver *Interface gráfica*)

## Como funciona
O GRUB carrega o kernel Linux 6.16.1 e um initramfs que procura o volume \`IANINJAPELAGESTAO\`,
monta \`live/rootfs.squashfs\` (xz) só-leitura e por cima uma camada de escrita em RAM (OverlayFS).
**Tudo o que alterar perde-se ao desligar** (a menos que exista um disco de dados \`IANINJA-DADOS\`:
ver \`/usr/share/doc/ianinjapelagestao/README\` no sistema).
O sistema arranca no nível 5 (SysVinit): o LightDM mostra o ecrã de início de sessão no \`vt7\`;
as consolas de texto \`tty1\`–\`tty6\` e a consola série \`ttyS0\` continuam com login.

## Requisitos
- **RAM:** mínimo 2 GB (interface gráfica sem IA); recomendado 4 GB (interface gráfica + modelo de IA local).
- CPU x86-64; placa gráfica com driver KMS no kernel (Intel, AMD, NVIDIA/nouveau, VMware/VirtualBox
  VMSVGA, QEMU std/virtio). Sem aceleração 3D o Mesa desenha por CPU (llvmpipe).

## Contas
O sistema live tem as contas \`root\` e \`ninja\` (o \`ninja\` tem sudo sem senha, \`/etc/sudoers.d/ninja\`).
As senhas **não estão no repositório**: na construção vêm de \`scripts/senhas.local\`
(ver \`scripts/senhas.local.exemplo\`); se esse ficheiro não existir, são geradas senhas aleatórias.
No primeiro arranque o assistente cria a sua própria conta e esconde o \`ninja\`.

## Gravar numa pen USB
- **Windows:** [Rufus](https://rufus.ie) → escolher a ISO → *modo de imagem DD* (quando perguntar) → Iniciar.
  Ou [balenaEtcher](https://etcher.balena.io) → Flash from file → escolher a pen → Flash.
- **Linux:** \`sudo dd if=ianinjapelagestao-12.4-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync\`
  (confirme \`/dev/sdX\` com \`lsblk\` — o conteúdo da pen é apagado).

Arranque o PC pela pen (menu de boot da BIOS/UEFI; desative o *Secure Boot*, o GRUB não está assinado).

## Testar numa máquina virtual
- **QEMU (BIOS):** \`qemu-system-x86_64 -enable-kvm -m 4096 -smp 2 -vga std -cdrom ianinjapelagestao-12.4-x86_64.iso -boot d -nic user,model=e1000\`
  (\`-vga virtio\` também funciona; sem KVM tire \`-enable-kvm\`, mas o arranque gráfico demora vários minutos)
- **QEMU (UEFI):** acrescentar \`-bios /usr/share/ovmf/OVMF.fd\`
- **VirtualBox:** Nova VM → Tipo *Linux*, Versão *Other Linux (64-bit)*, 4096 MB RAM (mínimo 2048), sem disco →
  Definições → Ecrã → Controlador gráfico **VMSVGA**, memória de vídeo 128 MB (*Ativar aceleração 3D* é
  opcional) → Armazenamento → unidade ótica → escolher a ISO → (opcional: Sistema → *Ativar EFI*) → Iniciar.
  Rede: NAT com adaptador *Intel PRO/1000*.

Menu do GRUB:
| Entrada | O que faz |
|---|---|
| *ianinjapelagestao 12.4 (Live)* | por omissão: interface gráfica (LightDM + Xfce) |
| *Live - modo gráfico de compatibilidade* | \`nomodeset\` com interface gráfica sobre a imagem do firmware (simpledrm, sem aceleração): para PCs em que o ecrã fica preto com o driver normal da placa |
| *Live - modo texto, sem interface gráfica* | nível 3: só consolas de texto (\`3\` na linha do kernel) |
| *Live - modo seguro/verbose* | \`nomodeset\`, mensagens completas, modo texto (sem KMS o Xorg não arranca) |
| *sem persistência* | interface gráfica, ignora o disco de dados \`IANINJA-DADOS\` |

A consola série \`ttyS0\` (115200) também tem login.

## Interface gráfica
Ambiente de trabalho **Xfce 4.20** sobre o **Xorg** (driver modesetting, Mesa), com o gestor de
sessões **LightDM** (ecrã *lightdm-gtk-greeter*) e um aspeto ao estilo do macOS: tema **WhiteSur**
(GTK, janelas, ícones e cursores), barra superior e dock em baixo, botões das janelas à esquerda,
fonte **Inter** (e JetBrains Mono no terminal), papel de parede e logótipo próprios.

- **Entrar:** no ecrã de início de sessão escolha \`ninja\` e escreva a senha definida em \`scripts/senhas.local\`.
  O \`root\` não aparece na lista (use \`sudo\` no terminal, ou uma consola de texto).
- **Consolas de texto:** \`Ctrl+Alt+F1\` … \`Ctrl+Alt+F6\` (login de texto normal);
  voltar ao ambiente gráfico: \`Ctrl+Alt+F7\`.
- **Pesquisa rápida de aplicações:** \`Super+Espaço\` (tecla Windows + Espaço).
- **Sem interface gráfica:** entrada *modo texto* do GRUB (ou carregar \`e\` no GRUB e acrescentar \` 3\`
  à linha \`linux\`); com o sistema já arrancado: \`sudo telinit 3\` (voltar: \`sudo telinit 5\`).
- **Problemas:** \`/var/log/Xorg.0.log\` e \`/var/log/lightdm/\`; se o ecrã ficar preto, use o *modo gráfico de compatibilidade*
  (ou o *modo seguro*, só texto). Se o X falhar 3 vezes seguidas o sistema volta sozinho à consola
  \`tty1\` com um aviso (registo \`/var/log/ianinja-dm.log\`; tentar outra vez: \`sudo ianinja-dm repor\`).
- Teclado português no X (\`setxkbmap us\` para americano).

## O que está incluído
- **Sistema base LFS 12.4 (Cap. 5–8):** $n_lfs pacotes/secções (passagens múltiplas contam à parte), entre eles Glibc 2.42, GCC 15.2.0, Binutils 2.45,
  Bash 5.3, Coreutils 9.7, Perl 5.42, Python 3.13.7, OpenSSL 3.5.2, Vim, GRUB 2.12, Udev (systemd 257.8),
  SysVinit 3.14, Kbd, IPRoute2, E2fsprogs.
- **BLFS 12.4 (F8):** $n_blfs passos — bootscripts BLFS, make-ca/p11-kit (certificados), Linux-PAM, Shadow com PAM,
  Sudo, dhcpcd, Wget, cURL, OpenSSH, Nano, cpio, dosfstools, efivar, efibootmgr, pciutils, usbutils, which, tree
  (lista exata em \`docs/RELATORIO-FINAL.md\`).
- **Interface gráfica (F8d, BLFS 12.4, $n_gui passos):** Xorg-Server 21.1 + bibliotecas, aplicações e tipos de letra
  do Xorg, Mesa (iris/crocus/i915, radeonsi/r600/r300, nouveau, svga, virgl, llvmpipe) com LLVM/Clang,
  libinput, D-Bus, elogind, Polkit, GLib, GTK3, Pango, Cairo, HarfBuzz, librsvg, Xfce 4.20 (painel, xfwm4,
  Thunar, xfdesktop, terminal, appfinder, notificações), xfce4-docklike-plugin (dock), LightDM +
  lightdm-gtk-greeter; temas WhiteSur (GTK, ícones, cursores), fontes Inter, JetBrains Mono, DejaVu e Liberation.
- **Drivers e firmware (F8c, $n_drv passos):** kernel com drivers em módulos (carregados pelo udev), linux-firmware,
  microcódigo do CPU, Wi-Fi (libnl, wpa_supplicant, iw, \`ligar-wifi\`), som ALSA (alsa-lib, alsa-utils).
- **IA local (F8b, $n_ia passos):** llama.cpp com um modelo pequeno (Qwen2.5-1.5B): \`ia-perguntar\`, e um chat
  automático quando o \`ninja\` entra numa consola de texto \`tty1\`–\`tty6\` (\`Ctrl+C\` ou \`/sair\` volta à shell).
- **Aplicações, drivers, programação e loja (F8e, $n_apps passos):** NSPR/NSS, libcups, libsecret e
  xdg-utils para as aplicações instaladas a pedido (VS Code, Chrome, Claude Code, Codex); headers do kernel,
  Vulkan (Mesa com anv/hasvk/radv/lavapipe, vulkaninfo), OpenRazer, hidapi + HeadsetControl, BlueZ + Blueman,
  xfce4-screenshooter; Python com sqlite3/requests/pytest, Node.js 22 + npm, GDB, Valgrind; OSTree + Flatpak,
  xdg-desktop-portal(-gtk) e a Loja (Flathub); OpenCV, NumPy, PyGObject, Ristretto e o projeto face-finder
  (ver *Aplicações, drivers e loja*).
- Locale \`pt_PT.UTF-8\` (+ \`en_US.UTF-8\`), fuso \`Europe/Lisbon\`, teclado \`pt-latin1\`, hostname \`ianinjapelagestao\`.
- Rede automática: \`dhcpcd\` em \`eth0\` (nomes clássicos com \`net.ifnames=0\`).

## Aplicações, drivers e loja
O que a ISO não pode levar por licença (VS Code, Google Chrome, Claude Code, Codex) instala-se no 1.º
uso, a partir dos sites oficiais (com Internet; SHA-256 verificado); o resto já vem no sistema.
**Numa sessão live sem disco de dados \`IANINJA-DADOS\` tudo o que instalar fica na RAM e perde-se ao
desligar** — no 1.º arranque o assistente pergunta onde guardar os dados (partição nova na própria pen, ficheiro no
disco do Windows ou uma partição formatada); na consola: \`sudo ianinja-persistencia listar\` e \`criar <id>\`.

### VS Code, Google Chrome, Claude Code e Codex
- **Assistente automático:** no 1.º início de sessão, com Internet e se faltar alguma das quatro, abre-se
  um terminal com \`instalar-aplicacoes tudo\` (aceite cada licença). Pergunta uma só vez por pasta
  pessoal; para voltar a perguntar: \`instalar-tudo-click.sh --agora\`.
- **Atalho *Instalar aplicações*** fixado na dock (e no menu *Sistema*): abre o menu num terminal.
- **Linha de comandos:**
  \`\`\`
  instalar-aplicacoes                 # menu
  instalar-aplicacoes vscode          # Visual Studio Code  -> /opt/vscode, comando code
  instalar-aplicacoes chrome          # Google Chrome       -> /opt/google/chrome, comando google-chrome
  instalar-aplicacoes claude          # Claude Code         -> ~/.local/bin/claude (instalador oficial, sem sudo)
  instalar-aplicacoes codex           # Codex CLI + ripgrep -> /usr/local/bin/codex e /usr/local/bin/rg
  instalar-aplicacoes tudo            # as quatro
  instalar-aplicacoes -l              # estado (instalada? versão? onde?)
  \`\`\`
  Repetir o comando atualiza para a versão mais recente; \`-f <app>\` reinstala, \`-s <app>\` não pergunta
  nada. Espaço necessário: VS Code ~1,7 GB, Chrome ~0,9 GB, Claude Code ~0,8 GB, Codex ~0,5 GB.
- No fim da instalação do Chrome, ele passa a ser o **navegador predefinido** (xdg-mime, xdg-settings e
  as aplicações preferidas do Xfce).

### Loja (Flatpak + Flathub)
- Atalho **Loja** na dock (antes de *Instalar aplicações*) e no menu *Sistema*; ou o comando \`loja\`.
- *Descobrir* (destaques, populares e categorias), pesquisa, página de cada aplicação com
  *Instalar*/*Abrir*/*Remover* e barra de progresso, *Instaladas*, *Atualizações* e *Aplicações
  oficiais* (VS Code, Chrome, Claude Code e Codex, pelo \`instalar-aplicacoes\`).
- Instala só para o utilizador (\`flatpak --user\`, sem sudo), em \`~/.local/share/flatpak\`. No terminal:
  \`flatpak install --user flathub <id>\`. As aplicações instaladas aparecem no menu do Xfce (as primeiras
  podem pedir para sair e voltar a entrar). Os textos das aplicações vêm do Flathub (quase sempre em inglês).
- Sem persistência a Loja mostra uma faixa de aviso e pergunta antes da 1.ª instalação: use
  \`sudo ianinja-persistencia listar\` e \`sudo ianinja-persistencia criar <id>\` para as aplicações ficarem no disco de dados.

### Drivers e periféricos
- **Intel e AMD:** Mesa com OpenGL e **Vulkan** (anv/hasvk para Intel, radv para AMD; lavapipe por CPU em
  máquinas virtuais ou sem GPU suportada). Ver: \`vulkaninfo --summary\`.
- **NVIDIA:** por omissão o nouveau (livre). O driver oficial instala-se a pedido (Internet; ~2,6 GB
  livres durante a instalação):
  \`\`\`
  instalar-driver-nvidia -l           # placas, série recomendada e estado
  instalar-driver-nvidia              # deteta, pergunta e instala
  instalar-driver-nvidia --ativar     # troca já o nouveau pelo nvidia (reinicia a sessão gráfica)
  \`\`\`
  Turing (GTX 16xx, RTX 20xx) e mais recentes: série 620 com os módulos abertos; Maxwell, Pascal e Volta
  (GTX 750 a 1080 Ti): série 580; Kepler e anteriores: fica o nouveau. O atalho *Instalar driver NVIDIA*
  só aparece no menu quando há placa NVIDIA. Depois da instalação a NVIDIA passa a placa principal e o
  OpenGL de uma placa Intel/AMD do mesmo computador deixa de funcionar (nos portáteis híbridos os ecrãs
  ligados à Intel/AMD mostram a imagem desenhada pela NVIDIA).
- **Razer (OpenRazer):** módulos do kernel e serviço \`openrazer-daemon\`, que arranca sozinho na sessão
  gráfica quando há um periférico Razer ligado (o \`ninja\` já está no grupo \`plugdev\`). Comando \`openrazer\`:
  \`openrazer -l\` (dispositivos, bateria, brilho), \`openrazer brilho <0-100> [N]\`, \`openrazer cor <RRGGBB> [N]\`,
  \`openrazer efeito espectro|respirar|onda|reativo|desligar [N] [RRGGBB]\`.
- **HyperX, SteelSeries, Logitech, Corsair…:** headsets e placas de som USB funcionam com o ALSA;
  bateria, sidetone, luzes, equalizador e desligar automático com \`headsetcontrol\` (\`headsetcontrol -h\`
  mostra as opções). O OpenRGB não está incluído (é Qt).
- **Bluetooth:** BlueZ + **Blueman** (applet no painel, \`blueman-manager\`; na consola \`bluetoothctl\`).
  Teclados, ratos e comandos funcionam; **os headsets Bluetooth emparelham, mas sem som**: o áudio
  Bluetooth (A2DP/HFP) precisa de um servidor de som (PipeWire ou PulseAudio), que não está na ISO.
- **\`info-hardware\`** (atalho *Informação do hardware*): placas gráficas e driver em uso, OpenGL, Vulkan,
  som, periféricos gaming, OpenRazer, Bluetooth e Wi-Fi; \`info-hardware -c\` lista também todos os
  dispositivos PCI e USB.
- **Capturas de ecrã:** \`Print\` = ecrã inteiro, \`Shift+Print\` = região (xfce4-screenshooter);
  \`Alt+Print\` (janela) mantém-se.

### Programação
- Já incluído: GCC/G++, Make, CMake, Meson, Ninja, Git, Perl, LLVM/Clang, **Python 3.13** (pip, venv,
  sqlite3, requests, pytest), **Node.js 22 + npm**, **GDB** (com Python) e **Valgrind**.
- **Python:** \`python3 -m venv .venv\`, \`. .venv/bin/activate\`, \`pip install <pacote>\`; fora de um venv,
  \`pip install\` sem sudo instala na pasta pessoal (\`~/.local\`).
- **npm:** \`npm install -g <pacote>\` funciona **sem sudo** (vai para \`~/.npm-global\`, já no PATH);
  \`sudo npm install -g\` instala para todos.
- **A pedido** (atalho *Instalar ferramentas de programação* no menu *Desenvolvimento*, ou no terminal):
  \`\`\`
  instalar-ferramentas rust           # rustup: rustc, cargo, rustfmt, clippy -> ~/.cargo e ~/.rustup
  instalar-ferramentas go             # Go (go.dev)                           -> /usr/local/go
  instalar-ferramentas java           # OpenJDK LTS (Eclipse Temurin)         -> /opt/jdk
  instalar-ferramentas tudo
  instalar-ferramentas -l             # estado (inclui o que já vem no sistema)
  \`\`\`
  Repetir atualiza; \`-f\` reinstala, \`-s\` não pergunta. Nas sessões novas o PATH já inclui \`~/.cargo/bin\`
  e \`~/go/bin\`, e o \`JAVA_HOME\` fica definido.

### Face Finder (projeto de exemplo)
Programa em Python + OpenCV que **encontra e marca rostos** em fotografias (modelo YuNet; funciona sem
rede). Deteção não é reconhecimento: diz *onde* há rostos, não *quem* são.
- Projeto em \`~/Projetos/face-finder\` (código, modelo, 12 fotografias de licença livre, testes e
  configuração do VS Code); pode alterá-lo à vontade — o comando do sistema usa a cópia em
  \`/usr/share/face-finder\`.
- Interface gráfica: menu **Face Finder** (ou \`face-finder-gui\`).
- Linha de comandos:
  \`\`\`
  cd ~/Projetos/face-finder
  face-finder fotos -o saida --abrir        # marca os rostos e abre as imagens no Ristretto
  face-finder fotos --limiar 0.6            # mais sensível (mais rostos e mais enganos)
  python3 -m unittest discover -s tests -v  # testes do projeto
  \`\`\`
  Em \`saida/\` ficam as imagens \`<nome>_rostos.jpg\`, o \`resultados.json\` e o \`relatorio.html\`.
  Mais em \`~/Projetos/face-finder/README.md\`; no VS Code, abra a pasta e use *Executar e depurar*.

## Comandos úteis
\`\`\`
ip addr                         # ver IP
loadkeys us                     # teclado americano
/etc/rc.d/init.d/sshd start     # ativar SSH
cat /etc/os-release
\`\`\`

## Como foi construído
Num WSL2 (Ubuntu 24.04), numa imagem de disco montada em \`/mnt/lfs\`, por etapas que o
\`scripts/run-all.sh\` corre por ordem (estado em \`progresso.json\`, registo em \`logs/registo.log\`):

| Etapa | Script | O que faz |
|---|---|---|
$(for id in "${ETAPA_IDS[@]}"; do
  s=$(ls $P/scripts/f$(printf '%02d' "$(echo $id | tr -dc 0-9)" 2>/dev/null)$(echo $id | tr -d 'F0-9')-*.sh 2>/dev/null | head -1)
  echo "| $id | \`${s:+scripts/$(basename $s)}\` | $(jq -r --arg id $id '.etapas[$id].nome // "—"' $STATE) |"
done)

A interface gráfica (F8d) e os drivers/firmware (F8c) foram acrescentados depois da primeira ISO (só
consola); a F8d é construída a partir das páginas do BLFS listadas em \`scripts/gui/ordem.txt\`.
A F8e (aplicações, drivers, programação, loja e face-finder) veio a seguir, com o mesmo método: passos em
\`scripts/apps/passos-0*.txt\` e decisões em \`scripts/apps/decisoes-0*.txt\` (copiadas para \`docs/DECISOES.md\`).
Ver \`ETAPAS.md\` (etapas e registo), \`docs/DECISOES.md\` (decisões tomadas), \`docs/RELATORIO-FINAL.md\`
(tempos, testes e lista de pacotes), \`docs/previsao-interface.html\` (pré-visualização da interface),
\`scripts/\` (um script por etapa) e \`logs/\` (um log por pacote/passo; capturas do ecrã de início de
sessão dos testes em \`logs/11-ecra-*.png\`).
EOF

# Relatório final
{
  echo "# ianinjapelagestao 12.4 — Relatório final"
  echo
  ini=$(jq -r '[.etapas[]|select(.inicio_ts>0)|.inicio_ts]|min' $STATE)
  fim=$(date +%s)
  echo "- Início: $(jq -r .inicio $STATE) · Fim: $(agora) · **Duração total: $(_dur $((fim-ini)))**"
  echo "- Host: WSL2 Ubuntu 24.04 em Windows 11, $(nproc) núcleos, $(free -g | awk '/Mem:/{print $2}') GB RAM atribuídos"
  echo "- ISO: \`output/ianinjapelagestao-12.4-x86_64.iso\` — **$TAM** — SHA-256 \`$SHA\`"
  echo "- Pacotes: $n_lfs do LFS (Cap. 5–8, contando passagens múltiplas) + passos BLFS: $n_blfs (F8, base) + $n_ia (F8b, IA) + $n_drv (F8c, drivers e firmware) + $n_gui (F8d, interface gráfica) + $n_apps (F8e, aplicações, drivers, programação e loja)"
  echo
  echo "## Tempo por etapa"
  echo
  echo "| Etapa | Nome | Estado | Duração | Notas |"
  echo "|---|---|---|---|---|"
  for id in "${ETAPA_IDS[@]}"; do
    jq -r --arg id "$id" '.etapas[$id] | "\(.inicio_ts // 0) \(.fim_ts // 0) \(.estado // "pendente")\t\(.nome // "")\t\((.notas // "") | gsub("\\|"; "/") | gsub("\n"; " "))"' $STATE |
    while IFS=$'\t' read -r a nome notas; do
      set -- $a
      d="—"; if [ "$2" -gt 0 ] && [ "$1" -gt 0 ]; then d=$(_dur $(( $2 - $1 ))); fi
      # a própria F12 ainda está em curso quando o relatório é escrito
      if [ "$id" = F12 ] && [ "$2" -eq 0 ] && [ "$1" -gt 0 ]; then set -- "$1" 0 ok; notas="README, relatório e cópia para o Windows"; d=$(_dur $(( $(date +%s) - $1 ))); fi
      echo "| $id | $nome | $3 | $d | $notas |"
    done
  done
  echo
  echo "## Testes automáticos (F11, QEMU headless)"
  for m in bios uefi; do
    echo; echo "### ${m^^}"; echo; echo '```'; cat $P/logs/11-resultado-$m.txt 2>/dev/null; echo '```'
    if [ -f $P/logs/11-ecra-$m.png ]; then echo; echo "Captura do ecrã de início de sessão: \`logs/11-ecra-$m.png\`"; fi
  done
  if [ -f $P/logs/11-resultado-persistencia.txt ]; then
    echo; echo "### Persistência"; echo; echo '```'; cat $P/logs/11-resultado-persistencia.txt; echo '```'
  fi
  echo
  echo "## Test suites obrigatórias (Cap. 8)"
  echo
  (grep -h 'Test suite' $REGISTO || true) | sed 's/^- [0-9-]* [0-9:]* — /- /'
  echo
  echo "## Pacotes com falhas de testes toleradas"
  echo
  (grep -l 'AVISO-TESTE' $P/logs/0*.log 2>/dev/null || true) | xargs -r -n1 basename | sed 's/^/- /'
  echo
  for g in "f8|F8 — pacotes BLFS (base)" "f8b|F8b — inteligência artificial" \
           "f8c|F8c — drivers e firmware" "f8d|F8d — interface gráfica (pela ordem da build)" \
           "f8e|F8e — aplicações, drivers, programação, loja e face-finder (pela ordem da build)"; do
    pre=${g%%|*}
    echo "## Passos ${g#*|}"
    echo
    if [ $pre = f8d ] && [ -f $P/scripts/gui/ordem.txt ]; then
      # ordem real dos passos (scripts/gui/passos-NN.txt), só os que têm log
      cat $P/scripts/gui/passos-0[1-9].txt 2>/dev/null | sed 's/[[:space:]]*#.*$//' | grep -v '^[[:space:]]*$' |
        cut -d'|' -f1 | while read -r n; do [ -f $P/logs/f8d-$n.log ] && echo "- $n"; done || true
    elif [ $pre = f8e ] && ls $P/scripts/apps/passos-[0-9][0-9].txt > /dev/null 2>&1; then
      # ordem real dos passos (scripts/apps/passos-NN.txt), só os que têm log
      cat $P/scripts/apps/passos-[0-9][0-9].txt 2>/dev/null | sed 's/[[:space:]]*#.*$//' | grep -v '^[[:space:]]*$' |
        cut -d'|' -f1 | while read -r n; do [ -f $P/logs/f8e-$n.log ] && echo "- $n"; done || true
    else
      (ls $P/logs/$pre-*.log 2>/dev/null || true) | xargs -r -n1 basename | sed "s/^$pre-//;s/\.log\$//;s/^/- /"
    fi
    echo
  done
  echo "## Decisões tomadas"
  echo
  grep '^## ' $P/docs/DECISOES.md | sed 's/^## /- /'
  echo
  echo "Detalhes em \`docs/DECISOES.md\`."
  echo
  echo "## Avisos conhecidos"
  echo
  echo "- O GRUB da ISO não está assinado: em PCs com *Secure Boot* ativo é preciso desativá-lo."
  echo "- Sistema live: sem um disco de dados \`IANINJA-DADOS\` as alterações vivem em RAM e perdem-se ao desligar."
  echo "- Interface gráfica só X11 (sem Wayland). Com \`nomodeset\` o Xorg usa o simpledrm (imagem do firmware, sem aceleração nem mudança de resolução): entrada *modo gráfico de compatibilidade*; o *modo seguro* arranca só em texto."
  echo "- Em VMs sem aceleração 3D o Mesa desenha por CPU (llvmpipe): o ambiente funciona, mas mais devagar."
  echo "- VS Code, Google Chrome, Claude Code, Codex, o driver oficial da NVIDIA, Rust, Go e Java não vão na ISO (licença ou tamanho): instalam-se a pedido, com Internet (\`instalar-aplicacoes\`, \`instalar-driver-nvidia\`, \`instalar-ferramentas\`)."
  echo "- Bluetooth sem áudio: os headsets emparelham, mas o A2DP/HFP precisa de PipeWire ou PulseAudio (não incluídos). O CUPS está instalado, mas não arranca nem tem o cups-filters."
  echo "- Com o driver oficial da NVIDIA instalado, o OpenGL de outra placa Intel/AMD do mesmo computador deixa de funcionar."
  echo "- As chaves de host SSH (se o sshd for ativado) são geradas no arranque e mudam a cada boot."
  echo
  echo "## Falhas durante a build (corrigidas e retomadas; últimas 20)"
  echo
  (grep -h 'falhou\|AVISO' $REGISTO || true) | grep -v 'tentativa' | sed 's/^- //;s/^/- /' | tail -20 || true
} > $P/docs/RELATORIO-FINAL.md

# Desmontagem limpa
umount -R $LFS 2>/dev/null || true
for l in $(losetup -j $P/lfs.img | cut -d: -f1); do losetup -d $l; done

# Cópia para a pasta do projeto no Windows
mkdir -p $WIN/output $WIN/docs $WIN/logs $WIN/scripts
# espaço livre no C: (a ISO tem 2-3 GB; a cópia antiga com o mesmo nome é substituída, conta como livre)
precisa=$(( $(stat -c %s $ISO) + $(du -sb $P/logs $P/scripts $P/docs | awk '{s+=$1} END{print s}') + 512*1024*1024 ))
livre=$(df -B1 --output=avail $WIN | tail -1 | tr -d ' ')
antiga=$(stat -c %s $WIN/output/$(basename $ISO) 2>/dev/null || echo 0)
if [ $(( livre + antiga )) -lt $precisa ]; then
  etapa_fim F12 falhou "sem espaço no C: — livres $(( (livre+antiga)/1024/1024 )) MiB, precisa de $(( precisa/1024/1024 )) MiB"
  exit 1
fi
rm -f $WIN/output/$(basename $ISO)
cp $ISO $ISO.sha256 $WIN/output/
# confirmar a cópia (o 9p do WSL para o C: pode falhar a meio sem erro visível)
SHA_WIN=$(sha256sum $WIN/output/$(basename $ISO) | cut -d' ' -f1)
if [ "$SHA_WIN" != "$SHA" ]; then
  etapa_fim F12 falhou "a ISO copiada para o Windows tem SHA-256 diferente ($SHA_WIN ≠ $SHA)"
  exit 1
fi
cp $P/README.md $P/ETAPAS.md $P/progresso.json $WIN/
cp $P/docs/*.md $WIN/docs/
# pré-visualização da interface gráfica (página HTML), se existir
if [ -f $P/docs/previsao-interface.html ]; then cp $P/docs/previsao-interface.html $WIN/docs/; fi
# capturas do greeter dos testes F11 (logs/11-ecra-*.png) vão com os logs
cp $P/logs/*.log $P/logs/*.txt $WIN/logs/ 2>/dev/null || true
cp $P/logs/*.png $WIN/logs/ 2>/dev/null || true
cp -r $P/scripts/. $WIN/scripts/
etapa_fim F12 ok "ISO e documentação copiadas para C:\\Users\\User\\Documents\\ianinjapelagestao_iso"
cp $P/ETAPAS.md $P/progresso.json $WIN/
