# PROJETO **ianinjapelagestao** — Prompt de execução autónoma para IA

> **Como usar:** cole este ficheiro inteiro (ou anexe-o) numa IA com acesso a terminal Linux (ex.: Claude Code, agente com shell) e escreva apenas: **"Execute este projeto do início ao fim."**

---

## 0. MISSÃO

Você é um engenheiro de sistemas autónomo. A sua missão é construir, **do zero e sozinho**, uma distribuição Linux chamada **`ianinjapelagestao`**, seguindo **exatamente** os dois livros oficiais abaixo, e entregá-la como uma **imagem `.iso` inicializável (live)**, testada e documentada.

| Fonte | URL | Uso |
|---|---|---|
| **LFS 12.4 (System V)** | https://www.linuxfromscratch.org/lfs/view/12.4/ | Sistema base completo (Cap. 2 a 10) |
| **BLFS 12.4 (System V)** | https://www.linuxfromscratch.org/blfs/view/12.4/ | Pacotes extra (rede, segurança, initramfs, UEFI, ISO) |

Os livros são a **fonte de verdade**. Antes de compilar cada pacote, abra a página correspondente do livro e transcreva os comandos **tal como estão**. Não invente flags, não use versões diferentes das do livro.

---

## 1. REGRA PRINCIPAL — AUTONOMIA TOTAL

O dono do projeto **não vai mexer em nada**. Portanto:

1. **Nunca faça perguntas** nem espere aprovação. Todas as decisões já estão tomadas na Secção 3. Se surgir algo não previsto, escolha a opção mais conservadora/recomendada pelo livro, **registe a decisão** em `docs/DECISOES.md` e continue.
2. **Nunca peça ao utilizador** para executar comandos, editar ficheiros, reiniciar ou instalar algo. Faça tudo você.
3. **Nunca toque em discos reais do host.** Todo o sistema LFS é construído dentro de um **ficheiro de imagem** montado via loop (`lfs.img`). Proibido: `fdisk`/`mkfs`/`dd` em `/dev/sdX`, `/dev/nvmeX`, etc.
4. **Recuperação de erros sozinha:** em caso de falha, (a) leia o log, (b) consulte a página do pacote e a **errata** do LFS 12.4, (c) corrija e repita — até **3 tentativas** por passo. Só pare definitivamente se for impossível continuar; nesse caso deixe o estado exato e a causa em `ETAPAS.md`.
5. **Processos longos:** a compilação demora horas. Execute em segundo plano (`nohup`/`tmux`/`screen`), monitorize os logs periodicamente e nunca deixe o seu próprio timeout matar a build.
6. **Retomável:** se a sessão cair, ao recomeçar leia `progresso.json` e continue do último passo concluído — nunca recomece do zero sem necessidade.

---

## 2. AMBIENTE DE CONSTRUÇÃO (HOST)

Assuma um host Linux x86_64 (preferencialmente Ubuntu/Debian recente) com `sudo` e internet. Requisitos mínimos: **4+ núcleos, 8 GB RAM, 60 GB livres**.

### 2.1 Preparar o host (automático)
```bash
sudo apt-get update
sudo apt-get install -y build-essential bison gawk texinfo m4 python3 patch \
  wget curl xz-utils bzip2 gzip tar file \
  xorriso squashfs-tools mtools dosfstools grub-common grub-pc-bin grub-efi-amd64-bin \
  qemu-system-x86 ovmf expect tmux
# LFS exige /bin/sh -> bash
sudo ln -sf bash /bin/sh
```
Depois execute o script **`version-check.sh`** da página *Host System Requirements* (LFS Cap. 2.2) e grave a saída em `logs/00-version-check.log`. Corrija qualquer requisito em falta antes de avançar.

### 2.2 Estrutura de pastas do projeto
```
~/ianinjapelagestao/
├── ETAPAS.md              # ficheiro de etapas (humano) — SEMPRE atualizado
├── progresso.json         # estado máquina (para retomar)
├── README.md              # como usar a ISO (gerado no fim)
├── scripts/               # um script por etapa + run-all.sh (orquestrador)
├── logs/                  # um log por pacote/passo
├── docs/DECISOES.md       # decisões tomadas sozinho
├── docs/RELATORIO-FINAL.md
├── lfs.img                # imagem de 40 GB (ext4) montada em /mnt/lfs
├── iso-root/              # árvore da ISO
└── output/ianinjapelagestao-12.4-x86_64.iso (+ .sha256)
```

---

## 3. DECISÕES JÁ TOMADAS (não perguntar)

| Item | Decisão |
|---|---|
| Nome da distro | `ianinjapelagestao` |
| Base | LFS 12.4 **System V** + BLFS 12.4 System V |
| Arquitetura | x86_64 |
| Destino da build | Ficheiro `lfs.img` 40 GB ext4, loop em `/mnt/lfs` (`LFS=/mnt/lfs`) |
| Paralelismo | `MAKEFLAGS=-j$(nproc)`, `TESTSUITEFLAGS=-j$(nproc)` |
| Test suites | **Obrigatórias**: Glibc, GCC, Binutils, GMP, MPFR, MPC (Cap. 8). Restantes: opcionais, executar só se não atrasarem muito |
| Locale / fuso | `pt_PT.UTF-8` + `en_US.UTF-8`; fuso `Europe/Lisbon`; teclado `pt-latin1` |
| Hostname | `ianinjapelagestao` |
| Utilizadores | `root` e `ninja` (com `sudo`); senhas em `scripts/senhas.local`, fora do Git |
| Rede | `dhcpcd` em `eth0` (kernel com `net.ifnames=0`) |
| Formato final | **ISO híbrida live** BIOS + UEFI, rootfs em **SquashFS (xz)** + **OverlayFS** em tmpfs |
| Rótulo do volume | `IANINJAPELAGESTAO` |
| Gerador da ISO | `grub-mkrescue` (host) com `xorriso` |

---

## 4. FICHEIRO DE ETAPAS (OBRIGATÓRIO)

Crie **`ETAPAS.md`** logo no início e atualize-o **a cada etapa iniciada/concluída** (e a cada pacote no Cap. 8). Formato:

```markdown
# ianinjapelagestao — Etapas do Projeto
Início: <data/hora> | Última atualização: <data/hora> | Progresso global: 37 %

| # | Etapa | Estado | Início | Fim | Duração | Notas |
|---|-------|--------|--------|-----|---------|-------|
| F0 | Preparação do host | ✅ Concluída | ... | ... | 6 min | version-check OK |
| F1 | Imagem, fontes e utilizador lfs | 🔄 Em curso | ... | — | — | 72/95 pacotes baixados |
| F2 | ... | ⏳ Pendente | | | | |

Legenda: ⏳ Pendente · 🔄 Em curso · ✅ Concluída · ⚠️ Concluída c/ aviso · ❌ Falhou

## Registo detalhado
- 2026-11-04 19:02 — Binutils-2.45 Pass 1 compilado (log: logs/05-binutils-p1.log)
```

Mantenha em paralelo `progresso.json` (`{"etapa_atual":"F5","passo":"gcc","tentativas":1,...}`).

---

## 5. PLANO DE EXECUÇÃO — ETAPAS

### F0 — Preparação do host
- Secção 2.1 completa; criar estrutura da Secção 2.2; criar `ETAPAS.md` e `progresso.json`.

### F1 — Preparação (LFS Cap. 2, 3, 4)
- Criar `lfs.img` (`truncate -s 40G`), `mkfs.ext4`, montar via loop em `/mnt/lfs`; `export LFS=/mnt/lfs`, `umask 022`.
- Cap. 3: descarregar **todos os pacotes e patches** da lista do livro para `$LFS/sources` (usar a *wget-list* e o ficheiro *md5sums* do livro 12.4) e **validar MD5**. Repetir downloads falhados via mirrors.
- Cap. 4: criar layout limitado, utilizador `lfs`, `.bash_profile` e `.bashrc` exatamente como no livro.

### F2 — Cross-toolchain (LFS Cap. 5)
Binutils-2.45 P1 → GCC-15.2.0 P1 → Linux-6.16.1 API Headers → Glibc-2.42 → Libstdc++.
- Executar **o sanity check do Glibc** descrito no livro. Se falhar, **não avance**.

### F3 — Ferramentas temporárias (LFS Cap. 6)
M4, Ncurses, Bash, Coreutils, Diffutils, File, Findutils, Gawk, Grep, Gzip, Make, Patch, Sed, Tar, Xz, Binutils P2, GCC P2.

### F4 — Chroot e ferramentas adicionais (LFS Cap. 7)
- Mudar ownership, montar sistemas de ficheiros virtuais, entrar no chroot (via script não interativo: `chroot ... /bin/bash -c "..."` ou script copiado para dentro do `$LFS`).
- Gettext, Bison, Perl, Python, Texinfo, Util-linux; limpeza.
- **Backup obrigatório** do sistema temporário (`tar` em `~/ianinjapelagestao/backup-cap7.tar.xz`) — ponto de restauro.

### F5 — Sistema base (LFS Cap. 8)
Todos os pacotes do Cap. 8 **na ordem do livro** (Man-pages → … → GRUB → … → SysVinit), um log por pacote, linha no `ETAPAS.md` por pacote. Depois: *Stripping* e *Cleaning Up*.

### F6 — Configuração do sistema + identidade (LFS Cap. 9)
- LFS-Bootscripts, udev, rede (`/etc/sysconfig/ifconfig.eth0` com `SERVICE=dhcpcd` após F8), `/etc/hosts`, `/etc/inittab`, relógio, consola (`pt-latin1`), locale, `/etc/inputrc`, `/etc/shells`.
- **Identidade da distro:**
  - `/etc/os-release` → `NAME="ianinjapelagestao"`, `ID=ianinjapelagestao`, `VERSION="12.4"`, `PRETTY_NAME="ianinjapelagestao 12.4 (LFS-based)"`.
  - `/etc/lsb-release`, `/etc/lfs-release` e `/etc/hostname` coerentes.
  - `/etc/issue` com banner ASCII "IANINJA PELAGESTAO" + `\n \l`.
  - `/etc/motd` com mensagem de boas-vindas.

### F7 — Kernel e boot (LFS Cap. 10)
- `/etc/fstab` adaptado a live: **sem entrada para `/`** (raiz é overlay); manter proc, sysfs, devpts, tmpfs. Desativar `checkfs` (remover links `S*checkfs`) e ajustar `mountfs` se necessário — registar em DECISOES.md.
- Compilar **Linux-6.16.1** como no livro, **mais** estas opções **embutidas (=y)**:
  `BLK_DEV_INITRD, DEVTMPFS, DEVTMPFS_MOUNT, TMPFS, SQUASHFS, SQUASHFS_XZ, SQUASHFS_ZSTD, OVERLAY_FS, ISO9660_FS, JOLIET, ZISOFS, BLK_DEV_LOOP, BLK_DEV_SR, SCSI, ATA, SATA_AHCI, ATA_PIIX, USB_XHCI_HCD, USB_EHCI_HCD, USB_STORAGE, VFAT_FS, NLS_CP437, NLS_ISO8859_1, EFI, EFI_STUB, FB_EFI (ou DRM_SIMPLEDRM), SERIAL_8250, SERIAL_8250_CONSOLE, VIRTIO_PCI, VIRTIO_BLK, VIRTIO_NET, E1000, E1000E, R8169`.
- **Não** instalar GRUB num disco (a ISO terá o seu próprio GRUB — ver F10).

### F8 — Pacotes BLFS (sistema usável)
Instalar, seguindo as páginas do BLFS 12.4 (e respetivas dependências obrigatórias):
1. **BLFS Boot Scripts** (Cap. 2) — base para serviços.
2. **make-ca** (+ p11-kit, libtasn1) — certificados.
3. **Linux-PAM** e **Shadow** reconstruído com PAM; **Sudo**.
4. **dhcpcd** (Cap. 14) — rede automática.
5. **Wget** e **cURL**; **OpenSSH**.
6. **Nano** (editor amigável); **cpio** (para initramfs).
7. **dosfstools**, **efivar**, **efibootmgr**; **pciutils**, **usbutils**, **which**, **tree**.
8. Opcional se o tempo permitir: **Git**, **Lynx**, **htop-like (procps já incluído)**.
- Criar utilizadores (Secção 3), `/etc/sudoers.d/ninja`, `/etc/skel` (BLFS "Configuring for Adding Users") e ficheiros bash do BLFS ("The Bash Shell Startup Files") com prompt personalizado `ninja@ianinjapelagestao`.

### F9 — Sistema live (initramfs + SquashFS)
- Basear-se na página **BLFS "About initramfs"** (`mkinitramfs`) e estender o `/init` para boot live:
  ```sh
  # lógica do /init (resumo)
  mount -t proc proc /proc; mount -t sysfs sys /sys; mount -t devtmpfs dev /dev
  # procurar o dispositivo com LABEL=IANINJAPELAGESTAO (repetir até 30 s)
  DEV=$(blkid -L IANINJAPELAGESTAO)
  mount -o ro "$DEV" /run/iso
  mount -t squashfs -o loop,ro /run/iso/live/rootfs.squashfs /run/lower
  mount -t tmpfs tmpfs /run/rw && mkdir -p /run/rw/upper /run/rw/work
  mount -t overlay overlay -o lowerdir=/run/lower,upperdir=/run/rw/upper,workdir=/run/rw/work /newroot
  # mover /run/iso, /run/lower para dentro de /newroot e:
  exec switch_root /newroot /sbin/init
  ```
  Incluir no initramfs: bash, mount, umount, blkid, losetup, switch_root, mkdir, sleep, e as bibliotecas necessárias (`ldd`). Em caso de falha, cair num shell de emergência com mensagem clara.
- Gerar `rootfs.squashfs` a partir de `$LFS` **excluindo** `/sources`, `/tools`, `/proc/*`, `/sys/*`, `/dev/*`, `/run/*`, `/tmp/*`, `/boot/*`:
  `mksquashfs $LFS iso-root/live/rootfs.squashfs -comp xz -wildcards -e ...`

### F10 — Geração da ISO
- `iso-root/boot/vmlinuz` (kernel), `iso-root/boot/initrd.img`, `iso-root/live/rootfs.squashfs`.
- `iso-root/boot/grub/grub.cfg`:
  ```
  set default=0
  set timeout=5
  menuentry "ianinjapelagestao 12.4 (Live)" {
      linux /boot/vmlinuz quiet net.ifnames=0 console=tty0 console=ttyS0,115200
      initrd /boot/initrd.img
  }
  menuentry "ianinjapelagestao 12.4 (Live - modo seguro/verbose)" {
      linux /boot/vmlinuz net.ifnames=0 nomodeset console=tty0 console=ttyS0,115200
      initrd /boot/initrd.img
  }
  ```
- Gerar ISO híbrida (BIOS + UEFI):
  `grub-mkrescue -o output/ianinjapelagestao-12.4-x86_64.iso iso-root -- -volid IANINJAPELAGESTAO`
- Gerar `sha256sum` em `output/ianinjapelagestao-12.4-x86_64.iso.sha256`.

### F11 — Testes automáticos (sem intervenção humana)
Usar `qemu-system-x86_64` em modo **headless** (`-nographic`, consola série) com `expect`/`timeout`:
1. **Boot BIOS:** `-m 2048 -cdrom <iso> -boot d`.
2. **Boot UEFI:** igual + `-bios /usr/share/ovmf/OVMF.fd` (ou caminho OVMF do host).
3. Critérios de aceitação (cada um com evidência em `logs/11-teste-*.log`):
   - [ ] GRUB mostra o menu "ianinjapelagestao".
   - [ ] Kernel arranca e o initramfs monta o SquashFS.
   - [ ] Aparece o banner de `/etc/issue` e o prompt `login:`.
   - [ ] Login como `root` funciona; `cat /etc/os-release` mostra `ianinjapelagestao`.
   - [ ] `ip addr` mostra `eth0` com IP via DHCP (rede user do QEMU) e `wget -q --spider https://www.linuxfromscratch.org` funciona.
   - [ ] `sudo -u ninja sudo -n true` funciona.
   - [ ] `poweroff` encerra limpo.
4. Se algum critério falhar: corrigir (kernel, init, fstab, bootscripts), regenerar ISO e repetir F11 — até passar.

### F12 — Entrega
- `README.md`: o que é, como gravar em USB (Rufus/BalenaEtcher/`dd`), como testar em VirtualBox/QEMU, credenciais, pacotes incluídos.
- `docs/RELATORIO-FINAL.md`: duração total, tempo por etapa, nº de pacotes, tamanho da ISO, resultado dos testes, decisões tomadas, avisos conhecidos.
- `ETAPAS.md` com todas as linhas ✅ e progresso 100 %.
- Desmontar tudo limpo (`umount -R /mnt/lfs`, `losetup -d`).
- Mensagem final ao utilizador: caminho da ISO, SHA-256, resumo dos testes.

---

## 6. BOAS PRÁTICAS OBRIGATÓRIAS

- Um script por etapa em `scripts/` (`set -euo pipefail`, idempotente, com `log()` que escreve em ficheiro e no `ETAPAS.md`). `scripts/run-all.sh` orquestra tudo lendo `progresso.json`.
- Antes de cada pacote: extrair o tarball em `$LFS/sources`, `cd`, executar instruções do livro, voltar e **apagar** o diretório extraído (regra do livro).
- Confirmar no início se há **errata** para o LFS/BLFS 12.4 e aplicá-la.
- Nunca correr como `root` o que o livro manda correr como `lfs` (Cap. 5–6) e vice-versa.
- Se o tempo for crítico, a ferramenta oficial **jhalfs** pode automatizar o LFS — usar apenas como plano B e documentar em DECISOES.md.

---

## 7. DEFINIÇÃO DE PRONTO

O projeto está concluído **apenas** quando existirem:
1. `output/ianinjapelagestao-12.4-x86_64.iso` + `.sha256`;
2. testes F11 aprovados em **BIOS e UEFI**, com logs;
3. `ETAPAS.md` a 100 %, `README.md` e `docs/RELATORIO-FINAL.md` preenchidos.

**Comece agora pela F0. Não pergunte nada. Mantenha o `ETAPAS.md` sempre atualizado.**
