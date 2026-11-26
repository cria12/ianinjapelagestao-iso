# ianinjapelagestao — Decisões tomadas autonomamente

## Host de construção: WSL2 (Ubuntu 24.04) em Windows 11
_2026-11-04 19:26_

O computador do dono do projeto é Windows 11 (12 núcleos, 16 GB RAM). O prompt assume um host Linux, por isso foi instalada a distribuição Ubuntu-24.04 no WSL2 já presente (kernel 6.18 da Microsoft, com suporte a loop, squashfs, overlay e /dev/kvm). O ficheiro %USERPROFILE%\.wslconfig foi criado com memory=12GB, swap=8GB, processors=12 e vmIdleTimeout/instanceIdleTimeout=-1 para que a VM não seja desligada durante a compilação. Em /etc/wsl.conf: systemd=true, utilizador por omissão root e appendWindowsPath=false (o PATH do Windows tem espaços e parêntesis que poluiriam o ambiente). O projeto vive em /root/ianinjapelagestao (ext4 do WSL); a ISO e os documentos finais são copiados para C:\Users\User\Documents\ianinjapelagestao_iso.

## Transcrição dos comandos do livro
_2026-11-04 19:26_

Os comandos de cada pacote são extraídos automaticamente do HTML oficial do LFS/BLFS 12.4 (blocos <pre class="userinput"> e <pre class="root">) por scripts/extract-book.py, em vez de reescritos à mão — garante transcrição literal e sem erros de cópia. Blocos interativos ou só explicativos (passwd, su - lfs, exec bash --login, tzselect, vim -c ':options', exemplos de make -j32, etc.) são listados explicitamente em scripts/book-overrides.txt com o motivo. Blocos de test suite correm com tolerância a falhas (o livro documenta falhas conhecidas) e os resultados ficam nos logs.

## Errata LFS/BLFS 12.4
_2026-11-04 19:26_

Errata consultada em 2026-11-04: a única alteração com impacto é a troca de ftp.gnu.org/gnu por ftpmirror.gnu.org, já refletida na wget-list-sysv publicada (versão de dez/2025). A errata do BLFS não afeta os pacotes escolhidos.

## Rede do WSL em modo mirrored
_2026-11-04 19:26_

Com a rede NAT por omissão do WSL2 as transferências ficavam a ~50 KB/s (no Windows: ~2,5 MB/s). Foi definido networkingMode=mirrored em .wslconfig, o que elevou a velocidade para 1,5–4 MB/s.

## Partição LFS em ficheiro de imagem
_2026-11-04 19:28_

Conforme a Secção 3, o 'disco' LFS é o ficheiro esparso /root/ianinjapelagestao/lfs.img (40 GB, ext4, rótulo LFS) montado via loop em /mnt/lfs. Os blocos do Cap. 2.4–2.7 que referem /dev/<xxx> e swapon não se aplicam. A imagem ocupa apenas o espaço efetivamente usado.

## Backup do Cap. 7 sem /sources
_2026-11-04 20:06_

O backup obrigatório (backup-cap7.tar.xz) segue o Cap. 7.13.2 mas exclui ./sources (≈600 MB de tarballs já validados por MD5 e reprodutíveis), para reduzir tempo e espaço. Para restaurar: montar lfs.img, apagar o conteúdo exceto sources e extrair o tar em /mnt/lfs.

## Stripping (8.85): ignorar erros do strip
_2026-11-05 07:48_

O ciclo final do livro devolve erro em ficheiros que não são ELF (ex.: /usr/lib/libgcc_s.so é um script do linker); o livro diz que esses avisos são ignoráveis, mas com bash -e paravam a build. Adicionado '|| true' só nessa linha. As 3 tentativas anteriores já tinham feito a parte save_usrlib, por isso os .dbg dessas 7 bibliotecas ficaram sem símbolos de depuração (sem impacto na ISO live).

## Nomes de rede e consola série
_2026-11-05 07:49_

Não são geradas regras udev persistentes (Cap. 9.4.1.1): numa ISO live elas ficariam presas ao MAC da máquina de build. Com net.ifnames=0 no GRUB e AlternativeNamesPolicy vazio, a 1.ª placa chama-se sempre eth0. Ao /etc/inittab do livro foi acrescentado um agetty em ttyS0 (115200) para permitir testes headless no QEMU e uso em servidores. Consola: KEYMAP=pt-latin1, FONT=Lat2-Terminus16, UNICODE=1; LANG=pt_PT.UTF-8; fuso Europe/Lisbon (aplicado no Cap. 8 Glibc).

## fstab e bootscripts para sistema live
_2026-11-05 07:49_

O /etc/fstab não tem entrada para / (a raiz é OverlayFS: SquashFS só-leitura + tmpfs, montado pelo initramfs). Foram removidos os links S*checkfs (fsck numa raiz overlay/squashfs não se aplica). O mountfs do LFS faz 'mount -o remount,rw /' — no overlay isso é inofensivo — e 'mount -a -O no_netdev' monta o resto do fstab, por isso não foi alterado.

## Configuração do kernel
_2026-11-05 07:53_
**Atualização (drivers):** o ponto de partida 'make defconfig' foi substituído pela configuração do pacote linux do Arch Linux 6.16.1.arch1-1 (quase todos os drivers em módulos); o resto deste método mantém-se. Ver 'Kernel: configuração base do Arch Linux e drivers em módulos'.

Em vez do menuconfig interativo do Cap. 10.3: make defconfig (x86_64) + as opções dos 3 blocos de configuração do livro (extraídas automaticamente por scripts/kconfig-from-book.py) + as opções da Secção F7 do prompt, todas embutidas (=y), aplicadas com scripts/config e make olddefconfig (duas passagens). Lista completa: logs/10-kernel-opcoes.txt. Opções que o Kconfig não permitiu ativar (dependências/arquitetura): NLS_CP437 FB_EFI. A documentação do kernel (cp -r Documentation) não foi copiada para poupar espaço na ISO. GRUB não é instalado em disco: a ISO usa o GRUB do grub-mkrescue.

## BLFS: compilação como root dentro do chroot
_2026-11-05 07:59_

Os blocos 'userinput' do BLFS (configure/make), que o livro prevê para um utilizador sem privilégios, são executados como root dentro do chroot, tal como no Cap. 8 do LFS — o sistema ainda não tem utilizadores nem arrancou. Cada página é transcrita automaticamente (scripts/gen-scripts.py -> scripts/gen/blfs/) e executada por scripts/run-blfs.sh (extrair, cd, comandos, apagar). URLs e somas MD5 vêm da própria página (scripts/blfs-fetch.py), com a errata ftp.gnu.org/gnu -> ftpmirror.gnu.org aplicada. Test suites que só aparecem no texto (fora de blocos) não são corridas, exceto o 'ninja test' do Linux-PAM (falhas toleradas, ver logs/f8-linux-pam.log).

## BLFS: blfs-bootscripts sem MD5 no livro
_2026-11-05 07:59_

A página 'BLFS Boot Scripts' não indica soma MD5 para blfs-bootscripts-20250225.tar.xz. Foi fixada a soma obtida em 2026-11-04 (ec1bae931da7e994d2fbb752913215a0); um tarball diferente faz a F8 falhar. O diretório extraído é mantido em /sources durante a F8 (recomendação do livro) e apagado no fim. Os blocos 'make install-service-dhcpcd' e 'make install-sshd' foram substituídos por versões que entram nesse diretório (scripts/replace/blfs-basicnet-dhcpcd.5.sh e blfs-postlfs-openssh.8.sh).

## BLFS: certificados (make-ca) e DNS no chroot
_2026-11-05 07:59_

O 'make-ca -g' descarrega o certdata.txt da Mozilla dentro do chroot; como o /etc/resolv.conf do LFS é só um marcador (o dhcpcd gere-o no arranque), o do host é copiado temporariamente para $LFS/etc/resolv.conf e o original é reposto logo a seguir (também em caso de erro). O bloco do cron semanal (/etc/cron.weekly/update-pki.sh) foi omitido: o sistema não tem cron; numa ISO live os certificados ficam com a data de construção e podem ser atualizados à mão com 'make-ca -g'.

## BLFS: dependências recomendadas instaladas
_2026-11-05 07:59_

Além das dependências obrigatórias (p11-kit/libtasn1 para o make-ca, Linux-PAM para o Shadow, libusb para o usbutils, efivar+popt para o efibootmgr), foram instaladas estas recomendadas, por serem necessárias ao funcionamento: libunistring, libidn2 e libpsl (o configure do cURL 8.15 exige libpsl e o livro desaconselha desativá-lo; Wget usa-o também) e hwdata (pci.ids/usb.ids, sem os quais lspci/lsusb só mostram números). Foi também instalada a documentação pré-gerada do Linux-PAM (download adicional com MD5 na página). Dependências opcionais (Doxygen, texlive, asciidoc, GnuTLS, nghttp2, etc.) não foram instaladas e os blocos que delas dependem foram omitidos (ver scripts/book-overrides.txt).

## BLFS: configuração do dhcpcd
_2026-11-05 07:59_

O dhcpcd foi compilado sem privilege separation (--disable-privsep), que é a opção por omissão do livro; os blocos do utilizador dhcpcd e da variante privsep foram omitidos. O /etc/sysconfig/ifconfig.eth0 escrito na F6 foi reescrito segundo o modelo do livro, sem os marcadores <insert ...>: ONBOOT=yes, IFACE=eth0, SERVICE=dhcpcd, DHCP_START="-b -q -h $HOSTNAME", DHCP_STOP="-k" (o -h envia o nome ianinjapelagestao ao servidor DHCP). Os exemplos de IP estático e de resolv.conf.head (OpenDNS) não foram aplicados.

## BLFS: OpenSSH — chaves de host e arranque manual
_2026-11-05 07:59_

O bootscript sshd do BLFS não gera chaves de host, mas o 'make install' do OpenSSH gera-as (ssh-keygen -A) — ficariam iguais em todas as cópias da ISO, permitindo ataques man-in-the-middle entre máquinas que arrancam a mesma imagem. As chaves geradas na construção são apagadas e ao bloco 'start' de /etc/rc.d/init.d/sshd foi acrescentada uma linha '/usr/bin/ssh-keygen -A' (cria só as chaves em falta, logo antes de lançar o daemon). Os links S30sshd dos níveis 2-5 criados por 'make install-sshd' foram removidos (mantêm-se os K30sshd): a ISO é pública e tem contas com senha fixa da construção (ninja com sudo sem senha), por isso o sshd não arranca sozinho — ativa-se com '/etc/rc.d/init.d/sshd start' (isto também evita gerar chaves RSA a cada arranque, lento em QEMU sem KVM). Aplicou-se 'PermitRootLogin no' e 'UsePAM yes' (recomendações do livro); a autenticação por senha mantém-se ativa (o bloco que a desativa foi omitido, pois a ISO não traz chaves autorizadas) — entra-se como ninja e usa-se sudo.

## BLFS: utilizador ninja e sudo sem senha
_2026-11-05 07:59_

O utilizador ninja (senha de scripts/senhas.local, shell /bin/bash) é criado com 'useradd -m' só depois de /etc/skel estar povoado, de forma idempotente. Tem sudo através de /etc/sudoers.d/ninja (modo 0440, validado com visudo -c -f) com a regra 'ninja ALL=(ALL:ALL) NOPASSWD: ALL' em vez de 'ALL' com senha: os testes automáticos (F11) executam 'sudo -u ninja sudo -n true', que exige NOPASSWD. O ficheiro /etc/sudoers.d/00-sudo do livro (secure_path e grupo wheel com senha) também foi criado. A senha do root definida no Cap. 8 mantém-se; o Shadow reinstalado com PAM não altera /etc/shadow.

## BLFS: ficheiros de arranque do Bash, /etc/skel e prompt
_2026-11-05 07:59_

Aplicada a página 'The Bash Shell Startup Files' (substitui o /etc/profile do Cap. 9.7 pelo do BLFS + /etc/profile.d). Desvios: em /etc/profile.d/i18n.sh o marcador <ll>_<CC>.<charmap> passou a pt_PT.UTF-8 (C.UTF-8 na consola linux, como no livro); em /etc/bashrc o prompt passou a '\u@\h [ \w ]' (ex.: ninja@ianinjapelagestao, a vermelho para root e verde para utilizadores). Os ficheiros pessoais (~/.bash_profile, ~/.profile, ~/.bashrc, ~/.bash_logout) foram criados para o root e copiados para /etc/skel (diretório 0755 do root, ficheiros 0600, conforme 'Configuring for Adding Users').

## BLFS: pacotes opcionais Git e Lynx
_2026-11-05 07:59_

Git 2.50.1 e Lynx 2.9.2 foram incluídos porque não trazem dependências novas (Git usa cURL/OpenSSL/Expat/Python já presentes; Lynx usa OpenSSL/ncurses/zlib/bzip2). Do Git omitiu-se a documentação (gerá-la exige asciidoc/xmlto; os tarballs pré-gerados git-manpages/git-htmldocs não têm MD5 no livro e ocupariam espaço na ISO). No Lynx aplicaram-se as três alterações de lynx.cfg do livro (LOCALE_CHARSET, DEFAULT_EDITOR:vi, PERSISTENT_COOKIES).

## initramfs live
_2026-11-05 08:02_

Baseado no /init do BLFS 'About initramfs' (mkinitramfs), mas com lógica própria para live (scripts/live-init.sh): procura o volume com LABEL=IANINJAPELAGESTAO até 30 s (tentando cada dispositivo devolvido pelo blkid, útil em pens USB onde o disco e a partição têm o mesmo rótulo), monta o ISO9660, o live/rootfs.squashfs por loop e um OverlayFS com camada de escrita em tmpfs; move /run, /dev, /proc e /sys para a nova raiz (o mountvirtfs do LFS deteta-os já montados) e faz switch_root para /sbin/init. Em falha abre um bash de emergência com o motivo. Contém bash, mount, umount, blkid, losetup, switch_root, mkdir, sleep e utilitários mínimos, com as bibliotecas obtidas por ldd dentro do chroot. Todos os drivers necessários estão embutidos no kernel, por isso não leva módulos.

## GRUB também na consola série
_2026-11-05 08:03_

Ao grub.cfg da Secção F10 foram acrescentadas 3 linhas (serial --unit=0 --speed=115200; terminal_input/terminal_output console serial) para o menu aparecer tanto no ecrã como em ttyS0 — necessário para os testes automáticos headless (F11) verificarem o menu. As entradas de menu são exatamente as do prompt.

## IA: llama.cpp b12121 (só CPU)
_2026-11-05 08:29_

O motor de inferência é o llama.cpp, release b12121 (tarball do GitHub https://github.com/ggml-org/llama.cpp/archive/refs/tags/b12121.tar.gz, SHA-256 0b6fbcaa41a51782ccb3454ae6a1cf6b2f7d0530e8dfe6d2f9de2df8c916a33a fixado em scripts/f08b-ia.sh). Compilado no chroot com CMake 4.1.0 (página do BLFS) e Ninja, em Release, bibliotecas partilhadas em /usr/lib, programas em /usr/bin (llama-cli, llama-completion, llama-server, llama-bench e restantes ferramentas). OpenMP ativo (libgomp do GCC 15.2.0). Testes e exemplos do llama.cpp não são compilados. O diretório de fontes é apagado no fim. Pequena alteração às fontes: no chat do llama-cli, '/sair' é aceite como sinónimo de '/exit' (sed em tools/cli/cli-context.cpp).

## IA: variantes do backend CPU (GGML_BACKEND_DL + GGML_CPU_ALL_VARIANTS)
_2026-11-05 08:29_

A ISO tem de correr em qualquer PC x86_64, mas compilar com -march=native (GGML_NATIVE, por omissão) prenderia o binário ao CPU do host de construção (AVX-512 noutros CPUs dá 'Illegal instruction'), e compilar só para a linha de base x86-64 (SSE2) tornaria a inferência várias vezes mais lenta. Por isso usou-se GGML_NATIVE=OFF, GGML_BACKEND_DL=ON e GGML_CPU_ALL_VARIANTS=ON: são geradas bibliotecas libggml-cpu-<variante>.so (x64, sse42, sandybridge, haswell/AVX2, skylakex/AVX-512, icelake, alderlake/AVX-VNNI, sapphirerapids/AMX, zen4, ...) em /usr/lib/ggml (GGML_BACKEND_DIR), e o ggml escolhe no arranque a melhor que o CPU suporta. Variante efetivamente compilada: todas (se a combinação falhasse, o script recorre à versão portátil x86-64 e regista-o em /usr/share/ia/compilacao.txt).

## IA: cURL/HTTPS e interface web do llama.cpp
_2026-11-05 08:29_

Pedia-se LLAMA_CURL=ON, mas no llama.cpp b12121 essa opção está obsoleta (o CMake só emite um aviso e ignora-a): os downloads de modelos (-hf/-mu) usam o cliente HTTP interno (cpp-httplib) com OpenSSL, ativado com LLAMA_OPENSSL=ON — o OpenSSL do LFS é usado. O ia-baixar usa o cURL do sistema (F8). A interface web do llama-server não é incluída: obtê-la exigiria npm (LLAMA_BUILD_UI) ou descarregar durante a compilação um pacote pré-gerado do Hugging Face sem soma fixada (LLAMA_USE_PREBUILT_UI), e o chroot não tem rede; a API compatível com a OpenAI (/v1/chat/completions, /v1/completions, /v1/models, /health) funciona normalmente.

## IA: CMake do BLFS com bibliotecas internas
_2026-11-05 08:29_

O CMake 4.1.0 segue a página do BLFS (URL e MD5 do livro). As dependências recomendadas libarchive, libuv e nghttp2 não estão instaladas, por isso o bootstrap usa as cópias incluídas no CMake (--no-system-libarchive/--no-system-libuv/--no-system-nghttp2, além das jsoncpp/cppdap/librhash que o livro já indica); cURL, zlib, bzip2, xz, zstd e expat são as do sistema. Acrescentou-se --parallel=$(nproc) ao bootstrap. Opcionais (Qt, sphinx, gfortran...) não instalados; a test suite (bin/ctest, só no texto da página) não foi corrida.

## IA: modelo predefinido Qwen2.5-1.5B-Instruct Q4_K_M (Apache 2.0)
_2026-11-05 08:29_

Modelo incluído na ISO: qwen2.5-1.5b-instruct-q4_k_m.gguf do repositório oficial Qwen/Qwen2.5-1.5B-Instruct-GGUF no Hugging Face (revisão 91cad51170dc346986eccefdc2dd33a9da36ead9), 1117320736 bytes, SHA-256 6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e (oid do ponteiro Git LFS publicado pelo Hugging Face, confirmado com sha256sum após o download). Licença Apache 2.0 (permite redistribuição; texto em /usr/share/doc/qwen2.5-1.5b-instruct/LICENSE). Escolha: 1,5 mil milhões de parâmetros em Q4_K_M (~1,1 GB) é o melhor compromisso para uma ISO live que corre só no CPU — responde em português com qualidade razoável, gera várias dezenas de tokens por segundo num CPU moderno com AVX2 e cabe em máquinas com 4 GB de RAM; modelos maiores (3B/7B) duplicariam ou quadruplicariam a ISO e a RAM necessária. Instalado em /usr/share/ia/modelos/ com o link predefinido.gguf. O download é feito no host para $LFS/sources (excluído do SquashFS) e reutilizado se já existir com a soma certa.

## IA: comandos ia-* e servidor
_2026-11-05 08:29_

Comandos em /usr/bin (bash, mensagens em pt-PT; funções comuns em /usr/share/ia/ia-comum.sh): ia-chat (chat interativo com llama-cli; threads = núcleos físicos via lscpu, contexto 2048-16384 tokens consoante a RAM livre após carregar o modelo; prompt de sistema em pt-PT a identificar-se como assistente do ianinjapelagestao; -m modelo, -l lista), ia-perguntar (pergunta única via llama-completion -cnv -st, sem TTY, imprime só a resposta; semente 42, temperatura 0,1, máx. 64 tokens), ia-servidor {start|stop|restart|status} (chama /etc/rc.d/init.d/ia-servidor, bootscript ao estilo do BLFS que lança o llama-server como 'nobody' em 127.0.0.1:8080, configurável em /etc/sysconfig/ia-servidor; NÃO ativado no arranque — só escuta localmente, mas consome RAM/CPU), ia-baixar (descarrega outro GGUF por URL ou dono/repo/ficheiro.gguf do Hugging Face para /var/lib/ia/modelos — grupo ninja, 2775 —, com barra de progresso, verificação de espaço livre e do cabeçalho GGUF) e ia-info (CPU e extensões AVX2/AVX-512/AMX, variantes ggml, RAM, swap/zram, modelos, versão; -b corre llama-bench).

## IA: chat automático no login do ninja
_2026-11-05 08:29_

No fim de /home/ninja/.bash_profile e /etc/skel/.bash_profile foi acrescentada (uma só vez, com marcador) a linha que carrega /usr/share/ia/autoarranque.sh. Este lança o ia-chat, após a mensagem 'A iniciar o chat de IA… (Ctrl+C ou /sair para voltar à shell)', apenas se: o utilizador não for root, o stdin for um terminal, a consola for /dev/tty1-tty6, não for uma sessão ssh (SSH_CONNECTION/SSH_TTY), a variável IA_SEM_CHAT não estiver definida e existir modelo predefinido. Ao sair do chat fica a shell normal. Na consola série ttyS0 (usada pelos testes automáticos), por ssh e para o root nunca arranca.

## Kernel afinado para IA no CPU (llama.cpp) e persistência
_2026-11-05 08:34_

Às opções da live juntam-se as de scripts/sistema/kernel-opcoes-ia.txt, todas embutidas (=y):
- ZRAM + ZSMALLOC com backends LZ4 e ZSTD e compressor por omissão zstd (ZRAM_DEF_COMP_ZSTD), mais CRYPTO_LZ4/CRYPTO_ZSTD: swap comprimida em RAM. Um modelo de 1,5-8 B em Q4 ocupa 1-5 GiB; com zram o resto do sistema (e o KV cache em picos) pode ir para swap comprimida (~3:1 com zstd) em vez de o processo ser morto pelo OOM. zstd comprime melhor que lzo-rle/lz4 com custo de CPU aceitável para swap.
- TRANSPARENT_HUGEPAGE com omissão 'madvise' (não 'always'): só quem pede MADV_HUGEPAGE recebe páginas de 2 MiB, evitando o aumento de memória e as pausas de compactação do khugepaged em todo o sistema, que é o que mais pesa numa máquina com pouca RAM a correr um LLM. O llama.cpp/ggml beneficia quando pede huge pages para os buffers grandes; o modo pode ser mudado em /sys/kernel/mm/transparent_hugepage/enabled sem recompilar.
- NUMA=y (já vinha do defconfig) e NUMA_BALANCING=n: o balanceamento automático migra páginas entre nós e o próprio llama.cpp avisa para o desligar quando se usa --numa; em máquinas de 1 nó não faz nada.
- CPU_FREQ com governador por omissão 'performance' (o defconfig escolhia 'userspace'); schedutil, powersave e ondemand ficam disponíveis; drivers X86_INTEL_PSTATE, X86_AMD_PSTATE e X86_ACPI_CPUFREQ. A inferência é limitada pela largura de banda de memória e pela frequência sustentada: 'performance' evita a latência de subida de frequência entre tokens.
- Preempção: mantém-se PREEMPT_VOLUNTARY do defconfig (com PREEMPT_DYNAMIC pode mudar-se no arranque com preempt=full/none). É o compromisso de débito/latência usado pelas distribuições genéricas; o trabalho de um LLM é cálculo contínuo em vários threads e não ganha com preempção total.
- HZ=1000 (o do defconfig): o custo do tick em núcleos ocupados é desprezável (<0,1 %) e dá melhor granularidade ao escalonador numa máquina interativa (chat), como faz o Ubuntu desde 24.04.
- Persistência: EXT4_FS (já estava), USB_STORAGE + USB_UAS, MMC/SDHCI (PCI, ACPI) e leitores Realtek PCI (MISC_RTSX_PCI/MMC_REALTEK_PCI), NVMe (+ VMD da Intel, usado por portáteis recentes), VFAT com NLS_CODEPAGE_437/ISO8859_1/UTF8 — tudo embutido para o initramfs (sem módulos) encontrar a partição IANINJA-DADOS em pens USB, cartões SD ou discos NVMe.
- Correções: a opção pedida como NLS_CP437 chama-se NLS_CODEPAGE_437 no Kconfig; FB_EFI depende de FB=y, que o defconfig não ativa, por isso FB=y passou a constar da lista.
O id do passo F7 inclui o md5 da lista de opções, para o kernel ser recompilado sempre que a lista mudar.
Opções que o Kconfig recusou nesta compilação: nenhuma.

## Afinação de memória e CPU em tempo de execução (IA)
_2026-11-05 08:34_

Instalado por F9 a partir de scripts/sistema/ (antes do SquashFS, idempotente):
- /etc/rc.d/init.d/zram, ligado como rcS.d/S21zram (depois de mountvirtfs, modules, udev e swap; antes do mountfs) e rc0.d/rc6.d/K93zram (após o sendsignals, antes do swapoff geral): /dev/zram0 com 50 % da RAM até 16 GiB, compressor zstd, swap com prioridade 100. Configurável em /etc/sysconfig/zram. Numa live sem disco é a única swap; mesmo com disco é preferida pela prioridade.
- /etc/sysctl.conf (bloco marcado, aplicado pelo S90sysctl do LFS): vm.swappiness=100 (com zram trocar páginas anónimas frias custa pouco e preserva a page cache onde vive o modelo GGUF lido por mmap); vm.page-cluster=0 (zram não tem custo de procura, read-ahead de swap só gasta CPU); vm.overcommit_memory=1 (o ggml reserva buffers grandes que só usa em parte; com a heurística por omissão podiam falhar com ENOMEM numa máquina com pouca RAM, e o OOM killer continua a proteger o sistema); vm.max_map_count=1048576 (como as distribuições recentes); vm.min_free_kbytes=65536 (reserva para a zram comprimir em picos). kernel.numa_balancing não é definido porque o kernel é compilado sem NUMA_BALANCING (o llama.cpp recomenda-o desligado) e uma chave inexistente faria o sysctl falhar.
- /etc/rc.d/init.d/desempenho (rcS.d/S91, depois do sysctl): governador cpufreq 'performance' em todos os CPUs e EPP 'performance' se o driver for intel_pstate/amd-pstate; THP 'enabled=madvise'. Sem cpufreq (QEMU) não faz nada e não falha.
- /etc/security/limits.d/90-ianinja-ia.conf: memlock ilimitado (llama.cpp --mlock), nofile 65536 e nproc 65536 para o ninja (compilações paralelas); linhas próprias para root porque '*' não se aplica ao root. O pam_limits já estava em /etc/pam.d/login e sshd; foi acrescentado a su e sudo (antes do 'session include system-session').
- /var/lib/ia/modelos existe na imagem; com persistência ligada vive na camada de escrita do disco IANINJA-DADOS e por isso persiste sem mais nada.

## Persistência em pen USB (IANINJA-DADOS)
_2026-11-05 08:34_

O /init (scripts/live-init.sh), depois de encontrar a ISO, procura durante até mais 5 s (blkid -t LABEL=IANINJA-DADOS, sem cache) um sistema ext4 com o rótulo IANINJA-DADOS — pode estar noutra pen USB, num cartão SD, num NVMe ou numa partição criada depois do fim da ISO na mesma pen. Se existir, monta-o rw (noatime) e usa <disco>/overlay/upper e <disco>/overlay/work (criados se faltarem) como camada de escrita do OverlayFS em vez do tmpfs; o disco é depois movido para /mnt/dados dentro do sistema. Se não montar (ou o OverlayFS falhar) volta ao tmpfs com um AVISO no ecrã. Escreve sempre 'persistência: IANINJA-DADOS (/dev/xxx)' ou 'persistência: desligada (tmpfs)', antes da mensagem 'raiz overlay pronta'. Desliga-se com persistencia=nao ou semdados na linha do kernel (entrada própria do GRUB). Escolhas: um sistema de ficheiros inteiro com rótulo (e não um ficheiro-imagem dentro da partição FAT/ISO) porque é o mais simples de criar, de reparar (e2fsck) e de montar sem módulos; ext4 porque tem journal (um corte de energia não corrompe a camada de escrita) e suporta tudo o que o OverlayFS exige como upper (xattrs trusted.*, whiteouts). Limitação: a camada de escrita está ligada à versão da ISO; ao trocar de ISO, ficheiros alterados em / continuam a sobrepor-se aos novos. O comando /usr/sbin/ia-criar-persistencia <partição> (só no sistema live, como root) recusa a partição da ISO em execução, o disco inteiro, partições sobrepostas à imagem ISO na mesma pen, partições montadas ou em swap; mostra o lsblk e só formata depois de se escrever SIM.

## GRUB: entrada sem persistência
_2026-11-05 08:35_

Acrescentada uma 3.ª entrada 'ianinjapelagestao (sem persistência)' (igual à 1.ª mais persistencia=nao): arranca com camada de escrita em tmpfs mesmo que exista um disco IANINJA-DADOS — útil para testar sem tocar nos dados ou para recuperar de uma camada de escrita estragada. As duas entradas originais e as linhas da consola série ficam iguais; a entrada por omissão continua a ser a 0 ('ianinjapelagestao 12.4 (Live)'), que é a que os testes F11 esperam ver e arrancam por timeout (com persistência automática se houver disco de dados).

## Testes F11: zram, IA e persistência
_2026-11-05 08:35_

Aos 7 critérios originais (iguais) juntam-se: 8 'zram ativo' (/dev/zram* em /proc/swaps) e 9 'IA responde' (ia-perguntar "Responde apenas com a palavra OK." como root na consola série; passa se imprimir uma linha não vazia antes de o prompt voltar; timeout 180 s com KVM e 900 s sem KVM, onde conta como LENTO). Os modos BIOS e UEFI passam a ter 9 critérios. A VM passa de -m 2048 -smp 2 para -m 4096 -smp 4 (um modelo de 1,5 B em Q4 ocupa ~1-1,5 GiB mais o KV cache, e o llama.cpp usa vários threads); com KVM usa -cpu host (o llama.cpp vê AVX2/AVX-512 do host), sem KVM -cpu max,la57=off (TCG emula AVX2; la57 desligado por compatibilidade com o OVMF). O critério 10 'persistência' corre à parte, só em BIOS: um ficheiro-imagem de 1 GiB formatado diretamente com mkfs.ext4 -L IANINJA-DADOS (sem tabela de partições nem loop — o blkid encontra o rótulo no disco inteiro /dev/vda) é ligado como disco virtio; no 1.º arranque confirma-se a mensagem 'persistência: IANINJA-DADOS (/dev/vda)', escreve-se /root/marcador-persistencia e desliga-se; no 2.º arranque confirma-se que o marcador existe. A imagem é apagada no fim (e também se o script sair a meio).

## Kernel: configuração base do Arch Linux e drivers em módulos
_2026-11-05 14:46_

Para a ISO arrancar e funcionar no máximo de hardware real (como a ISO live de uma distribuição generalista), a configuração deixou de partir do 'make defconfig' (que só traz meia dúzia de drivers e nenhum módulo útil) e passou a partir da configuração do pacote 'linux' do Arch Linux para a mesma versão: tag 6.16.1.arch1-1 do repositório gitlab.archlinux.org/archlinux/packaging/packages/linux, commit 30d51b4fa29e1a76b33d0f563271c016a6c296ae, ficheiro 'config' com SHA-256 ae8836206f1518de5c9204d58d74565be8978bb2eda93731373a839e77555433 (verificado por scripts/f07-kernel.sh; cópia em $LFS/sources/config-arch-6.16.1). Escolhido em vez de allmodconfig porque é uma configuração mantida e testada em milhões de máquinas x86_64, já sem as opções de teste/depuração que o allmodconfig ativa (KASAN, UBSAN, selftests, drivers de teste), o que daria um kernel mais lento, maior e mais demorado a compilar; e o Arch usa o kernel quase sem patches, pelo que a configuração serve tal e qual ao kernel vanilla 6.16.1 do LFS (as opções que dependem de ferramentas ausentes — Rust, pahole/BTF — são desligadas pelo próprio 'make olddefconfig'). Por cima aplicam-se, por esta ordem e com scripts/config + olddefconfig em duas passagens: as opções do livro (Cap. 10.3), a lista da live, scripts/sistema/kernel-opcoes-drivers.txt e scripts/sistema/kernel-opcoes-ia.txt. kernel-opcoes-drivers.txt: (1) embute (=y) tudo o que o arranque precisa, porque o initramfs não leva módulos — ISO9660/Joliet/zisofs, SquashFS (xz/zstd), OverlayFS, loop, ext4, vfat/msdos + NLS, devtmpfs, AHCI/SATA, PIIX/IDE genérico, disco e CD SCSI, NVMe, virtio (pci/blk/scsi/net/consola), Hyper-V (VMBus, disco storvsc, teclado), VMware PVSCSI, USB xHCI/EHCI/OHCI/UHCI incluindo a parte PCI (só USB_XHCI_HCD=y sem USB_XHCI_PCI=y não vê as portas), usb-storage + UAS, SD/MMC, HID/USB e PS/2, consola série 8250, efifb/simpledrm; (2) desliga a depuração pesada (DEBUG_INFO_NONE, sem DWARF5/BTF, sem IKHEADERS) — compilação muito mais rápida e /lib/modules dezenas de vezes menor; (3) MODULE_SIG=n: sem assinatura de módulos nem chave de assinatura (não há Secure Boot com chaves próprias nesta ISO; o lockdown do Arch continua inativo por omissão); (4) módulos comprimidos com zstd (MODULE_COMPRESS_ZSTD + MODULE_DECOMPRESS): o kmod 34.2 do LFS foi compilado com +ZSTD +XZ (kmod --version) e o zstd descomprime várias vezes mais depressa do que o xz, o que conta no arranque, quando o udev carrega dezenas de módulos; (5) LOCALVERSION_AUTO=n para a versão ser exatamente 6.16.1; (6) PREEMPT/PREEMPT_NONE/PREEMPT_LAZY=n, porque o Arch escolhe PREEMPT (total) e a escolha do projeto é PREEMPT_VOLUNTARY (ver 'Kernel afinado para IA'). Mantêm-se como módulos os drivers convidados de VirtualBox (VBOXGUEST, VBOXSF_FS, DRM_VBOXVIDEO), VMware (DRM_VMWGFX, VMXNET3), virtio-gpu, bochs e Hyper-V (rede/DRM). Os drivers de rede E1000/E1000E/R8169/VIRTIO_NET continuam embutidos (lista da live). Instalação: 'make INSTALL_MOD_STRIP=1 modules_install' no chroot (módulos sem símbolos de depuração) e 'depmod -a 6.16.1'; o link /lib/modules/6.16.1/build é removido (as fontes são apagadas a seguir). Resultado: 6256 módulos, 137M em /lib/modules/6.16.1. Lista completa de opções forçadas: logs/10-kernel-opcoes.txt; .config final em /boot/config-6.16.1 (fora do SquashFS) e em /proc/config.gz (IKCONFIG). Opções que o Kconfig recusou: nenhuma.

## Drivers: nova etapa F8c (firmware e espaço de utilizador)
_2026-11-05 18:02_

O firmware e os programas que tornam os drivers utilizáveis ficaram numa etapa própria, F8c 'Drivers e firmware' (scripts/f08c-drivers.sh, a seguir à F8b e antes da F9), em vez de irem para a F7: assim mudar o firmware ou os pacotes não obriga a recompilar o kernel (cerca de uma hora) e vice-versa. Os módulos do kernel continuam a ser compilados e instalados na F7. A etapa foi acrescentada a ETAPA_IDS em scripts/lib.sh com o mesmo mecanismo da F8b (script_etapa: F8c -> f08c-*.sh). Como nas outras etapas, os passos são idempotentes (progresso.json); os ids dos passos de firmware e microcódigo incluem a versão, para serem refeitos quando a versão fixada mudar.

## Firmware: linux-firmware 20261019 em .xz, deduplicado
_2026-11-05 18:02_

Instalado o linux-firmware 20261019 completo (tarball oficial https://cdn.kernel.org/pub/linux/kernel/firmware/linux-firmware-20261019.tar.xz, SHA-256 a10d1ab5baf2c74ba92e8c7cf313e691696c26bddfa6df00db795e48d70cd4ca tirado do sha256sums.asc assinado do kernel.org e verificado pelo script) em /usr/lib/firmware, com o próprio Makefile do pacote: 'make install-xz' (copy-firmware.sh segundo o WHENCE, cada ficheiro comprimido com xz --check=crc32, links do WHENCE criados) seguido de 'make dedup' (ficheiros iguais substituídos por links simbólicos). A instalação corre no host com DESTDIR=$LFS e FIRMWAREDIR=/usr/lib/firmware porque o dedup exige o rdfind, que não existe no LFS nem no BLFS (instalado no host Ubuntu por apt, com o GNU parallel para comprimir em paralelo); o resultado são só ficheiros de dados, sem binários do host. Compressão: o kernel tem FW_LOADER_COMPRESS_XZ e _ZSTD; escolheu-se xz porque o firmware é lido raramente (uma vez por dispositivo) e o xz dá ficheiros mais pequenos do que o zstd, o que reduz a ISO; o SquashFS (também xz) quase não volta a comprimir ficheiros já comprimidos. Instala-se tudo, como as distribuições generalistas, porque não se sabe em que hardware a ISO vai arrancar (Wi-Fi Intel/Realtek/MediaTek/Atheros/Broadcom, GPUs AMD/Intel/NVIDIA, Bluetooth, áudio SOF, etc.). Resultado: 3937 ficheiros, 790M. WHENCE e licenças em /usr/share/doc/linux-firmware-20261019. A página 'About Firmware' do BLFS sugere instalar só os ficheiros necessários a uma máquina concreta — desvio justificado por ser uma ISO para qualquer máquina.

## Firmware: wireless-regdb 2026.09.03
_2026-11-05 18:02_

Os drivers Wi-Fi (cfg80211) leem a base de dados regulamentar (canais e potências permitidos por país) de /usr/lib/firmware/regulatory.db; sem ela o kernel fica no domínio 'world' (00), mais restritivo, e regista erros. O BLFS 12.4 não tem página para o wireless-regdb, por isso usou-se o tarball oficial https://cdn.kernel.org/pub/software/network/wireless-regdb/wireless-regdb-2026.09.03.tar.xz (SHA-256 b22e0901227b820cd1c280abe681a15b773a5103a5e10dc442e94ebb34cbf58d, do sha256sums.asc do kernel.org) e instalaram-se só regulatory.db e regulatory.db.p7s (a assinatura que o kernel valida com a chave embutida, CFG80211_REQUIRE_SIGNED_REGDB + CFG80211_USE_KERNEL_REGDB_KEYS da configuração do Arch). O país define-se em tempo de execução com 'iw reg set PT'.

## Firmware: microcódigo Intel e AMD (carregamento precoce)
_2026-11-05 18:02_

Incluído microcódigo de CPU para carregamento precoce, como descrito no BLFS ('About Firmware' > Microcode updates): GenuineIntel.bin = concatenação de intel-ucode/* do microcode-20260925 da Intel (https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/archive/refs/tags/microcode-20260925.tar.gz, SHA-256 0ec19023dad1e6dd0c5909174b8dff2555b91cf01671e36271a1ef36655c0cfc calculado no download, o GitHub não publica somas) e AuthenticAMD.bin = concatenação de amd-ucode/microcode_amd*.bin do linux-firmware 20261019, num cpio não comprimido (kernel/x86/microcode/) em /boot/microcode.img (18M). A F9 põe esse cpio à frente do initramfs (o kernel lê-o antes de descomprimir o resto), por isso o grub.cfg não muda. O carregamento tardio (depois do arranque) está desativado no kernel 6.16 por omissão e não é usado. Em máquinas virtuais o kernel ignora o microcódigo. Os ficheiros intel-ucode/ não são copiados para /usr/lib/firmware (só serviriam ao carregamento tardio).

## Drivers: carregamento automático de módulos pelo udev
_2026-11-05 18:02_

Confirmado que não é preciso nada de novo para os módulos serem carregados: o bootscript udev do LFS (rcS.d/S10udev) arranca o udevd e faz 'udevadm trigger --action=add' (subsistemas e dispositivos) + 'udevadm settle'; as regras 80-drivers.rules do udev do LFS correm 'kmod load' com o MODALIAS de cada dispositivo, e o modules.alias é gerado pelo depmod na F7. O S50udev_retry repete os eventos que falharam antes de o / estar montado. O bootscript network (rc3.d) só corre depois disto, por isso placas de rede cujo driver é módulo já existem quando o ifup corre (de qualquer modo, E1000/E1000E/R8169/VIRTIO_NET estão embutidos). O /etc/sysconfig/modules (S05modules) fica vazio: não há módulos a forçar. O firmware é pedido pelos drivers através do carregador do kernel diretamente de /usr/lib/firmware (não é preciso udev para isso).

## Wi-Fi: libnl, wpa_supplicant, iw e ligar-wifi
_2026-11-05 18:02_

Do BLFS 12.4: libnl-3.11.0 (dependência obrigatória do iw e recomendada do wpa_supplicant, para o driver nl80211), wpa_supplicant-2.11 e iw-6.9 (URLs e MD5 do livro). O wpa_supplicant usa o .config do livro (nl80211 + wext, WPA/WPA2/WPA3-pessoal, EAP, WPS, readline) sem a interface D-Bus (bloco 2 e ficheiros D-Bus omitidos: não há D-Bus nem NetworkManager). A documentação da libnl (download adicional) foi omitida. O serviço 'wpa' do blfs-bootscripts (make install-service-wpa) foi instalado e criado /etc/sysconfig/ifconfig.wlan0 segundo o modelo do livro (SERVICE="wpa", WPA_SERVICE="dhcpcd", DHCP_START="-b -q -h $HOSTNAME", DHCP_STOP="-k"), mas com ONBOOT="no": a ISO não conhece nenhuma rede e um ifup falhado no arranque só atrasaria e mostraria FAIL. Novo comando /usr/bin/ligar-wifi <SSID> [interface] (pt-PT, passa a root com sudo): pede a senha sem eco (Enter vazio = rede aberta), escreve com wpa_passphrase o ficheiro que o serviço 'wpa' do BLFS lê — /etc/sysconfig/wpa_supplicant-wlan0.conf (modo 600, sem a senha em claro) — e faz ifdown/ifup wlan0 (wpa_supplicant + dhcpcd), esperando até 30 s pelo IP; 'ligar-wifi -l' procura redes (iw scan) e 'ligar-wifi -d' desliga. Nota: pedia-se /etc/wpa_supplicant-wlan0.conf, mas o serviço do BLFS procura /etc/sysconfig/wpa_supplicant-<ifconfig>.conf; usou-se esse caminho para 'ifup wlan0' (e ONBOOT=yes) funcionarem sem alterar o serviço. Antes de ligar faz 'rfkill unblock wifi' (rfkill do util-linux). Com persistência (IANINJA-DADOS) a configuração fica guardada; pondo ONBOOT="yes" em ifconfig.wlan0 liga-se sozinho no arranque.

## Som: alsa-lib e alsa-utils
_2026-11-05 18:02_

Do BLFS 12.4: alsa-lib-1.2.14 (com o alsa-ucm-conf-1.2.14, download adicional da página sem MD5 no livro — SHA-256 32e9809f592d92b978aa1032e35293c33b8d0f1ec475f937022c3ee9a3069c21 fixado no script —, necessário às placas modernas, p. ex. SOF em portáteis Intel) e alsa-utils-1.2.14 (aplay, arecord, amixer, alsamixer, alsactl, speaker-test). Dependências opcionais não instaladas (Doxygen: blocos de documentação omitidos; libsamplerate, fftw, xmlto). 'alsactl init/store' do livro não podem correr no chroot (não há placa de som). Instalado o bootscript alsa do blfs-bootscripts (rcS.d/S60alsa; K35alsa em 0/1/6) com uma alteração: como numa live o 1.º arranque nunca tem /var/lib/alsa/asound.state, sem estado gravado faz 'alsactl init' (volumes por omissão) em vez de 'restore' (que falharia e mostraria FAIL), e ao desligar só grava o estado se houver placa de som. Os drivers de som são módulos (snd_hda_intel, snd_sof_*, snd_usb_audio, ...) carregados pelo udev.

## Bluetooth: só drivers do kernel
_2026-11-05 18:02_

Os drivers de Bluetooth (BT, btusb, btintel, btrtl, ...) existem como módulos e o firmware respetivo está no linux-firmware, mas o espaço de utilizador (BlueZ) não foi instalado: o BlueZ exige D-Bus, GLib e, na prática, um ambiente com serviço de sessão, nada disso existe nesta ISO de consola, e não era um requisito. Os adaptadores são reconhecidos (aparecem em dmesg/lsusb e em /sys/class/bluetooth), mas não há bluetoothctl.

## Interface gráfica: Xorg + Xfce 4.20 com aspeto ao estilo do macOS
_2026-11-05 19:59_

Pedido: uma interface gráfica moderna, ao estilo do macOS. Escolheu-se o Xfce 4.20 do BLFS sobre o Xorg (com Mesa e LightDM) em vez do GNOME ou do KDE: é o ambiente completo mais leve do livro (cabe numa ISO live e corre em VMs sem aceleração 3D, com o llvmpipe do Mesa), mantém tudo dentro do BLFS 12.4 System V, e o seu painel e gestor de janelas permitem reproduzir o aspeto do macOS (barra superior, dock, botões de janela à esquerda, compositor com sombras) com temas livres. Wayland não é usado: nenhum compositor Wayland adequado está no BLFS e o Xfce 4.20 é uma sessão X11. A lista de páginas foi resolvida automaticamente das dependências Required + Recommended das páginas-alvo (scripts/blfs-deps.py, scripts/gui/resolver.sh); foram cortadas recomendações sem utilidade num ambiente de trabalho e muito pesadas (TeX Live, GTK4, GStreamer, PulseAudio, GEGL/Graphviz, Vala, XScreenSaver, Vulkan, DocBook) — lista em scripts/gui/resolver.sh. Ciclos de dependências resolvidos à mão como o livro indica (FreeType recompilado depois do HarfBuzz; driver xf86-input-libinput depois do Xorg-Server; gdk-pixbuf antes do librsvg; GTK3 antes do adwaita-icon-theme) — ver scripts/gui/ordem.txt.

## F8d — Base gráfica: páginas, ordem e passos acrescentados
_2026-11-05 19:59_

O bloco 1 segue scripts/gui/ordem.txt (x/xorg7 a x/xinit), com seis passos a mais: o libepoxy (x/libepoxy, listado no bloco 2) passa para antes do xorg-server, porque o glamor — e com ele o driver modesetting, que substitui os antigos drivers DDX — precisa dele (o livro recomenda-o "needed for glamor"); o passo do bloco 2 com o mesmo id é saltado por já estar feito. Entre o LLVM e o Mesa entram SPIRV-Headers, SPIRV-Tools, SPIRV-LLVM-Translator e libclc (páginas do BLFS 12.4, sem desvios), exigidos pelo driver iris (ver Mesa). Passos próprios (scripts/gui/funcoes-01.sh): dbus-bootscript (make install-dbus do blfs-bootscripts), mesa-vgem e xorg-teclado. Os blocos que acrescentam linhas a ficheiros do sistema ou criam utilizadores foram tornados repetíveis (corre_passo tenta cada passo até 3 vezes).

## F8d — Listas do Xorg (bibliotecas, aplicações, tipos de letra)
_2026-11-05 19:59_

As páginas x7lib, x7app e x7font não têm tarball principal: o livro escreve a lista com as somas MD5, descarrega-a com wget -i- e verifica com md5sum -c; correm em /sources com DNS no chroot (pagina_rede), pelo que os tarballs ficam verificados pelas somas do livro. Mantêm-se as listas completas do livro. Omitem-se os blocos que só fazem sentido numa sessão interativa: a redefinição de as_root com sudo/su (compila-se como root; as_root vem de blfs-env.sh), o "bash -e" e o "exit" do subshell (o script gerado já corre com bash -e, pelo que um erro em qualquer pacote do ciclo para o passo) e o grep dos logs do make check (os testes estão comentados no próprio ciclo). O mkdir lib/app/font passa a mkdir -p e, no ciclo das bibliotecas, apaga-se o diretório de cada pacote antes de o extrair (o do libpciaccess, com build/, não era apagado pelo livro e impedia repetir o passo). Os symlinks /usr/lib/X11 e /usr/include/X11 são omitidos: só se aplicam com XORG_PREFIX diferente de /usr. Remove-se o xkeystone como o livro indica (o Nickle não está instalado).

## F8d — GLib com GObject Introspection
_2026-11-05 19:59_

A GLib 2.84.4 é instalada pela ordem do livro: primeiro sem introspection, depois o gobject-introspection-1.84.0 (download adicional, MD5 do livro) compilado em gi-build contra a GLib acabada de instalar, depois a reconfiguração com -D introspection=enabled e o ninja install final. As páginas de manual são geradas (-D man-pages=enabled, rst2man do docutils, instalado antes). Omitidos: o patch opcional glib-skip_warnings (GLIB_LOG_LEVEL) e a documentação da API (gi-docgen não instalado). O bloco que move /usr/include/glib-2.0 para .old corre como no livro (inofensivo ao repetir).

## F8d — FreeType antes e depois do HarfBuzz
_2026-11-05 19:59_

O FreeType é compilado duas vezes com os mesmos blocos (passos freetype2 e freetype2-harfbuzz): o configure deteta sozinho o HarfBuzz na segunda passagem, que é o que o livro pede. A documentação adicional (freetype-doc) não é descarregada e os blocos que a extraem e copiam são omitidos. No Graphite2 omitem-se o make docs e a cópia da documentação gerada (asciidoc/Doxygen/dblatex não instalados). No libpng não se aplica o patch APNG opcional; no libxml2 não se descarrega a suite de testes xmlts nem se para um httpd que não existe; no ICU omitem-se os exemplos ldd/readelf com placeholders.

## F8d — LLVM com Clang, sem compiler-rt nem testes
_2026-11-05 19:59_

O LLVM 20.1.8 é compilado como no livro (bibliotecas partilhadas libLLVM com LLVM_LINK_LLVM_DYLIB, RTTI, FFI, alvos host — X86 — e AMDGPU para o radeonsi do Mesa), incluindo o Clang (download recomendado), porque o libclc, exigido pelo driver iris do Mesa, é compilado com ele e o Mesa liga ao libclang-cpp para o compilador OpenCL interno (mesa_clc/intel_clc). O Rust só precisa do LLVM. O compiler-rt (download opcional: sanitizers e profiling) não é instalado. A suite de testes (ninja check-all, muito longa) e a correção dos testes do compiler-rt são omitidas. Ao cmake do livro acrescentou-se LLVM_PARALLEL_LINK_JOBS=2 e a compilação usa ninja -j10: a máquina de construção tem 11 GB de RAM e compilar/ligar o Clang com 14 tarefas arriscava falta de memória. Fica /etc/clang/clang{,++}.cfg com -fstack-protector-strong, como no livro.

## F8d — Mesa: drivers escolhidos
_2026-11-05 19:59_

Em vez de -D gallium-drivers=auto, a lista é explícita: iris, crocus e i915 (Intel: Broadwell e posteriores, Gen4-7 e GMA 900-3150), radeonsi, r600 e r300 (AMD/ATI), nouveau (NVIDIA), svga (VMware e VirtualBox com VMSVGA, via vmwgfx), virgl (QEMU com virtio-gpu e virglrenderer) e llvmpipe/softpipe como recurso por CPU (VirtualBox/QEMU sem 3D, bochs/std-vga). O zink fica de fora (precisa do Vulkan-Loader). Sem Vulkan (-D vulkan-drivers=""): os drivers Vulkan precisam do glslang e do Vulkan-Loader, que não estão instalados. Plataformas: só x11 (-D platforms=x11) — o Wayland e o wayland-protocols só são instalados no bloco 2 e o livro lembra que fora do GNOME/KDE só se usa x11; o EGL continua com x11, surfaceless e drm (o GBM e o glamor do Xorg funcionam). Sem VA-API/VDPAU (libva e libvdpau não instalados) e sem -D video-codecs=all: o próprio livro avisa que esses codecs têm patentes e a ISO é distribuída. O patch recomendado mesa-add_xdemos é aplicado (glxinfo e glxgears, úteis para diagnóstico). Omitidos: lspci (informativo), a suite de testes (+1,7 SBU) e a documentação HTML.

## F8d — Mesa: módulo vgem no arranque
_2026-11-05 19:59_

O livro pede CONFIG_DRM_VGEM para o llvmpipe/softpipe e avisa que, como módulo, não é carregado automaticamente. O kernel da F7 tem DRM_VGEM=m (vmwgfx, virtio-gpu, bochs, i915, xe, amdgpu, radeon e nouveau também como módulos, carregados pelo udev); acrescenta-se "vgem" a /etc/sysconfig/modules (passo mesa-vgem), sem recompilar o kernel.

## F8d — D-Bus: bootscript, machine-id e testes
_2026-11-05 19:59_

O D-Bus 1.16.2 é instalado como no livro (o utilizador/grupo messagebus, 18, já vem do LFS) e o bootscript dbus do blfs-bootscripts-20250225 (S29 nos níveis 2-5) é instalado pelo passo dbus-bootscript, no diretório do blfs-bootscripts. Mantém-se o dbus-uuidgen --ensure que o livro recomenda para compilar no chroot; como o /var/lib/dbus/machine-id ficaria igual em todas as cópias da ISO, a função limpar_machine_id (funcoes-01.sh) apaga-o no fim da F8d e o bootscript dbus gera um novo em cada arranque (dbus-uuidgen --ensure antes do daemon); /etc/machine-id é um symlink para ele. Omitidos: os testes (precisam de D-Bus Python/PyGObject e reconfiguram com asserts/intrusive_tests, impróprios para produção) e os comandos que arrancam os daemons de sistema e de sessão (não há D-Bus a correr no chroot). Mantém-se o session-local.conf com /usr/local/share/dbus-1/services.

## F8d — elogind e PAM
_2026-11-05 19:59_

O elogind 255.17 segue o livro, mas com -D man=false em vez de man=auto: o libxslt está instalado mas o DocBook não, e o xsltproc (com --nonet) falharia ao gerar as páginas. KillUserProcesses=no em /etc/elogind/logind.conf, como o livro sugere. A configuração PAM do livro é aplicada sem alterar o resto da F8: a /etc/pam.d/system-session (que só tinha pam_unix) recebe pam_loginuid (required) e pam_elogind (optional) — acrescentados só se ainda não estiverem lá — e cria-se /etc/pam.d/elogind-user. Todos os módulos usados existem no Linux-PAM da F8 (pam_loginuid, pam_access, pam_env, pam_limits, pam_keyinit) e o kernel tem CONFIG_AUDITSYSCALL, pelo que o pam_loginuid consegue escrever /proc/self/loginuid no login da consola; o pam_elogind é optional e não impede o login se o elogind não arrancar. O elogind não tem bootscript: é ativado pelo D-Bus (org.freedesktop.login1).

## F8d — Polkit
_2026-11-05 19:59_

O utilizador/grupo polkitd (27) é criado só se não existir. Usa-se -D man=false (o livro indica-o quando o libxslt está instalado sem o DocBook) e -D tests=false (os testes precisam do dbusmock e de um D-Bus de sistema a correr, que não existem no chroot). JavaScript pelo Duktape, sessões pelo elogind e autenticação pelo Linux-PAM (o /etc/lfs-release existe, pelo que o tipo de sistema é detetado). Removem-se os ficheiros systemd (/tmp/*.service e /usr/lib/{sysusers,tmpfiles}.d) como no livro. O polkitd não tem bootscript: é ativado pelo D-Bus. O agente de autenticação gráfico (polkit-gnome para o Xfce) não faz parte deste bloco.

## F8d — Xorg-Server, xinit e teclado
_2026-11-05 19:59_

O Xorg-Server 21.1.18 é compilado como no livro (glamor, logind via elogind, xkb em /var/lib/xkb, RPC seguro com o libtirpc); cria-se /etc/X11/xorg.conf.d e acrescentam-se /tmp/.ICE-unix e /tmp/.X11-unix ao /etc/sysconfig/createfiles, só se ainda não lá estiverem. O patch opcional TearFree não é aplicado (o livro só o aconselha sem compositor; o xfwm4 tem compositor). No xinit não se aplica o setuid ao Xorg nem a alteração do startx para o 1.º VT livre (o LightDM arranca o X como root; o startx sem root funciona com o elogind no VT atual). No libinput não se copia a documentação HTML (só existe com -D documentation=true, que precisa de Sphinx). Como a página "Xorg-7 Testing and Configuration" não é transcrita, o teclado português (igual ao KEYMAP=pt-latin1 da consola) é definido em /etc/X11/xorg.conf.d/00-keyboard.conf (XkbLayout "pt"), que o LightDM e o Xfce respeitam.

## F8d — Rust: LLVM do sistema, /opt/rustc e rede no chroot
_2026-11-05 19:59_

O Rustc 1.89.0 é compilado como o livro indica: contra o LLVM do sistema (bootstrap.toml com llvm-config = /usr/bin/llvm-config e link-shared = true; o LLVM do bloco 1 foi compilado com LLVM_LINK_LLVM_DYLIB=ON), só com o alvo X86, sem documentação, e instalado em /opt/rustc-1.89.0 com a ligação simbólica /opt/rustc e /etc/profile.d/rustc.sh (carregado por scripts/blfs-env.sh nas páginas seguintes). Como se compila como root no chroot, os blocos "as root" (mkdir/ln -svfn em /opt, x.py install) correm diretamente e as variáveis LIB{SSH2,SQLITE3}_SYS_USE_PKG_CONFIG mantêm-se no mesmo processo (não há sudo a filtrá-las), pelo que o cargo usa o libssh2 e o SQLite do sistema, compilados logo antes. O tarball rustc-src já traz as crates em vendor/, mas o x.py descarrega sempre o compilador stage0 de static.rust-lang.org, por isso o passo corre com rede (pacote_rede).

## F8d — Rust: test suite omitida
_2026-11-05 19:59_

A test suite do Rust (blocos 4 e 5) não corre: acrescenta cerca de 15 SBU e 7,4 GB de disco, tem falhas conhecidas documentadas no próprio livro (ui, bootstrap fora do repositório Git, musl-default-linking, linker-warning) e serve sobretudo quem desenvolve crates. O Rust só é usado aqui para compilar o cargo-c e o librsvg, cujas próprias compilações validam o compilador.

## F8d — cargo-c e librsvg: crates descarregadas no chroot
_2026-11-05 19:59_

O cargo-c não traz as dependências: o livro descarrega o Cargo.lock da versão 0.10.15 com curl e o cargo build vai buscar as crates a crates.io; o librsvg 2.61.0 também precisa de Internet para as crates (o livro avisa na secção de dependências). Ambos correm com rede (pacote_rede). O bloco do Cargo.lock foi substituído para verificar também o MD5 que o livro indica no texto (57fab87782a5f9ef46fcbddc44d425b1); as crates ficam fixadas pelas somas do Cargo.lock. A test suite do librsvg corre com falhas toleradas (o livro conhece uma falha).

## F8d — gdk-pixbuf antes do librsvg: cache dos loaders regenerada
_2026-11-05 19:59_

O gdk-pixbuf é instalado antes do librsvg (o librsvg precisa dele), pelo que a cache loaders.cache gerada na instalação do gdk-pixbuf não inclui o loader SVG que o librsvg instala depois. O livro não volta a gerar a cache; acrescentou-se o passo pixbuf-loaders (função gdk_pixbuf_loaders em scripts/gui/funcoes-02.sh) que corre gdk-pixbuf-query-loaders --update-cache e confirma que image/svg ficou registado — sem isso o GTK3 não carrega os ícones simbólicos. O bloco 4 do gdk-pixbuf (o mesmo comando, só necessário com DESTDIR) mantém-se por ser inofensivo.

## F8d — GTK3: X11 + Wayland, sem páginas de manual
_2026-11-05 19:59_

O GTK3 é compilado com os backends X11 e Wayland (explícitos; são os valores por omissão) e o Broadway do livro. A opção -D man=true do livro passa a -D man=false: as páginas de manual precisam do docbook-xsl-nons, que não está instalado (o xsltproc com --nonet falharia a meio da compilação). gtk-query-immodules-3.0 --update-cache e glib-compile-schemas correm como no livro. Os exemplos ~/.config/gtk-3.0/settings.ini e gtk.css (blocos 5 e 6) são omitidos: o tema, os ícones e a fonte são configurados para todo o sistema em scripts/gui/tema.

## F8d — Documentação opcional e Gi-DocGen
_2026-11-05 19:59_

Não se descarregam as documentações opcionais do SQLite (sqlite-doc-*.zip, que também precisaria de unzip) nem do NASM (nasm-*-xdoc.tar.xz): os respetivos blocos de extração e instalação são omitidos. Os blocos de documentação da API do Pango e do gdk-pixbuf são omitidos por precisarem do Gi-DocGen, que não está instalado.

## F8d — shared-mime-info sem xdgmime
_2026-11-05 19:59_

O tarball xdgmime é um download opcional que só serve para correr a test suite do shared-mime-info; não é descarregado e o bloco que o compila é omitido. A base de dados MIME é gerada na instalação (-D update-mimedb=true, como no livro).

## F8d — SQLite: opções do livro e módulo sqlite3 do Python
_2026-11-05 19:59_

O SQLite é compilado com as opções do livro (--enable-fts4/5 e CPPFLAGS com SQLITE_ENABLE_COLUMN_METADATA, UNLOCK_NOTIFY, DBSTAT_VTAB e SECURE_DELETE), necessárias ao Rust/cargo e a outras aplicações. O livro recomenda recompilar o Python depois do SQLite para criar o módulo sqlite3; não se faz aqui porque nenhuma página da interface gráfica precisa dele.

## F8d — Testes de Wayland, libxkbcommon, GTK3 e at-spi2-core
_2026-11-05 19:59_

Estas test suites não estão em blocos de comandos do livro (só no texto) e precisam de coisas ausentes no chroot (Xvfb, sessão gráfica, sessão D-Bus a correr, XDG_RUNTIME_DIR), por isso não correm.

## Xfce: documentação e sessão pelo LightDM
_2026-11-05 19:59_

As páginas do Xfce (libxfce4util, xfconf, libxfce4ui, libxfce4windowing, exo, garcon, xfce4-panel, xfce4-session, xfwm4, thunar, xfdesktop, xfce4-settings, xfce4-appfinder, tumbler, xfce4-notifyd, xfce4-terminal) seguem o livro sem alterações: o gtk-doc já vem desligado por omissão nos configure do Xfce e o Vala não está instalado, pelo que as bindings ficam de fora automaticamente. O libxfce4windowing deteta o Wayland (GTK3 foi compilado com o backend Wayland) e usa os wlr-protocols incluídos no tarball. Nada de painel, tema ou aspeto é configurado aqui (fica para scripts/gui/tema).

## xfce4-session: sem ~/.xinitrc
_2026-11-05 19:59_

Os blocos 4 e 5 (criar ~/.xinitrc com "dbus-launch --exit-with-x11 startxfce4" e correr startx) foram omitidos: são para o utilizador que arranca o X à mão e o startx é interativo. A sessão é lançada pelo LightDM a partir de /usr/share/xsessions/xfce.desktop (Exec=startxfce4), que o próprio make install do xfce4-session instala (XSESSION_PREFIX=/usr por omissão); o startxfce4 arranca o dbus-launch sozinho quando não há bus de sessão, pelo que não é preciso nenhum equivalente sistémico do ~/.xinitrc. O bloco 3 (update-desktop-database e update-mime-database) é mantido: desktop-file-utils e shared-mime-info já estão instalados.

## libnotify, VTE e xfce4-notifyd: blocos omitidos
_2026-11-05 19:59_

libnotify bloco 2 (documentação com GTK-Doc) e VTE bloco 2 (documentação com Gi-DocGen) foram omitidos por as ferramentas não estarem instaladas. xfce4-notifyd bloco 3 (notify-send de teste) foi omitido: precisa de uma sessão gráfica e de um bus D-Bus de sessão, inexistentes no chroot.

## VTE sem GnuTLS, GTK-4 e Vala
_2026-11-05 19:59_

O meson_options.txt do VTE 0.80.3 tem gnutls, gtk4 e vapi ligados por omissão (com "required"), e nenhum destes está instalado. Ao comando do livro acrescentou-se -D gnutls=false -D gtk4=false -D vapi=false (opções descritas nas "Command Explanations" da página). Ficam ligados: GTK3, ICU, FriBidi, GObject Introspection (vem com a GLib) e fast_float; o liblz4 obrigatório já vem do LFS. Só se instala libvte-2.91.so (GTK3), que é o que o xfce4-terminal usa. O "rm -v /etc/profile.d/vte.*" do livro é mantido.

## alsa-lib fora deste bloco
_2026-11-05 19:59_

A alsa-lib (e o alsa-ucm-conf) já é instalada na F8c "Drivers e firmware", pelo que não faz parte destes passos. Não se reconfigura o kernel: o som vem como módulos no kernel de base Arch (F7).

## libcanberra: patch do livro, sem GStreamer/PulseAudio/GTK2
_2026-11-05 19:59_

O patch libcanberra-0.30-wayland-1.patch é obrigatório no livro e é descarregado automaticamente (blfs-fetch.py: patch-obrigatorio). O configure segue o livro (--disable-oss); GStreamer, PulseAudio e GTK2 não estão instalados e o configure deteta-os como ausentes, ficando só o backend ALSA e libcanberra-gtk3.

## libgpg-error e libgcrypt acrescentadas antes do LightDM
_2026-11-05 19:59_

A página do LightDM dá o libgcrypt como dependência obrigatória, e este precisa do libgpg-error; nenhum dos dois está no sistema nem em scripts/gui/ordem.txt (o resolver não os apanhou). Acrescentaram-se os passos general/libgpg-error e general/libgcrypt, como no livro, entre o itstool e o LightDM. A documentação HTML/texto do libgcrypt é gerada com o makeinfo do Texinfo do LFS, como na página. O Vala (recomendado) não é instalado: o LightDM compila sem as bindings Vala.

## LightDM: utilizador, Xorg e greeter
_2026-11-05 19:59_

O utilizador e o grupo lightdm (uid/gid 65, livres no sistema) só são criados se não existirem, para o passo poder ser repetido. O greeter lightdm-gtk-greeter-2.0.9 é o download adicional da página (--extra lightdm-gtk-greeter) e compila-se com o libxklavier, como no livro. O bloco que cria /usr/bin/X a partir de /opt/xorg foi substituído: o Xorg está em /usr (XORG_PREFIX=/usr), pelo que apenas se garante a ligação /usr/bin/X -> Xorg (o LightDM usa xserver-command=X por omissão) se o xorg-server não a tiver criado.

## LightDM: PAM
_2026-11-05 19:59_

O livro troca pam_systemd por pam_elogind nos três ficheiros de data/pam (lightdm, lightdm-autologin, lightdm-greeter); esses ficheiros só usam pam_nologin, pam_env, pam_unix, pam_permit, pam_deny, pam_succeed_if e pam_elogind (opcional), todos do Linux-PAM/elogind já instalados. São ficheiros novos em /etc/pam.d com nome próprio: não alteram login, su, sshd, sudo nem os system-* do BLFS, pelo que os logins de texto e por ssh não são afetados. Não se usou o modelo "include system-login" de outras distribuições porque o BLFS não tem esse ficheiro.

## LightDM: configuração funcional e arranque no runlevel 5
_2026-11-05 19:59_

O "telinit 5" do livro não pode correr no chroot. Em seu lugar cria-se /etc/lightdm/lightdm.conf.d/10-ianinjapelagestao.conf com [Seat:*] greeter-session=lightdm-gtk-greeter e user-session=xfce (o LightDM lê lightdm.conf.d antes de lightdm.conf; sem user-session o valor por omissão seria "default", que não existe), e confirma-se que existem xfce.desktop, o .desktop do greeter, o binário e os ficheiros PAM. O make install-lightdm do blfs-bootscripts-20250225 (passo lightdm-bootscript, função bootscripts da etapa) instala /etc/rc.d/init.d/xdm e /etc/sysconfig/xdm com DISPLAY_MANAGER=/usr/bin/lightdm e acrescenta ao /etc/inittab "dm:5:respawn:/etc/rc.d/init.d/xdm". O passo lightdm-runlevel5 muda "id:3:initdefault:" para "id:5:initdefault:", garante que todo o S* de rc3.d existe também em rc5.d (hoje os dois são iguais: sysklogd e network), e confirma que os agetty de tty1-tty6 e ttyS0 (definidos para os runlevels 2345 na F6) continuam ativos no 5. O LightDM ocupa o vt7 (minimum-vt=7 por omissão), que nenhum agetty usa; o login na ttyS0 e em tty1-6 mantém-se. Para voltar ao modo texto basta acrescentar "3" à linha do kernel no GRUB ou "telinit 3".

## Tipos de letra: DejaVu e Liberation
_2026-11-05 19:59_

A página TTF-and-OTF-fonts não tem tarball e o seu único bloco pressupõe a DejaVu já extraída, pelo que é substituída pela função fontes_ttf. Instalam-se a DejaVu 2.37 (a página do livro usa-a como exemplo; fallback com grande cobertura Unicode e inclui DejaVu Sans Mono, usada no terminal) e a Liberation 2.1.5 (métricas compatíveis com Arial, Times New Roman e Courier New, para documentos e páginas web), cerca de 9 MB no total. Os tarballs são descarregados no host para $LFS/sources a partir das releases oficiais no GitHub e verificados por SHA-256 fixado no script; os .ttf vão para /usr/share/fonts/dejavu e /usr/share/fonts/liberation, as licenças para /usr/share/doc, e corre-se fc-cache -f. O Noto (completo ou Color Emoji) não foi incluído por causa do tamanho na ISO; a fonte de interface (Inter) é instalada pelo tema.

## xfce4-terminal sem página de manual
_2026-11-05 19:59_

O meson.build do xfce4-terminal 1.1.5 gera sempre a página de manual com xsltproc --nonet e a folha de estilos DocBook XSL, que não está instalada (o passo falhava a compilar doc/xfce4-terminal.1) e não oferece opção para a desligar. Antes do meson setup retira-se a linha subdir('doc') do meson.build; o resto segue o livro. Fica sem man xfce4-terminal.

## Tema: aspeto ao estilo do macOS com temas livres WhiteSur
_2026-11-05 19:59_

O aspeto pedido (moderno, ao estilo do macOS) é dado por temas livres e maduros do projeto WhiteSur (github.com/vinceliuice), todos fixados numa tag ou commit e verificados por SHA-256 (scripts/gui/tema/fontes.txt e scripts/gui/funcoes-04.sh). Tema GTK/xfwm4: WhiteSur-gtk-theme, tag 2026-09-10 (commit 99247ecd219bdc1c7409baff062b4aafcf1102a7), arquivo do GitHub com SHA-256 65516c8f45da45c602471e31b4de0b6e9aed6eb3fc3820df16161d077245a1a2, licença MIT. Ícones: WhiteSur-icon-theme, tag 2026-09-10 (commit 73d8040da51a9ed74e47c7366e7e9ff437601a5c), SHA-256 406c9cd59705583f1754b0eaca96cc48bafda042b88ef143f16d8ae1820ecd95, licença GPL-3.0. Cursores: WhiteSur-cursors, sem tags nem releases, fixado no commit e190baf618ed95ee217d2fd45589bd309b37672b (2025-04-05), SHA-256 35c817c2c26bc4d2c06801cfe6c924a068ad771d3846c5203b04d1c893dd5664, licença GPL-3.0. Os textos das licenças ficam em /usr/share/doc/whitesur-*. Os arquivos .tar.gz são os que o GitHub gera para cada tag/commit; se o GitHub os voltar a gerar com outra compressão a soma muda e o download falha (não passa nada sem verificação).

## Tema GTK: variantes pré-geradas, sem sassc
_2026-11-05 19:59_

O install.sh do WhiteSur-gtk-theme compila o tema a partir de SCSS e precisa do sassc (e do glib-compile-resources, xmllint...), que não está instalado. O repositório traz em release/ os temas já gerados (WhiteSur-{Light,Dark}[-solid][-nord].tar.xz, com gtk-2.0, gtk-3.0, gtk-4.0, xfwm4, metacity, gnome-shell, cinnamon, unity e plank; release-info.txt: gerados em 2025-12-27 e incluídos na tag 2026-09-10). Usam-se esses: WhiteSur-Light (por omissão), WhiteSur-Dark e as variantes -solid (sem transparências, para máquinas lentas ou sem compositor), em /usr/share/themes. Apagam-se gnome-shell, cinnamon, unity, plank e metacity-1, que o Xfce não usa (o gnome-shell traz o logótipo da Apple no botão "Atividades"). Ocupam cerca de 10 MB.

## Ícones e cursores: sem ferramentas em falta; logótipo da Apple substituído
_2026-11-05 19:59_

O install.sh do WhiteSur-icon-theme só usa cp, sed, ln e gtk-update-icon-cache (do GTK3) e corre no chroot com -d /usr/share/icons, instalando WhiteSur, WhiteSur-light e WhiteSur-dark (cerca de 100 MB sem compressão; os SVG comprimem bem no SquashFS). O tema usa o logótipo da Apple nos ícones start-here (menu de aplicações); todos os start-here.svg são substituídos pelo logótipo próprio da distribuição (ianinja-logo.svg) e os start-here-symbolic.svg pela versão simbólica, e apaga-se folder-apple (pasta com o logótipo da Apple, sem uso). Ficam os restantes ícones do tema, incluindo ícones de aplicações de terceiros e de dispositivos (iPhone/iPad), como em qualquer distribuição que inclua o WhiteSur. Os cursores vêm já gerados em dist/ (o build.sh precisaria do inkscape) e são copiados para /usr/share/icons/WhiteSur-cursors; /usr/share/icons/default/index.theme herda deles (cursor do X e do LightDM).

## Dock: xfce4-docklike-plugin 0.5.1
_2026-11-05 19:59_

A dock é um segundo painel do xfce4-panel com o plugin xfce4-docklike-plugin 0.5.1 (2026-03-02; archive.xfce.org/src/panel-plugins/xfce4-docklike-plugin/0.5/, SHA-256 9d7b355c2be37fb0a73b77b4ed75f092d23c012a67b102c9f847c55ddc3095df, licença GPL-3.0 ou posterior). O arquivo da Xfce não publica soma para este plugin; a SHA-256 foi calculada após o download. A 0.5.x só tem meson (o autotools foi retirado) e exige glib >= 2.58, GTK3 >= 3.24, cairo, libxfce4panel/libxfce4ui/libxfce4util >= 4.16, libxfce4windowing(+ui, +x11) >= 4.19.4 e libX11/libXi — tudo já instalado por páginas de ordem.txt (xfce4-panel 4.20.5, libxfce4windowing 4.20.4, gtk3, Xorg libs); o código que precisa do libxfce4ui 4.21 está protegido por LIBXFCE4UI_CHECK_VERSION. Compila-se só com X11 (-D x11=enabled -D wayland=disabled): o backend Wayland exige o gtk-layer-shell, que não existe, e a sessão Xfce 4.20 do sistema é X11. Fica em /usr/lib/xfce4/panel/plugins/libdocklike.so (--libdir=/usr/lib, como o xfce4-panel). O diretório de fontes é apagado no fim. Configuração inicial: /etc/xdg/xfce4/panel/docklike.rc (o plugin procura-a em XDG_CONFIG_DIRS quando o utilizador ainda não tem a sua) com Thunar, Terminal, Localizador de aplicações e Definições fixados, ícones de 48 px e pontos por baixo das aplicações abertas.

## Painéis: barra superior e dock em /etc/xdg/xfce4/panel/default.xml
_2026-11-05 19:59_

Os dois painéis são definidos em /etc/xdg/xfce4/panel/default.xml (substitui o do xfce4-panel), e não em /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml: no xfce4-panel 4.20, quando o utilizador não tem o canal xfce4-panel, o programa migrate copia o default.xml para o canal do utilizador sem fazer perguntas, e a partir daí tudo pode ser mudado ou apagado; com o canal em /etc/xdg/xfconf, os plugins definidos no sistema não podem ser removidos pelo utilizador (o xfconf volta a mostrar os valores de sistema). Painel 1 (barra superior, 28 px a toda a largura, translúcido): menu de aplicações com o logótipo da distribuição, menu de janelas (ícone da janela ativa; abre a lista de janelas), espaço, área de notificação, relógio "%a %d %b  %H:%M" (Inter Medium) e um botão de sair que abre o diálogo de terminar sessão/reiniciar/desligar. Painel 2 (dock): centrado em baixo, ajustado ao conteúdo, 64 px com ícones de 48 px, escondido de forma inteligente (aparece quando nenhuma janela o tapa), fundo translúcido; os cantos arredondados vêm de ~/.config/gtk-3.0/gtk.css (o GTK3 não tem gtk.css de sistema), posto em /etc/skel e copiado para /home/ninja e /root. Não existe menu global de aplicações (como o do macOS): o Xfce não o tem sem plugins e bibliotecas extra (appmenu), e o painel não mostra o nome da janela ativa por extenso, só o ícone.

## Janelas, fontes e definições GTK
_2026-11-05 19:59_

xfwm4 (/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml): tema WhiteSur-Light, botões Fechar/Minimizar/Maximizar à esquerda (button_layout "CHM|", semáforo do tema), título centrado em Inter Semi-Bold, compositor ligado com sombras nas janelas e menus (não na dock, para não aparecer uma sombra retangular à volta dos cantos redondos), janelas novas centradas, 2 áreas de trabalho. xsettings.xml parte do ficheiro do xfce4-settings 4.20.2, com tema WhiteSur-Light, ícones WhiteSur, cursor WhiteSur-cursors 24 px, fonte Inter 10, monoespaçada JetBrains Mono 10, antialiasing em tons de cinzento com hinting ligeiro e os botões das janelas GTK com barra de título própria (CSD) também à esquerda. Os mesmos valores ficam em /etc/gtk-3.0/settings.ini para aplicações GTK fora do Xfce. Fontes: Inter 4.1 (github.com/rsms/inter, Inter-4.1.zip, SHA-256 9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e, SIL OFL 1.1; 10 estilos estáticos de extras/ttf) e JetBrains Mono 2.304 (JetBrainsMono-2.304.zip, SHA-256 6f6376c6ed2960ea8a963cd7387ec9d76e3f629125bc33d1fdcd7eb7012f7bbf, SIL OFL 1.1; 6 estilos), em /usr/share/fonts/inter e /usr/share/fonts/jetbrains-mono, extraídas com o módulo zipfile do Python (o unzip não está instalado), seguidas de fc-cache -f. /etc/fonts/conf.d/52-ianinja-tema.conf torna-as as preferidas para sans-serif e monospace (DejaVu como alternativa).

## Papel de parede, logótipo e ambiente de trabalho
_2026-11-05 19:59_

O papel de parede (/usr/share/backgrounds/ianinja/ianinja-claro.svg) e o logótipo (ianinja-logo.svg e ianinja-logo-symbolic.svg em /usr/share/icons/hicolor/scalable/apps) são originais, feitos para o ianinjapelagestao (domínio público, CC0): gradiente claro azul-lilás-pêssego com manchas suaves (só gradientes, sem filtros, para o librsvg o desenhar depressa em qualquer resolução) e o nome da distribuição discreto no canto inferior direito; o logótipo é uma cabeça de ninja com faixa e olhos. Não se usa nenhum logótipo nem marca da Apple. O xfdesktop 4.20 guarda o fundo por ligação de monitor (monitorVirtual-1, monitoreDP-1, ...), que só se conhece no arranque: xfce4-desktop.xml define as ligações mais comuns e, para as outras, a imagem por omissão compilada no xfdesktop (/usr/share/backgrounds/xfce/xfce-x.svg) passa a ser uma ligação simbólica para o papel de parede (o original fica como xfce-x-original.svg). No ambiente de trabalho aparecem a pasta pessoal, o lixo e os discos amovíveis.

## Atalho Super+Espaço (pesquisa rápida) e terminal
_2026-11-05 19:59_

Os atalhos de teclado por omissão vêm do libxfce4ui (/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml) e esse ficheiro define a lista inteira. Em vez de o substituir, acrescenta-se ao ficheiro instalado (com python3 xml.etree, já que o xmlstarlet não existe) o atalho Super+Espaço (Super+space) a abrir "xfce4-appfinder --collapsed"; Alt+Espaço continua a abrir o menu da janela (xfwm4). O xfce4-appfinder (xfce4-appfinder.xml) abre centrado, sem decoração, fecha ao perder o foco e ordena pelos mais usados, como uma pesquisa do tipo Spotlight. xfce4-terminal 1.1.5: desde a 1.1 as preferências estão no canal xfconf xfce4-terminal (xfce4-terminal.xml); /etc/xdg/xfce4/terminal/terminalrc tem os mesmos valores e só é importado se o canal não existir. Esquema claro próprio (fundo branco, texto #1d1d1f, paleta de 16 cores suaves), JetBrains Mono 11, sem barra de menus, 100x30, cursor em I.

## Ecrã de início de sessão (lightdm-gtk-greeter)
_2026-11-05 19:59_

/etc/lightdm/lightdm-gtk-greeter.conf: tema WhiteSur-Light, ícones WhiteSur, cursor WhiteSur-cursors, Inter 11, fundo = papel de parede da distribuição (sem fundo por utilizador: não há AccountsService), caixa de entrada centrada, imagem do utilizador redonda, barra superior com o nome da máquina, o relógio no formato do painel, teclado, idioma, sessão, acessibilidade e energia. O aspeto ao estilo do macOS (caixa translúcida com cantos arredondados, sombra suave, campos arredondados) vem de /var/lib/lightdm/.config/gtk-3.0/gtk.css: o greeter corre como utilizador lightdm com HOME=/var/lib/lightdm e o GTK3 lê o gtk.css do utilizador; o ficheiro pertence ao lightdm.

## Configuração para todos os utilizadores
_2026-11-05 19:59_

Toda a configuração vai para /etc/xdg (lida por todos os utilizadores enquanto não tiverem a sua em ~/.config), /etc/gtk-3.0, /etc/fonts, /etc/lightdm e /usr/share, a partir da árvore scripts/gui/tema/raiz (copiada sem preservar o dono). Para o ninja (já criado) e o root só se copia ~/.config/gtk-3.0/gtk.css (cantos da dock) e apaga-se qualquer ~/.config/xfce4, para que nada se sobreponha às predefinições (não devia existir nenhuma). Novos utilizadores recebem o gtk.css de /etc/skel. A verificação final confirma ficheiros, temas, caches de ícones, fontes (fc-match sans-serif = Inter, monospace = JetBrains Mono), o loader SVG do gdk-pixbuf, o desenho dos SVG com rsvg-convert, as bibliotecas do docklike e que todos os XML são válidos (python3 xml.etree).

## Live: Rust e caches do cargo fora do SquashFS
_2026-11-05 20:02_

O Rust (/opt/rustc, mais de 1 GB) e as caches do cargo (~/.cargo) só servem para compilar o librsvg e o cargo-c na F8d; nenhum programa da ISO precisa deles em execução (o librsvg é uma biblioteca nativa). Por isso são excluídos do rootfs.squashfs, reduzindo a ISO; o /etc/profile.d/rustc.sh fica, mas só acrescenta ao PATH um diretório inexistente. O LLVM fica, porque o Mesa (llvmpipe, radeonsi) usa a libLLVM em execução.

## Sistema live com interface gráfica
_2026-11-05 20:02_

Depois da F8d a imagem live leva o Xorg, o Mesa, o GTK3, o Xfce, o LightDM e o tema, sem mudanças no initramfs: o X não precisa de nada no arranque precoce — os drivers DRM (bochs, virtio-gpu, vmwgfx, i915, amdgpu, nouveau) são módulos carregados pelo udev já na raiz final, o /dev é o devtmpfs movido do initramfs (o udev aplica as permissões de /dev/dri), o Xorg corre como root lançado pelo LightDM, e /run, /tmp (1777) e /var são graváveis no OverlayFS; /tmp/.X11-unix e /tmp/.ICE-unix são criados pelo createfiles. O '3' do GRUB (modo texto) chega ao SysVinit porque o /init passa os seus argumentos ao switch_root. O mksquashfs passa a excluir também var/lib/dbus/machine-id (e antes apaga-o, e troca um /etc/machine-id regular pelo symlink, se aparecer), registos do X/LightDM (var/log/Xorg.*, var/log/lightdm/*), mapas de teclado compilados (var/lib/xkb/*.xkm) e caches de utilizador (root/.cache, home/*/.cache); NÃO exclui /var/lib/lightdm (tem o gtk.css do greeter) nem /var/cache/fontconfig. Depois do mksquashfs, se o LightDM estiver instalado, confirma-se com unsquashfs -l que a imagem tem o LightDM, o Xorg, o greeter, o startxfce4, a sessão xfce.desktop, o tema WhiteSur-Light, o gtk.css do greeter e os bootscripts xdm e dbus, e que não tem o machine-id. Tamanho: o SquashFS não é copiado para a RAM (é lido da ISO por loop), por isso a RAM necessária não cresce com ele; só a camada de escrita vive em tmpfs (até 50 % da RAM, por omissão do tmpfs). O limite de 4 GiB por ficheiro da ISO9660 deixou de fazer falhar a F9: se o rootfs.squashfs chegar a 4 GiB, a F10 gera a ISO com -iso-level 3.

## GRUB: modo texto e modo seguro sem interface gráfica
_2026-11-05 20:02_

Com a interface gráfica (F8d) o /etc/inittab arranca no nível 5 (LightDM no vt7). Acrescentou-se ao grub.cfg (o mesmo ficheiro serve o arranque BIOS e o UEFI do grub-mkrescue) a entrada 'ianinjapelagestao 12.4 (Live - modo texto, sem interface gráfica)', igual à normal mais ' 3' no fim da linha do kernel: o kernel não reconhece o '3' e passa-o como argumento ao /init do initramfs, que o entrega ao /sbin/init no switch_root ("$@"), e o SysVinit arranca no nível 3 (só consolas de texto, sem LightDM). A entrada 'modo seguro/verbose' também passou a ter ' 3': com nomodeset os drivers DRM nativos (bochs, virtio-gpu, vmwgfx, i915, amdgpu...) não carregam, o Xorg com o driver modesetting não encontra um ecrã utilizável e o LightDM ficaria a reiniciar o X em ciclo. A entrada por omissão continua a ser a 0 ('ianinjapelagestao 12.4 (Live)', agora com interface gráfica), cujo texto exato os testes F11 procuram; os títulos novos não contêm a cadeia '(Live)' e por isso não a confundem. A entrada 'sem persistência' arranca com interface gráfica, como a normal.

## Testes F11: módulos carregados automaticamente
_2026-11-05 20:03_

Com o kernel de drivers em módulos (base Arch, F7) acrescentou-se o critério 10 'Módulos carregados automaticamente (snd_hda_intel via udev)' aos modos BIOS e UEFI, que passam a ter 10 critérios: a VM ganha uma placa de som HDA (-device intel-hda -device hda-duplex), cujo driver snd_hda_intel é módulo; depois do login confirma-se, sem nada carregar à mão, que 'lsmod' o mostra (espera até 20 s) e que /lib/modules/$(uname -r)/kernel existe (o comando mostra também o número de módulos carregados e /proc/asound/cards). Escolheu-se a placa de som porque a rede (e1000) tem de continuar embutida para o critério 5 não depender de módulos, e o som não tem driver embutido nenhum. O teste de persistência passa a ser o critério 11 (sem placa de som, igual ao anterior).

## Testes F11: interface gráfica
_2026-11-05 20:03_

Com o nível 5 por omissão (F8d) o login de teste continua a ser pela ttyS0: o agetty da ttyS0 (e os de tty1-6) está ativo nos níveis 2345 e o LightDM usa o vt7, pelo que os critérios 1-11 não mudam. A VM passa a ter -vga std explícito (placa bochs, cujo driver DRM bochs é módulo carregado pelo udev e dá KMS ao Xorg com o driver modesetting; -nographic só tira a janela, a placa existe) e, nos modos BIOS e UEFI, o monitor do QEMU num socket unix (logs/11-monitor-<modo>.sock; com -monitor explícito a série fica sozinha no stdio). Novos critérios nos modos BIOS e UEFI, que passam a ter 13: 12 'LightDM a correr no nível 5' (pidof lightdm, mostrando runlevel e a linha id: do inittab); 13 'Xorg arrancou (modesetting, sem Fatal server error) e greeter ativo' (pidof Xorg ou X, /var/log/Xorg.0.log — ou /var/log/lightdm/x-0.log — com o módulo modesetting carregado e sem 'Fatal server error', e pidof lightdm-gtk-greeter); 14 'Fonte Inter e tema WhiteSur-Light' (fc-list : family começa por Inter e existe /usr/share/themes/WhiteSur-Light/gtk-3.0). Para 12-13 espera-se até 180 s com KVM e 600 s sem KVM (sem KVM o Xorg e o greeter demoram minutos a arrancar): não terem aparecido conta como timeout (LENTO sem KVM, FAIL com KVM); 'Fatal server error' é sempre FAIL. Correm antes do critério 9 (IA), cuja carga não deve atrasar o X. Se o critério 13 passar, tira-se uma captura do greeter pelo monitor (comando screendump, em PPM, enviado com socat) e converte-se para logs/11-ecra-<modo>.png com scripts/ppm-para-png.py (só a biblioteca padrão do Python: o host não tem ImageMagick, netpbm nem PIL, e não se instalou nada); a captura é só informativa (linha INFO) e nunca falha o teste. O teste de persistência (critério 11) mantém o monitor no stdio, como antes.

## VS Code, Google Chrome, Claude Code e Codex instalados no 1.º uso (não vão na ISO)
_2026-11-06 14:36_

A ISO é pública e live. As licenças do Visual Studio Code (Microsoft, https://code.visualstudio.com/license) e do Google Chrome (https://www.google.com/chrome/terms/) não permitem redistribuir os binários oficiais; o Claude Code (Anthropic) é software proprietário distribuído só pela Anthropic; o Codex CLI é Apache-2.0, mas trata-se da mesma forma porque muda de versão quase todas as semanas e assim cada utilizador fica com a versão atual. Por isso a ISO leva só as bibliotecas de que precisam e o comando /usr/bin/instalar-aplicacoes, que os descarrega a pedido (menu, ou instalar-aplicacoes vscode|chrome|claude|codex|tudo; -l mostra o estado; repetir = atualizar). Atalho "Instalar aplicações" no menu (Sistema) e fixado na dock (abre o xfce4-terminal com o menu).

## Origem das transferências e verificação
_2026-11-06 14:36_

VS Code: API oficial https://update.code.visualstudio.com/api/update/linux-x64/stable/latest (dá o URL do tar.gz linux-x64, a versão e o SHA-256); extraído em streaming para /opt/vscode, SHA-256 conferido no fim. Chrome: índice do repositório apt oficial https://dl.google.com/linux/chrome/deb/dists/stable/main/binary-amd64/Packages (versão, caminho e SHA-256 do google-chrome-stable_*.deb), .deb descarregado, conferido e extraído com ar + tar; só opt/google/chrome, os .desktop e os ícones são usados (sem o postinst, sem a fonte apt nem o cron de atualização). Claude Code: instalador oficial curl -fsSL https://claude.ai/install.sh | bash, corrido como o utilizador que chamou o comando (nunca como root; o próprio instalador recusa sudo), que verifica o SHA-256 do manifesto da Anthropic e põe ~/.local/bin/claude (com atualização automática própria); o comando acrescenta ~/.local/bin ao PATH no ~/.bashrc se faltar. Codex: release mais recente de https://github.com/openai/codex/releases, anexo codex-x86_64-unknown-linux-musl.tar.gz (binário estático musl, SHA-256 do campo digest da API do GitHub) para /usr/local/bin/codex; e o ripgrep oficial (https://github.com/BurntSushi/ripgrep/releases, ripgrep-<versão>-x86_64-unknown-linux-musl.tar.gz, estático) para /usr/local/bin/rg, que o Codex e os agentes usam para pesquisar código. Antes de descarregar verifica a Internet e o espaço livre (VS Code ~1,7 GB, Chrome ~0,9 GB, Claude ~0,8 GB, Codex ~0,5 GB); numa sessão live sem disco IANINJA-DADOS avisa que tudo se perde ao desligar e sugere sudo ia-criar-persistencia.

## Dependências: o que o ldd mostrou em falta
_2026-11-06 14:36_

Analisadas as dependências (NEEDED, recursivamente, contra /mnt/lfs/usr/lib) do VS Code 1.145.0 e do Chrome 157.0.8103.38 oficiais. Em falta no sistema: libnspr4.so, libnss3.so, libnssutil3.so, libsmime3.so (NSPR + NSS) e libcups.so.2 (CUPS), nos dois. Tudo o resto (GTK3, ATK/AT-SPI, libgbm/Mesa, libdrm, libxkbcommon, libXss, libxkbfile, libxshmfence, ALSA, libudev, libnotify, libcurl, libpci) já existe da F8d. Opcionais ignorados: libqt5_shim/libqt6_shim do Chrome (integração com Qt, só carregados com o tema Qt) e o msal-node-runtime.node do VS Code (início de sessão Microsoft por broker; precisaria de WebKitGTK e libsoup 3, muito pesados — o início de sessão faz-se pelo navegador). Carregados com dlopen: libsecret-1.so.0 (cofre de segredos) — instalada; libvulkan.so.1 vem com o próprio Chrome/VS Code. O Claude Code é um binário nativo que só usa a glibc (tem o ripgrep embutido); o Codex é estático (musl) e traz o bubblewrap embutido para a sandbox (precisa de CONFIG_USER_NS=y e Landlock/seccomp, que o kernel da F7 tem). Nenhum dos dois precisa de Node.js, por isso o general/nodejs não entra.

## Páginas do BLFS acrescentadas e cortes
_2026-11-06 14:36_

Ordem: NSPR, NSS, Nettle, GnuTLS, xdg-utils, CUPS (+ bootscript), libsecret. Cortados: cups-filters ("Required (Postinstall)", arrasta libcupsfilters, Ghostscript, Poppler, Qt6... — sem ele o CUPS não converte trabalhos para a maioria das impressoras, mas a libcups funciona), colord (recomendado do CUPS), gnome-keyring (dependência de execução do libsecret: arrasta GnuPG, OpenLDAP, Cyrus SASL, pinentry e gcr), Vala, xmlto/DocBook (requerido do xdg-utils só para gerar documentação) e o Links (já há o Lynx, que o xdg-utils aceita). NSS: testes omitidos (all.sh precisa de rede e de nome de máquina resolúvel).

## CUPS instalado mas sem arrancar
_2026-11-06 14:36_

O CUPS entra só pela libcups.so.2 que o Chrome e o VS Code exigem. O bootscript é instalado (make install-cups, passo cups-bootscript), mas o passo cups-sem-arranque tira os links S35cups dos níveis 2-5 (ficam os K00 de paragem, inofensivos) e marca o atalho cups.desktop com NoDisplay=true. O ninja fica no grupo lpadmin. Para imprimir: sudo /etc/rc.d/init.d/cups start (ou recriar /etc/rc.d/rc{2,3,4,5}.d/S35cups -> ../init.d/cups) e instalar o cups-filters. No atalho do CUPS o navegador @CUPS_HTMLVIEW@ é xdg-open (o livro usa firefox, que não existe).

## libsecret sem Vala nem páginas de manual
_2026-11-06 14:36_

meson com -D vapi=false (o Vala não está instalado), -D manpage=false (precisaria do docbook-xsl) e -D gtk_doc=false; o bloco 2 (documentação com gi-docgen) é omitido. Cifra: libgcrypt (já instalado). Sem gnome-keyring não há serviço org.freedesktop.secrets: os lançadores /usr/bin/code e /usr/bin/google-chrome detetam-no pela sessão D-Bus (NameHasOwner/ListActivatableNames) e, se faltar, passam --password-store=basic (tokens guardados localmente, como o Chromium faz sem cofre) em vez de mostrarem o aviso "OS keyring couldn't be identified". Se o utilizador instalar um cofre (gnome-keyring, KeePassXC), passa a ser usado sozinho.

## xdg-utils sem xmlto
_2026-11-06 14:36_

O make do xdg-utils 1.2.1 gera os scripts a partir de *.in + *.txt, e os *.txt (texto de ajuda) com xmlto txt a partir do DocBook em scripts/desc/*.xml. Sem xmlto/DocBook, o bloco 1 é substituído: os *.txt são gerados tirando as marcas XML com sed e corre-se só make scripts (sem páginas de manual nem HTML). O --help/--manual de cada xdg-* fica com texto simples; o funcionamento (xdg-open, xdg-settings, xdg-mime, xdg-icon-resource, xdg-desktop-menu) é o mesmo.

## Sandbox do Chromium (Chrome e VS Code)
_2026-11-06 14:36_

O chrome-sandbox fica com dono root e setuid (4755), como fazem os .deb oficiais; além disso o kernel tem namespaces de utilizador (CONFIG_USER_NS=y), que o Chromium usa primeiro. Os lançadores só acrescentam --no-sandbox, com aviso no terminal, se nenhum dos dois funcionar (unshare -Ur falha e o chrome-sandbox não é 0:4755 ou está num sistema de ficheiros nosuid).

## Instalar tudo no 1.º início de sessão
_2026-11-06 14:36_

/etc/xdg/autostart/instalar-tudo-default.desktop corre instalar-tudo-click.sh, que (com Internet e se faltar alguma das 4 aplicações) abre um terminal com "instalar-aplicacoes tudo"; o utilizador aceita cada licença. Pergunta uma só vez por pasta pessoal (~/.config/ianinjapelagestao/instalar-tudo.perguntado); manual: instalar-tudo-click.sh --agora. No fim do Chrome, o instalar-aplicacoes torna-o navegador predefinido (xdg-mime, xdg-settings e ~/.config/xfce4/helpers.rc). Não usa apt (o sistema não tem gestor de pacotes Debian).

## OpenCV sem as dependências multimédia recomendadas
_2026-11-06 14:36_

O livro recomenda FFmpeg, gst-plugins-base, xine-lib, v4l-utils, jasper, libavif e OpenJPEG para o opencv. Juntas puxariam mais de vinte páginas (libaom, x264, x265, libvpx, PulseAudio, GStreamer, libdvdnav...) só para ler e gravar vídeo e formatos de imagem raros. O face-finder só lê ficheiros de imagem: JPEG, PNG, TIFF e WebP chegam pelas bibliotecas que já existem (libjpeg-turbo, libpng, libtiff) ou pelas cópias internas do OpenCV. A interface GTK3 do highgui fica ativa (o GTK já está instalado). O Video4Linux (só cabeçalhos do kernel) mantém-se, por isso cv2.VideoCapture continua a funcionar com câmaras USB.

## OpenCV: WITH_IPP=OFF, sem G-API e sem opencv_contrib
_2026-11-06 14:36_

Durante o cmake o OpenCV descarrega o ippicv (Intel IPP) e o ADE (para o módulo G-API). O chroot não tem rede e estes downloads não seriam verificados pelo livro, por isso ficam desligados (-D WITH_IPP=OFF, -D BUILD_opencv_gapi=OFF, -D WITH_ADE=OFF; o init.cmake do G-API corre mesmo com o módulo desligado, daí o WITH_ADE). O IPP só acelera algumas funções; o resultado é o mesmo. O opencv_contrib (adicional opcional) não é preciso: o cv2.FaceDetectorYN está no módulo objdetect e usa o dnn, ambos do pacote base. Também ficam desligados de forma explícita CUDA, Qt, Java, documentação, exemplos e testes. O script substituído verifica no CMakeCache.txt que os módulos python3, dnn e objdetect entram na compilação, para falhar logo no cmake se o NumPy ou o Python não forem encontrados.

## NumPy antes do OpenCV; testes sem rede omitidos
_2026-11-06 14:36_

O NumPy é opcional no livro do opencv, mas sem ele não se gera o módulo cv2 para Python 3. Instala-se antes, com o meson_python e o pyproject-metadata que o livro pede. O NumPy é compilado com -Dallow-noblas=true, tal como no livro (sem BLAS/LAPACK otimizados, que aqui não fazem falta). Os testes do NumPy e do meson_python criam um venv e descarregam pacotes com pip, por isso ficam omitidos.

## libarchive instalada por ser requerida pelo opencv
_2026-11-06 14:36_

O livro lista a libarchive como requerida para o opencv (o OpenCV não a usa diretamente). Instala-se na mesma, por ser pequena e útil: dá bsdtar, bsdcpio e bsdunzip, e o livro cria a ligação /usr/bin/unzip.

## PyGObject e PyCairo para a interface gráfica do face-finder
_2026-11-06 14:36_

O PyGObject (com o PyCairo recomendado) dá ao Python acesso ao GTK 3 que já está instalado, e é isso que a face_finder_gui.py usa. Os testes do PyGObject precisam de uma sessão gráfica com D-Bus, por isso não correm (o livro não os põe em bloco próprio). O pytest não é instalado porque puxaria oito páginas (hatchling, pluggy, iniconfig...). Os testes do projeto usam unittest, que também corre com pytest se o utilizador o instalar mais tarde.

## Ristretto e libexif
_2026-11-06 14:36_

O Ristretto (com a libexif que o livro exige) é o visualizador de imagens do Xfce. O face-finder --abrir usa-o para mostrar as imagens marcadas. A documentação da libexif precisa do Doxygen, que não está instalado, por isso não é gerada.

## Modelo YuNet com URL fixada e SHA-256
_2026-11-06 14:36_

O detetor usa face_detection_yunet_2023mar.onnx (232 KB) do opencv_zoo, com licença MIT (models/face_detection_yunet/LICENSE, de Shiqi Yu). O ficheiro é descarregado no host pela função baixar, no commit f12e12798e83 (o que acrescentou esta versão), e verificado por SHA-256. Fica em /usr/share/face-finder e em ~/Projetos/face-finder/modelos. O programa funciona sem rede.

## Fotografias de licença livre do Wikimedia Commons
_2026-11-06 14:36_

Doze fotografias de pessoas com licença livre: domínio público (NASA, USDA, EPA e retrato do séc. XIX), CC BY 2.0/3.0 e CC BY-SA 2.5/3.0. São fotografias individuais e de grupo (de 6 a quase 100 pessoas), de frente e de perfil, a cores, a preto e branco e em sépia, de pessoas de idades e origens variadas. Não há crianças identificáveis: uma foto de grupo com crianças em primeiro plano foi trocada. Também não há contextos sensíveis. Usam-se as miniaturas fixas de 1280 px do Commons (upload.wikimedia.org/.../thumb/...), ou o original quando é mais pequeno, sem outras alterações. A lista (ficheiro, URL, SHA-256) está em scripts/apps/fotos-02.txt, e o autor, a licença e a origem de cada uma estão em CREDITOS.md, dentro do projeto. Um grande plano em que a boca ficava fora da imagem foi trocado porque o YuNet não o detetava. O README explica esta limitação.

## User-Agent próprio para os downloads do Wikimedia
_2026-11-06 14:36_

O upload.wikimedia.org responde 429 (Too Many Requests) ao User-Agent genérico do wget, por causa da política de User-Agent da Wikimedia. Com um nome descritivo, o mesmo URL funciona. As fotografias são descarregadas com a função baixar da etapa, à qual se dá um wgetrc temporário só com o user_agent (variável WGETRC). Cada download tem até cinco tentativas com pausas.

## Projeto em ~/Projetos/face-finder e programa em /usr/share/face-finder
_2026-11-06 14:36_

O comando /usr/bin/face-finder (e o face-finder-gui do atalho "Face Finder") corre a cópia em /usr/share/face-finder. Assim o utilizador pode alterar ou apagar o projeto em /home/ninja/Projetos/face-finder (dono ninja) sem estragar o comando. O projeto também é copiado para /etc/skel/Projetos/face-finder, para utilizadores novos. Inclui o código, o modelo, as fotografias, os testes, o README (com limitações e ética: deteção não é reconhecimento) e a configuração .vscode (settings.json e launch.json para correr e depurar com a extensão Python do VS Code, que se instala com instalar-aplicacoes). Se o PyGObject não estiver disponível, o atalho abre um terminal com a ajuda da linha de comandos. O lançador não é fixado na dock, porque o docklike.rc partilhado está a ser alterado pelo bloco 1; aparece no menu e no xfce4-appfinder.

## F8e — Drivers: headers do kernel para módulos externos
_2026-11-06 14:36_

A F7 apaga as fontes do kernel e o link /lib/modules/6.16.1/build, pelo que não era possível compilar módulos externos (NVIDIA, OpenRazer). O passo kernel-headers recompila o MESMO kernel 6.16.1 (tarball do LFS, sem patches) com a MESMA configuração (/boot/config-6.16.1; o passo falha se o make olddefconfig mudar alguma opção) só para obter o Module.symvers e os ficheiros gerados (include/generated, include/config, scripts/module.lds, objtool), e instala a árvore mínima de headers que o pacote linux-headers do Arch Linux instala (Makefiles de topo e de arch/x86, scripts, tools/objtool/objtool, include, arch/x86/include, alguns .h internos de drivers e todos os Kconfig) em /usr/src/linux-headers-6.16.1, com o link /lib/modules/6.16.1/build. Ficheiros .o/.cmd/.a e links partidos são apagados e os binários de scripts/ e tools/ despojados de símbolos. O bzImage e os módulos recompilados NÃO são instalados (ficam os da F7). Escolheu-se a compilação completa em vez de só "make modules_prepare" porque sem Module.symvers o modpost não confirma os símbolos importados pelos módulos externos (o nvidia-drm usa símbolos dos módulos drm/drm_kms_helper) — custa ~25 min de compilação uma única vez. O CONFIG_MODVERSIONS está desligado na configuração do Arch, por isso basta o vermagic coincidir: o passo compila um módulo de teste e compara o vermagic com o do nouveau instalado. Se a F7 for refeita (outra configuração), os passos kernel-headers e openrazer têm de ser refeitos.

## F8e — Vulkan: Mesa recompilado com anv, hasvk, radv e lavapipe
_2026-11-06 14:36_

Acrescentam-se Vulkan-Headers 1.4.321, Vulkan-Loader 1.4.321 e glslang 15.4.0 (páginas do BLFS; o SPIRV-Tools já veio da F8d) e reinstala-se o Mesa 25.1.8 com -D vulkan-drivers=intel,intel_hasvk,amd,swrast e -D vulkan-layers=device-select (escolha da GPU em portáteis híbridos). Os overrides do gen-scripts.py são por página e a página x/mesa já tem o replace da F8d (vulkan-drivers=""), por isso o passo mesa-vulkan é uma função: gera o script da página, troca só a opção vulkan-drivers numa cópia (gen/blfs/x/mesa-vulkan.sh) e corre-a com o run-blfs.sh, o mesmo tarball e o mesmo patch (verificados pelo MD5 do livro). Os drivers Gallium, as plataformas (só X11) e o resto ficam iguais aos da F8d. O lavapipe (Vulkan por CPU, sobre o llvmpipe) garante que as aplicações Vulkan arrancam em máquinas virtuais e sem GPU suportada, e permite testar o vulkaninfo no chroot. O NVK (Vulkan do nouveau) fica de fora: precisa de crates Rust descarregadas pelo meson (sem rede no chroot) e de bindgen/cbindgen. O teste do Vulkan-Loader (bloco 2) é omitido porque clona repositórios com git. Acrescenta-se ainda o vulkaninfo (Vulkan-Tools 1.4.321, não está no BLFS; GitHub, SHA-256 fixado), sem vkcube nem o ICD de teste.

## F8e — Aceleração de vídeo (VA-API/VDPAU) não incluída
_2026-11-06 14:36_

libva, intel-media-driver (com gmmlib) e libvdpau não são instalados: o intel-media-driver sozinho ocupa ~100 MB e demora a compilar, o VA-API do Mesa (radeonsi/nouveau) só serviria os codecs livres (VP9/AV1) porque a F8d excluiu os codecs com patentes, e nenhuma aplicação da ISO (sem leitor de vídeo nem navegador compilado) o usaria. Para o acrescentar mais tarde: páginas multimedia/libva e multimedia/intel-media-driver do BLFS e o Mesa com -D gallium-va=enabled.

## F8e — NVIDIA: driver oficial a pedido (instalar-driver-nvidia)
_2026-11-06 14:36_

Por omissão fica o nouveau (com o firmware GSP do linux-firmware). O driver oficial não pode ir dentro da ISO (licença) e é instalado no 1.º uso pelo comando /usr/bin/instalar-driver-nvidia: deteta as placas com lspci (classe 03xx, fabricante 10de), escolhe a série pelo id do dispositivo — 0x1e00 e acima (Turing e mais recentes) série 620.70.06 com os módulos abertos; 0x1340 a 0x1dff (Maxwell, Pascal, Volta) série 580.196.07, a última que as suporta, com o módulo proprietário; abaixo disso (Kepler e anteriores, séries legadas 470/390/340 que não compilam com o kernel 6.16) não instala e explica que fica o nouveau. Os intervalos vêm do supported-gpus.json da NVIDIA e, depois da descarga, a placa é confirmada na lista da própria versão. Descarrega a variante -no-compat32 (o sistema é só 64 bits) de download.nvidia.com com SHA-256 fixado no comando (os .sha256sum oficiais; versão atualizável com -v, caso em que o SHA-256 é lido do servidor), extrai-a, corre o nvidia-installer em modo silencioso (--kernel-module-type, --kernel-source-path=/lib/modules/$(uname -r)/build, --no-x-check, --skip-module-load, sem systemd, sem initramfs, sem fontes do módulo), põe o nouveau na lista negra (/etc/modprobe.d/nvidia-ianinja.conf, com nvidia-drm modeset=1 fbdev=1) e escreve um OutputClass do Xorg (MatchDriver nvidia-drm, PrimaryGPU). Em portáteis híbridos acrescenta um display-setup-script do LightDM (xrandr --setprovideroutputsource modesetting NVIDIA-0). Como o nouveau está em uso, o comando oferece-se para trocar já de driver: um script root desligado do terminal passa ao nível 3 do SysVinit (o LightDM está no inittab só no nível 5), solta a consola, descarrega o nouveau, carrega o nvidia-drm e volta ao nível 5; se falhar, repõe o nouveau e desativa a configuração do Xorg. Avisa que numa sessão live sem persistência a instalação vive na RAM (precisa de ~2,6 GB livres durante a instalação) e se perde ao desligar. O atalho "Instalar driver NVIDIA" (abre o xfce4-terminal) só aparece no menu quando há placa NVIDIA: uma regra udev (90-ianinja-nvidia.rules) copia-o para /usr/share/applications no arranque. Limitação: o instalador da NVIDIA substitui o libGL/libEGL do Mesa (compilado sem libglvnd, que não está no BLFS) pelos do libglvnd dele, pelo que depois da instalação o OpenGL das outras placas Intel/AMD do mesmo computador deixa de funcionar — daí o NVIDIA passar a placa principal.

## F8e — Razer: OpenRazer 3.12.4
_2026-11-06 14:36_

Do GitHub (versão fixada, SHA-256): os quatro módulos do kernel (razerkbd, razermouse, razerkraken, razeraccessory) compilados no chroot contra os headers do passo kernel-headers e instalados em /lib/modules/6.16.1/extra (comprimidos com zstd, como os da F7); as regras udev 99-razer.rules e o razer_mount; o grupo plugdev (criado; o ninja passa a pertencer-lhe, que o serviço exige); o serviço openrazer-daemon e a biblioteca Python openrazer (instalados como wheels, sem setup.py install). Dependências: dbus-python (página do BLFS), PyGObject e NumPy (bloco 2), e fora do BLFS pyudev 0.24.5 e daemonize 2.5.0 (wheels py3-none-any do PyPI, SHA-256 fixado) e setproctitle 1.3.8 (compilado da fonte). O serviço arranca na sessão gráfica (XDG autostart) só se houver um periférico Razer ligado, e também por ativação D-Bus (org.razer.service). Em vez do Polychromatic (GTK, muitas dependências) há o comando openrazer (lista dispositivos/bateria, brilho, cor fixa, efeitos espectro/respirar/onda/reativo/desligar).

## F8e — HyperX e outros periféricos gaming
_2026-11-06 14:36_

A configuração do kernel (Arch) já traz o que estes periféricos precisam: SND_USB_AUDIO (headsets e placas de som USB, incluindo os recetores sem fios HyperX Cloud), USB_HID/HID_GENERIC/HIDRAW embutidos, UHID, HID_LOGITECH(_HIDPP), HID_STEELSERIES, HID_CORSAIR, HID_PLAYSTATION, HID_NINTENDO, HID_STEAM, XPAD (comandos Xbox) e 130 drivers HID_* em módulo. Acrescenta-se o HeadsetControl 4.2.0 (bateria, sidetone, luzes, equalizador e desligar automático de headsets HyperX, SteelSeries, Logitech, Corsair, Roccat...) com o hidapi 0.15.0 (backends hidraw e libusb), ambos do GitHub com SHA-256 fixado; as regras udev geradas pelo próprio headsetcontrol usam TAG+="uaccess" e acrescenta-se GROUP="plugdev", MODE="0660" para funcionarem também sem o uaccess do logind. A biblioteca estática e os headers do HeadsetControl são apagados. O OpenRGB (luzes RGB de várias marcas) não é incluído: é Qt e a ISO não tem Qt; alternativa: AppImage oficial do OpenRGB descarregado pelo utilizador (corre sem instalação) ou o comando openrazer para Razer.

## F8e — Bluetooth: BlueZ 5.83 e Blueman 2.4.6
_2026-11-06 14:36_

Agora que há D-Bus e GLib, instala-se o BlueZ (página do BLFS; o libical vem antes, sem Vala: -D ICAL_GLIB_VAPI=false, sem documentação) com o bootscript bluetooth do blfs-bootscripts (bloco 8 do livro substituído pelo passo bluez-bootscript; documentação .txt omitida) e o Blueman (fora do BLFS; GitHub com SHA-256 fixado), gestor gráfico GTK3 com applet no painel, sem PulseAudio nem plugins de gestores de ficheiros inexistentes, com o "Enviar para" do Thunar. Custo: ~10 MB (BlueZ + libical) e ~5 MB (Blueman, Python). Teclados, ratos e comandos Bluetooth funcionam; os headsets Bluetooth emparelham mas o áudio (A2DP/HFP) precisa de um servidor de som (PulseAudio ou PipeWire), que não está na ISO.

## F8e — xfce4-screenshooter e teclas Print
_2026-11-06 14:36_

O xfce4-screenshooter 1.11.3 não está no BLFS 12.4: vem de archive.xfce.org (SHA-256 fixado), compilado com meson, só X11 (sem gtk-layer-shell para Wayland), sem documentação. O libxfce4ui já define Print e Shift+Print no ficheiro de sistema /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml; esse ficheiro substitui a lista inteira, por isso é editado no sítio (python3 xml.etree, como o atalho Super+Espaço da F8d): Print passa a xfce4-screenshooter -f (ecrã inteiro) e Shift+Print a xfce4-screenshooter -r (região); Alt+Print (janela) fica como estava.

## F8e — info-hardware
_2026-11-06 14:36_

Comando /usr/bin/info-hardware e atalho "Informação do hardware": placas gráficas com o driver do kernel em uso (lspci -k) e o estado do driver NVIDIA, OpenGL (glxinfo -B), Vulkan (vulkaninfo --summary e ICDs instalados), som (incluindo áudio USB), periféricos de marcas gaming ligados por USB (Razer, HyperX, Logitech, SteelSeries, Corsair...) com os drivers associados, bateria pelo headsetcontrol, estado do OpenRazer, Bluetooth e Wi-Fi; com -c lista todos os dispositivos PCI e USB.

## Patchelf antes do dbus-python
_2026-11-06 14:36_

O livro dá o Patchelf-0.18.0 como dependência "recomendada (runtime)" do meson_python, mas o meson_python 0.18 chama sempre `patchelf --print-rpath` quando o projeto tem bibliotecas internas (caso do dbus-python), e falha com "No such file or directory: patchelf". Acrescentou-se o passo `patchelf` (página general/patchelf, sem desvios) imediatamente antes do dbus-python.

## Ambiente de programação: o que entra na ISO e o que fica a pedido
_2026-11-06 14:36_

Na ISO já existiam GCC 15 (C/C++), Make, CMake 4.1, Meson, Ninja, Git, Perl, LLVM/Clang 20, Python 3.13.7 com pip 25.2 e ensurepip (o LFS 12.4 instala-os: /usr/bin/pip3, /usr/lib/python3.13/ensurepip/_bundled/pip-25.2-py3-none-any.whl, venv; sem EXTERNALLY-MANAGED, por isso "pip install" sem sudo cai sozinho em --user). O bloco 4 acrescenta: o módulo sqlite3 do Python, os módulos requests e pytest (com as dependências do livro), o six, o Node.js 22.18.0 com npm, o GDB 16.3 e o Valgrind 3.25.1, e o comando /usr/bin/instalar-ferramentas. Ficam a pedido (descarregados dos sites oficiais no 1.º uso, não vão na ISO): Rust (rustup), Go e Java (OpenJDK Temurin LTS). O BLFS não tem Go, jq, ripgrep, htop nem strace; o ripgrep vem com o Codex do instalar-aplicacoes (bloco 1) e o Claude Code traz o seu.

## Python: só o módulo _sqlite3, sem recompilar o interpretador
_2026-11-06 14:36_

O Python do LFS (Cap. 8) foi compilado antes do SQLite (F8d): o log 08-Python.log mostra "checking for stdlib extension module _sqlite3... disabled", e falta lib-dynload/_sqlite3.cpython-313-x86_64-linux-gnu.so. Todos os outros módulos de C existem (_ssl, _ctypes, _bz2, _lzma, _curses, _dbm/_gdbm, _uuid, readline); _tkinter falta e fica a faltar (sem Tk). Em vez de reinstalar o Python inteiro pela página general/python3 (que repetiria o PGO do --enable-optimizations, ~1,5 SBU + perfil, e substituiria a biblioteca padrão e o pip por ficheiros iguais), compila-se o mesmo Python-3.13.7.tar.xz (o tarball já está em /sources, MD5 do livro igual ao do LFS) com as opções do LFS menos --enable-optimizations, confirma-se no Makefile que o configure encontrou o SQLite (MODULE__SQLITE3_STATE=yes) e instala-se só Modules/_sqlite3<EXT_SUFFIX> em /usr/lib/python3.13/lib-dynload. A mesma versão e o mesmo configure dão a mesma ABI; o PGO só afeta o interpretador. Omitidos: testes (+2,8 SBU) e documentação HTML (download adicional).

## Certificados para pip, venv e requests
_2026-11-06 14:36_

O make-ca (F8) criou /etc/ssl/certs e /etc/pki/tls/certs/ca-bundle.crt, e o /etc/profile.d/pythoncerts.sh exporta _PIP_STANDALONE_CERT para esse ficheiro. O pip 25.2 usa o truststore (a loja do OpenSSL do sistema) e, nos venv, o certifi incluído no próprio pip, por isso funciona com ou sem a variável. O requests é instalado com o patch recomendado requests-use_system_certs-1 (--extra), que troca o certifi (não instalado) por /etc/pki/tls/certs/ca-bundle.crt ou por $_PIP_STANDALONE_CERT.

## Módulos Python escolhidos
_2026-11-06 14:36_

Poucos e leves (menos de 0,1 SBU e alguns MB cada): requests (HTTP em scripts) e pytest (testes), e o six (dependência de execução recomendada do GDB, para os scripts Python de depuração das bibliotecas). As dependências seguem o livro: setuptools_scm, charset-normalizer, idna, editables, pathspec, pluggy, trove-classifiers, hatchling, hatch-vcs, urllib3, iniconfig. O hatchling e o hatch-vcs servem também de backend para quem compilar outros módulos sem rede. Tudo o resto instala-se com pip num venv (python3 -m venv .venv). Omitidos todos os blocos de testes destas páginas: fazem pip install de módulos de teste a partir da Internet (o chroot não tem rede); o do setuptools_scm precisaria ainda do pytest, instalado depois.

## Node.js com as bibliotecas internas
_2026-11-06 14:36_

A página do Node.js recomenda Brotli, c-ares, ICU, libuv e nghttp2 do sistema. O ICU já existe (F8d) e usa-se (--with-intl=system-icu, dados completos, pt-PT incluído), tal como o OpenSSL e o zlib; Brotli, c-ares, libuv e nghttp2 são compilados a partir das cópias que vêm no próprio tarball do Node (as versões que ele testa), em vez de quatro páginas do BLFS que nada mais usa. Compila-se com make -j8 em vez de -j12: alguns ficheiros do V8 precisam de mais de 1 GB de RAM cada e o WSL tem 11 GB (o mesmo cuidado do LLVM). O make install põe node, npm, npx e corepack em /usr/bin (npm 10 interno, porque não há outro). O agente 01 confirmou que o Claude Code e o Codex não precisam do Node; ele entra só para programar.

## npm install -g sem sudo
_2026-11-06 14:36_

O /etc/profile.d/programacao.sh exporta, para utilizadores com UID diferente de 0, NPM_CONFIG_PREFIX=$HOME/.npm-global e põe $HOME/.npm-global/bin no PATH (é a solução da documentação do npm para o erro EACCES, aqui para todos os utilizadores e sem editar o ~/.npmrc). O root continua com o prefixo /usr (sudo npm install -g instala para todos). Escolheu-se o profile.d em vez do /usr/etc/npmrc (o globalconfig de um Node em /usr) porque esse aplicaria o ~/.npm-global também ao root. O profile.d é lido pelas consolas e pela sessão gráfica (o lightdm-session corre bash --login), e os terminais herdam o ambiente. O mesmo ficheiro põe no PATH, mesmo antes de existirem (para funcionarem logo após instalar, sem nova sessão), ~/.local/bin (pip --user, pipx, Claude Code; o bloco de PATH que o instalar-aplicacoes escreve no ~/.bashrc deteta que já lá está), ~/.cargo/bin (Rust) e ~/go/bin (go install), e define JAVA_HOME=/opt/jdk se o Java estiver instalado.

## GDB e Valgrind
_2026-11-06 14:36_

GDB com Python (--with-python) e readline/zlib do sistema; omitidos a documentação Doxygen (blocos 2 e 5, Doxygen não instalado) e os testes (bloco 3: o livro não os recomenda, 3 a 15 SBU com dezenas de falhas). Valgrind como no livro; omitido o bloco 2, que só prepara a suite de testes (make regtest não corre).

## Rust a pedido com o rustup (o /opt/rustc continua fora da ISO)
_2026-11-06 14:36_

O Rust 1.89 da F8d (/opt/rustc, 266 MB, ~80 MB comprimido) é excluído do rootfs.squashfs pela F9 e assim fica: em vez de uma versão fixa sem rustup, o comando "instalar-ferramentas rust" descarrega o rustup-init oficial (static.rust-lang.org, SHA-256 do ficheiro .sha256 publicado ao lado) e instala, como o utilizador que chamou o comando (nunca como root, como faz o instalar-aplicacoes com o Claude Code), o toolchain stable com o perfil minimal + rustfmt + clippy (~600 MB a menos sem a documentação local; rustup component add rust-docs a junta) em ~/.cargo e ~/.rustup, com --no-modify-path (o PATH vem do programacao.sh). Repetir o comando faz rustup self update e rustup update stable. Os cargo-capi/cbuild/cinstall/ctest do cargo-c em /usr/bin passam a funcionar como subcomandos desse cargo. Se o coordenador preferir levar o rustc na ISO, basta tirar opt/rustc da lista -e do mksquashfs na F9 (+~80 MB na ISO).

## Go e Java a pedido
_2026-11-06 14:36_

Go: versão estável mais recente de https://go.dev/dl/?mode=json (arquivo linux-amd64 e o seu SHA-256), extraído em streaming para /usr/local/go, com links go e gofmt em /usr/local/bin (já está no PATH). Java: a LTS mais recente segundo https://api.adoptium.net/v3/info/available_releases (25 em novembro de 2026), JDK HotSpot linux-x64 do Eclipse Temurin pela API da Adoptium (link e SHA-256), extraído para /opt/jdk, com links de todos os comandos de /opt/jdk/bin em /usr/local/bin e JAVA_HOME nas sessões novas. Ambos verificados pelo SHA-256 antes de substituírem a versão anterior (troca quase atómica do diretório); repetir o comando atualiza.

## O comando instalar-ferramentas
_2026-11-06 14:36_

Mesmo estilo e opções do instalar-aplicacoes do bloco 1 (sem o reutilizar nem editar): menu sem argumentos, instalar-ferramentas rust|go|java|tudo, -l estado (mostra também o que já vem no sistema), -f forçar, -s sem perguntas, --janela para o atalho; verifica a Internet e o espaço livre (Rust ~1,1 GB, Go ~0,6 GB, Java ~0,7 GB) e avisa numa sessão live sem persistência (sugere ia-criar-persistencia). Estado em /var/lib/instalar-ferramentas. Atalho "Instalar ferramentas de programação" no menu Desenvolvimento (ícone applications-development do WhiteSur), que abre o xfce4-terminal; não foi fixado na dock (ficheiro do bloco 1). Testado no host com IA_FERR_RAIZ: Go 1.27.3 e Temurin 25.0.5+8 descarregados, verificados, extraídos e executados; a 2.ª execução detetou a mesma versão; o rustup-init foi descarregado e verificado, e as opções confirmadas com rustup-init --help.

## Verificação no chroot
_2026-11-06 14:36_

O passo prog-verificar corre scripts/apps/programacao/verificar-programacao.sh no chroot: importa sqlite3, ssl, venv, requests, pytest e six; confirma a loja de certificados; node com OpenSSL e ICU pt-PT; npm com prefixo /usr para o root; gdb com Python; valgrind sobre /usr/bin/true. Depois, como UID 1000 (chroot --userspec, sem PAM) com uma pasta pessoal temporária, lê o /etc/profile e confirma o prefixo ~/.npm-global, instala com npm install -g --offline um pacote local e corre o seu comando, cria um venv com pip e sqlite3 e corre instalar-ferramentas -l. Nada fica em /home/ninja.

## Pygments antes do pytest
_2026-11-06 14:36_

O pytest 8.4 exige pygments>=2.7.2, que o livro só refere na lista de dependências e que não estava instalado (pip falhava com "No matching distribution found for pygments"). Acrescentou-se o passo `pygments` (página general/python-modules, secção Pygments-2.19.2) imediatamente antes do pytest, sem os testes (bloco 3: precisam de rede para o wcag-contrast-ratio).

## Loja de aplicações = Flatpak + Flathub, com uma Loja gráfica própria
_2026-11-06 14:36_

Decisão do utilizador: as aplicações de terceiros instalam-se com o Flatpak a partir do Flathub, através de uma Loja gráfica própria ao estilo de uma loja de aplicações (/usr/bin/loja, programa Python 3 + PyGObject/GTK 3 em /usr/share/loja, CSS próprio coerente com o WhiteSur-Light). Não há GNOME Software/KDE Discover (pediriam GTK4/libadwaita ou Qt). A Loja instala em modo --user (~/.local/share/flatpak, sem sudo nem polkit), mostra Descobrir (destaques: Firefox, Spotify, Discord, VLC, GIMP, OBS Studio, Steam, LibreOffice, Telegram, Blender; populares; categorias Internet, Música, Jogos, Gráficos, Programação, Escritório), pesquisa, página de cada aplicação (ícone, capturas, tamanhos, licença, descrição; Instalar/Abrir/Remover com barra de progresso), Instaladas, Atualizações e Aplicações oficiais (chama instalar-aplicacoes --janela vscode|chrome|claude|codex num xfce4-terminal e lê o estado com instalar-aplicacoes -l). Atalho "Loja" no menu (Sistema) e fixado na dock, antes de "Instalar aplicações".

## API do Flathub e cache
_2026-11-06 14:36_

Usa a API pública https://flathub.org/api/v2 (confirmada em 2026-11): POST /search, GET /appstream/<id>, /summary/<id> (tamanhos), /collection/popular, /collection/category/<cat> e /collection/category/AudioVideo/subcategories?subcategory=Audio (Música). Respostas guardadas 6 h em ~/.cache/loja/api (sem rede usa a cache antiga) e ícones/capturas em ~/.cache/loja/imagens. Só biblioteca padrão do Python (urllib, certificados do make-ca em /etc/pki/tls/certs/ca-bundle.crt). Os textos das aplicações vêm do Flathub (quase sempre em inglês); a interface é em português.

## Progresso das instalações
_2026-11-06 14:36_

O flatpak só escreve o progresso quando a saída é um terminal (com --noninteractive e um pipe escreve apenas "Installing ..."). A Loja corre flatpak install --user -y flathub <id> (e uninstall/update) num pseudo-terminal (módulo pty), com LC_ALL=C.UTF-8, e lê "Installing 2/3… ████ 45%" para a barra (passo e percentagem). Uma operação de cada vez; botão Cancelar (SIGINT). Testado com a saída real do flatpak.

## Sessão live: aviso e persistência
_2026-11-06 14:36_

Sem disco IANINJA-DADOS (/run/live/iso montado e nem /mnt/dados nem /run/live/dados) a Loja mostra uma faixa de aviso e, antes da 1.ª instalação, um diálogo: as aplicações ficam na RAM (camada tmpfs do OverlayFS) e perdem-se ao desligar; explica como usar sudo ia-criar-persistencia /dev/<partição>. Como as instalações são --user, em ~/.local/share/flatpak, ficam no disco de dados quando há persistência. Antes de instalar compara o tamanho instalado (API /summary, +20 %) com o espaço livre e pede confirmação se faltar.

## Pacotes do BLFS acrescentados
_2026-11-06 14:36_

libseccomp, bubblewrap, xdg-dbus-proxy, Fuse 3, libassuan, libksba, npth, pinentry, GnuPG, GPGME, libxmlb, AppStream, JSON-GLib, pyparsing (o meson do Flatpak exige-o), gstreamer + gst-plugins-base e PipeWire (o xdg-desktop-portal 1.20 exige gstreamer-pbutils e libpipewire para compilar; o daemon do PipeWire não arranca: não há session manager), gsettings-desktop-schemas, xdg-desktop-portal e xdg-desktop-portal-gtk. Cortados: OpenLDAP/Cyrus SASL/LMDB (GnuPG com --disable-ldap; só é preciso verificar assinaturas), gnome-desktop (xdg-desktop-portal-gtk com -D wallpaper=disabled: arrastaria o GTK4 e o GStreamer completo), xdg-desktop-portal-gnome/lxqt, Wireplumber, BlueZ, GeoClue, dconf, malcontent. Documentação desligada onde precisaria de Doxygen, texlive, gi-docgen ou DocBook (AppStream sem o subdiretório docs/, que exige docbook-xsl mesmo com docs=false; JSON-GLib sem man; manuais em PDF omitidos). Testes que precisam de rede (pip) ou de dbusmock/umockdev omitidos. PipeWire com -D systemd=disabled (o libsystemd.pc do elogind não tem o sd-journal usado pelo plugin do journal). Os dois portais apagam só as suas unidades systemd (o livro apaga /usr/lib/systemd inteiro, onde está o xfconfd.service do Xfce).

## OSTree e Flatpak compilados de fonte
_2026-11-06 14:36_

Não estão no BLFS 12.4. libostree 2026.6 (https://github.com/ostreedev/ostree/releases, SHA-256 164b8226aea6a0e6601036de02a5e3b62307bae25890ed557fb4e19020bd5974): HTTP com libcurl (sem libsoup), GPG com gpgme, checksums OpenSSL, rofiles-fuse; sem systemd, SELinux, Avahi, composefs, gtk-doc e manual; apaga-se o /etc/grub.d/15_ostree (o sistema não arranca de implantações OSTree). Flatpak 1.18.4, série estável (https://github.com/flatpak/flatpak/releases, SHA-256 b899a7a00c48d2c626cb8ec33fe556720b376c25805d7222430c0fdca4c6ac8d, igual ao .sha256sum do release): bwrap e xdg-dbus-proxy do sistema, instalação do sistema em /var/lib/flatpak, system helper (polkit; grupo privilegiado wheel) com o utilizador de sistema "flatpak" criado à mão (não há systemd-sysusers), seccomp, zstd, GObject Introspection; sem systemd, dconf, malcontent, SELinux, documentação e testes; unidades systemd apagadas (os serviços D-Bus funcionam por ativação). /etc/profile.d/flatpak.sh (do próprio Flatpak) acrescenta ~/.local/share/flatpak/exports/share e /var/lib/flatpak/exports/share ao XDG_DATA_DIRS; o lightdm-session é bash --login, por isso as aplicações instaladas aparecem no menu do Xfce (as primeiras podem pedir sair e voltar a entrar).

## Remote Flathub
_2026-11-06 14:36_

flathub.flatpakrepo descarregado de https://dl.flathub.org/repo/flathub.flatpakrepo e verificado por SHA-256 (3371dd25...a03a; se o Flathub o mudar é preciso rever a soma em funcoes-05.sh), guardado em /usr/share/loja/flathub.flatpakrepo. flatpak remote-add --system --if-not-exists flathub na construção, e o mesmo --user para o ninja (como ninja, no chroot); a Loja repete o remote-add --user no arranque (ficheiro local, sem rede) para utilizadores novos.

## Aspeto das aplicações Flatpak
_2026-11-06 14:36_

O /usr do sistema não é visível dentro da sandbox e o Flathub não tem a extensão org.gtk.Gtk3theme.WhiteSur-Light. Por isso copia-se o WhiteSur-Light (só gtk-3.0 e index.theme, ~1 MB) para ~/.themes do ninja e de /etc/skel, e um override global do utilizador (~/.local/share/flatpak/overrides/global: filesystems=~/.themes:ro) deixa as aplicações GTK 3 lê-lo; o nome do tema chega-lhes pelo XSETTINGS do Xfce. Um gschema override põe org.gnome.desktop.interface (gtk-theme, icon-theme, cursor-theme, font-name, color-scheme=prefer-light) com os valores do Xfce, que o portal Settings do xdg-desktop-portal-gtk mostra às aplicações. O cursor WhiteSur e os ícones não são copiados (as aplicações trazem os seus). Aplicações GTK4/libadwaita e Qt usam o aspeto próprio. Portais: /usr/share/xdg-desktop-portal/xfce-portals.conf com default=gtk (o xdg-desktop-portal >= 1.18 exige-o; o gtk.portal só declara UseIn=gnome).

## Requisitos do kernel
_2026-11-06 14:36_

O bwrap (sem setuid) usa namespaces de utilizador: o kernel da F7 tem CONFIG_USER_NS=y, PID/NET/IPC/UTS_NS, SECCOMP, FUSE_FS e OVERLAY_FS (confirmado em /boot/config-6.16.1). O fusermount3 fica setuid (livro) para o portal de documentos.

## xdg-dbus-proxy sem página de manual
_2026-11-06 14:36_

Com a opção `man` em "auto", o meson do xdg-dbus-proxy encontra o xsltproc e tenta gerar a página de manual a partir do docbook.xsl, que não está instalado; o xsltproc vai então à rede (http://docbook.sourceforge.net/...) e o build falha. O bloco 1 passa a usar `-D man=disabled` (scripts/replace/blfs-general-xdg-dbus-proxy.1.sh), como nos outros pacotes sem DocBook.

## Testes F11: aplicações da F8e
_2026-11-06 14:40_

Com a F8e (aplicações, programação, drivers, face-finder e Loja) os modos BIOS e UEFI passam de 13 para 18 critérios, em 5 grupos, todos sem rede obrigatória e depois do critério 14 (antes da IA): 15 'Instaladores' (como ninja: instalar-aplicacoes -l e instalar-ferramentas -l correm; /usr/local/bin/instalar-tudo-click.sh executável e com sintaxe válida; /etc/xdg/autostart/instalar-tudo-default.desktop com Exec= para ele); 16 'Programação' (node --version, npm --version, python3 -I -c 'import sqlite3, requests, numpy, cv2', gdb --version, e o prefixo global do npm do ninja é ~/.npm-global); 17 'Flatpak' (flatpak --version, bwrap --version, flathub em flatpak remotes --system, uma sandbox bwrap --unshare-all como ninja — namespaces de utilizador do kernel arrancado, que o chroot da F8e não pôde testar — e loja --verificar como ninja); 18 'Drivers' (vulkaninfo --summary mostra o lavapipe/llvmpipe, a única ICD Vulkan que funciona no QEMU sem GPU; info-hardware corre; instalar-driver-nvidia -l sai com 0 e diz 'nenhuma' sem erros; bluetoothctl --version; headsetcontrol --help; xfce4-screenshooter --version, ou --help se não houver ecrã); 19 'face-finder' (corre em /usr/share/face-finder/fotos, resultados.json com total_rostos >= 1 e nenhuma imagem ilegível, relatorio.html criado). Cada verificação corre com timeout (120 s com KVM, 900 s sem KVM) e a saída fica no log; um comando em falta dá FAIL do grupo sem prender o teste. A VM já tem rede NAT do QEMU (-nic user, critério 5): o acesso ao Flathub (wget --spider de dl.flathub.org) é só INFO.

## initramfs: mensagens no ecrã e espera de 60 s
_2026-11-11 18:44_

Num PC real o arranque ficava com o ecrã preto: com 'console=tty0 console=ttyS0,115200' a última console= (ttyS0) é o /dev/console, e todas as mensagens do /init (incluindo a FALHA NO ARRANQUE LIVE e a shell de emergência) e dos bootscripts iam para a porta série, invisíveis. A F10 passou a pôr 'console=ttyS0,115200 console=tty0' (o ecrã é o /dev/console). Para os testes F11, que leem a série, o /init (scripts/live-init.sh) escreve agora cada mensagem (função diz) no /dev/console e também nas outras consolas da linha do kernel (lidas de /proc/cmdline; cada uma é preparada com 'stty -F <dev> clocal', que abre com O_NONBLOCK — uma porta série que não exista no PC falha logo e é ignorada, e nunca se fica à espera da portadora; por isso o stty entrou no initramfs). A emergência mostra o motivo, a saída do blkid e sugestões em pt-PT e abre o bash no /dev/console (o ecrã); se a shell sair abre-se outra, em vez de o PID 1 sair (kernel panic). A espera pelo volume IANINJAPELAGESTAO passou de 30 s para 60 s (pens USB lentas, hubs, controladores USB 3 que demoram), com uma mensagem de progresso a cada 5 s. Os drivers de armazenamento não precisam de ir no initramfs: xhci/ehci/ohci/uhci (PCI), usb-storage, uas, sd_mod, sr_mod, nvme, ahci, mmc/sdhci-pci, virtio-blk, loop, isofs, squashfs (xz), overlay, ext4 e vfat estão todos embutidos (=y) no kernel 6.16.1 (confirmado em /boot/config-6.16.1).

## Interface gráfica vigiada (ianinja-dm)
_2026-11-11 18:44_

O inittab passou de 'dm:5:respawn:/etc/rc.d/init.d/xdm' para 'dm:5:respawn:/usr/sbin/ianinja-dm' (scripts/sistema/ianinja-dm, instalado pela F9). Lê o mesmo /etc/sysconfig/xdm e lança o LightDM como processo filho (o pidof lightdm continua a funcionar). Sem logind o LightDM dá ao seat0 exit-on-failure=true e sai quando o X ou o greeter não arrancam; antes, o init relançava-o em ciclo e o ecrã podia ficar preto no vt7. Agora cada saída antes de existirem um servidor X e um greeter (ou uma sessão Xfce) conta como falha (também um 'Fatal server error' no registo do X sem o LightDM sair em 20 s); à 3.ª falha no mesmo arranque o ianinja-dm faz chvt 1, escreve na tty1 um aviso em pt-PT a sugerir a entrada do GRUB 'modo gráfico de compatibilidade', reinicia o agetty da tty1 (--noclear: o pedido de login aparece por baixo do aviso) e fica a dormir para o init não voltar a lançar o LightDM. 'sudo ianinja-dm repor' apaga as falhas e volta a tentar. Registo em /var/log/ianinja-dm.log; estado em /run/ianinja-dm (só dura um arranque). Não há limite de tempo para o X aparecer (em máquinas lentas demora), para nunca matar um arranque lento mas válido. O /etc/rc.d/init.d/xdm do BLFS continua instalado (e verificado na imagem), mas já não é usado pelo inittab.

## GRUB: ecrã como consola principal (tty0 por último)
_2026-11-11 18:44_

Em todas as entradas a ordem passou a 'console=ttyS0,115200 console=tty0'. O kernel escreve as suas mensagens em todas as consolas, mas o /dev/console (stdin/stdout do /init do initramfs, dos bootscripts e da shell de emergência) é a ÚLTIMA console=; antes era a ttyS0, e num PC real qualquer falha do initramfs ou mensagem dos bootscripts ia para a porta série e o ecrã ficava preto. Agora vai para o ecrã; o /init escreve também na ttyS0 (função diz do scripts/live-init.sh), por isso os testes F11 continuam a ver 'persistência: ...', 'raiz overlay pronta' e 'FALHA NO ARRANQUE LIVE' na série; o banner e o login: da série vêm do agetty da ttyS0 (inittab), que não depende do /dev/console. O 'quiet' fica na entrada principal: só esconde as mensagens informativas do kernel (os erros do kernel continuam a aparecer); as mensagens do /init (a procurar o volume, progresso a cada 5 s, persistência, raiz pronta) e os [ OK ] dos bootscripts do LFS aparecem sempre no ecrã, por isso o arranque mostra progresso em vez de um ecrã preto, sem centenas de linhas do kernel; para ver tudo há as entradas sem quiet (compatibilidade e modo seguro).

## GRUB: modo gráfico de compatibilidade (nomodeset)
_2026-11-11 18:44_

Nova entrada (a 2.ª) 'ianinjapelagestao 12.4 (Live - modo gráfico de compatibilidade)', para PCs em que o driver DRM nativo da placa (nouveau em NVIDIA recentes com GSP, i915/xe, amdgpu sem firmware certo...) deixa o ecrã preto: 'nomodeset' (sem ' 3', arranca com interface gráfica e sem quiet). Com nomodeset o kernel 6.16 não carrega os drivers DRM nativos (incluindo o nouveau, por isso não é preciso nouveau.modeset=0) mas mantém os de firmware: CONFIG_SYSFB_SIMPLEFB=y faz do framebuffer do firmware um simple-framebuffer e CONFIG_DRM_SIMPLEDRM=y dá-lhe um /dev/dri/card0, onde o Xorg com o driver modesetting funciona (sem aceleração; o Mesa usa o llvmpipe). CONFIG_DRM_EFIDRM e CONFIG_DRM_VESADRM (novos no 6.16) não estão ligados; não fazem falta porque o simpledrm cobre os formatos comuns (XRGB8888, RGB565, RGB888) do GOP e do VESA, e ligá-los obrigaria a recompilar o kernel (F7) e tudo o que depende dele — fica como melhoria possível; se o formato não for suportado o kernel usa o efifb/vesafb (=y) e há consola de texto e o aviso do ianinja-dm. No UEFI o GOP já é um framebuffer (gfxpayload=keep); no BIOS o GRUB arrancaria o kernel em modo de texto VGA (sem framebuffer, o Xorg falhava — era por isso que o modo seguro tinha ' 3'), por isso a entrada faz insmod all_video e set gfxpayload=1024x768x32,1024x768,auto, e o kernel recebe um modo VESA linear. O título não contém '(Live)', que os testes F11 procuram para a entrada 0.

## initramfs: ISO9660 no disco inteiro (pen USB gravada em modo imagem)
_2026-11-11 20:02_

Causa real do arranque falhado num PC (foto do ecrã): numa pen USB gravada com a ISO em modo imagem o blkid via /dev/sda com a tabela de partições híbrida do grub-mkrescue (sda1/sda4 'Gap0/Gap1', sda2 EFI em FAT, sda3 HFS+ com LABEL=IANINJAPELAGESTAO) e não listava /dev/sda com o rótulo; o /init só tentava montar sda3 (HFS+, que o kernel nem suporta) e falhava ao fim de 60 s. O ISO9660 com live/rootfs.squashfs está no disco inteiro. O /init (scripts/live-init.sh, função procurar) tenta agora, em cada ciclo de 0,5 s: 1) cada dispositivo com o rótulo (blkid sem cache, -c /dev/null); 2) se não tiver live/rootfs.squashfs, o disco-pai dessa partição (por /sys/class/block/<part>/.., ex. sda3 -> sda, nvme0n1p3 -> nvme0n1, mmcblk0p2 -> mmcblk0) montado com -t iso9660; 3) por fim todos os discos inteiros (sem ficheiro partition no sysfs, incluindo sr*; excluindo loop, ram, zram, dm e md) com -t iso9660. Tudo só-leitura; um disco que não seja ISO9660 (ex. o NVMe com o Windows) falha logo a montagem e não é alterado. Os drivers precisos estão embutidos no kernel (ISO9660_FS, USB_XHCI_PCI, USB_EHCI_PCI, USB_OHCI_HCD, USB_UHCI_HCD, USB_STORAGE, USB_UAS, BLK_DEV_SD, BLK_DEV_SR, BLK_DEV_NVME, SATA_AHCI, MMC_BLOCK, VIRTIO_BLK, SQUASHFS_XZ, OVERLAY_FS = y), o initramfs não precisa de módulos. Não se mudou o grub-mkrescue para não gerar a partição HFS+: não tem opção para isso e mexer na estrutura híbrida arriscava o arranque BIOS/UEFI que já funciona; a correção no /init cobre todos os casos. A F11 passou a testar a ISO como pen USB e como disco (teste-pen.exp).

## ianinja-dm: níveis de recurso do Xorg antes de desistir
_2026-11-11 20:02_

Pedido: se o Xorg/LightDM falhar, passar sozinho para um modo compatível antes de cair na consola. Com o driver nativo da placa já carregado não é possível voltar ao framebuffer do firmware sem reiniciar (o driver DRM nativo remove o simpledrm ao carregar), por isso o ianinja-dm sobe de nível com configurações do Xorg cada vez mais simples, num ficheiro só seu (/etc/X11/xorg.conf.d/90-ianinja-recurso.conf, apagado no início de cada arranque e com 'ianinja-dm repor'): nível 0 automático (2 tentativas); nível 1 driver modesetting com AccelMethod none (sem glamor/OpenGL — a falha mais comum em placas recentes, ex. NVIDIA com nouveau sem aceleração, ou Mesa sem suporte para a GPU); nível 2+ uma placa de cada vez (Option kmsdev /dev/dri/cardN, primeiro as do firmware — simpledrm, se o driver nativo não chegou a tomar conta — depois as outras; útil em portáteis híbridos), só quando há mais do que uma placa. Antes de lançar o LightDM verifica-se que existe pelo menos uma placa com driver KMS e saídas (/sys/class/drm/cardN com cardN-*; o vgem não conta); se não existir nenhuma (ex. amdgpu que removeu o framebuffer do firmware e depois falhou) desiste logo. Se todos os níveis falharem: consola tty1 com o aviso a sugerir a entrada 'modo gráfico de compatibilidade' do GRUB (nomodeset: aí o simpledrm fica com a imagem do firmware e o Xorg modesetting funciona). 'ianinja-dm estado' mostra nível, placas e registo. Para testes: ianinja-dm.simular-falha=N na linha do kernel faz as N primeiras tentativas usarem um driver do Xorg inexistente (falha real do X). Não foi preciso o xf86-video-fbdev/vesa: o modesetting aceita o simpledrm. NVIDIA recentes: a entrada de compatibilidade é o caminho para chegar ao ambiente gráfico e correr instalar-driver-nvidia (o driver oficial fica ativo depois de reiniciar na entrada normal, o que exige persistência; o nouveau fica na lista negra).

## Testes F11: arranque como pen USB e como disco
_2026-11-11 20:07_

Num PC real com a ISO gravada numa pen USB (modo imagem/dd) o initramfs falhava com 'volume com LABEL=IANINJAPELAGESTAO ... não encontrado': o blkid mostrava o rótulo só na partição HFS+ (sda3) que o grub-mkrescue cria na tabela de partições híbrida, e o ISO9660 com live/rootfs.squashfs está no disco inteiro (/dev/sda), que o blkid não lista com o rótulo por ver a tabela de partições. No QEMU e no VirtualBox a ISO entrava sempre como CD (/dev/sr0, sem partições), por isso nenhum teste o apanhou. Novo grupo de testes (scripts/teste-pen.exp), 4 modos: pen-bios e pen-uefi (-device qemu-xhci -device usb-storage,removable=on,bootindex=0, a ISO como disco só-leitura: /dev/sda com sda1..sda4, como numa pen) e disco-bios e disco-uefi (virtio-blk, /dev/vda). Cada modo tem 4 critérios: o GRUB mostra o menu; o initramfs encontra o volume no DISCO INTEIRO (/dev/sdX ou /dev/vdX, não numa partição) e monta a raiz; login root na série; Xorg e lightdm-gtk-greeter a correr (até 180 s com KVM). A ISO é usada diretamente com readonly=on (não é preciso uma cópia).

## F8e — VTE recompilada com GnuTLS
_2026-11-12 19:24_

Na F8d a VTE 0.80.3 foi compilada com -D gnutls=false porque o GnuTLS só é instalado na F8e (passos nettle e gnutls). Sem GnuTLS a VTE escreve, a vermelho, no início de cada terminal (xfce4-terminal e qualquer outro baseado nela) "AVISO: GnuTLS não está ativo; os dados serão escritos no disco desencriptados!": o aviso é decidido na compilação (#if !WITH_GNUTLS em src/vte.cc), não depende da configuração do histórico, por isso limitar o scrollback do xfce4-terminal não o tiraria e só reduziria o histórico. O passo vte-gnutls, no fim da F8e, reinstala a mesma VTE com -D gnutls=true, para que o histórico do terminal guardado em ficheiros temporários fique cifrado: como os overrides são por página e a página gnome/vte já tem o replace da F8d, gera o script da página, troca só essa opção numa cópia (gen/blfs/gnome/vte-gnutls.sh) e corre-a com o run-blfs.sh e o mesmo tarball (verificado pelo MD5 do livro); as restantes opções (sem GTK-4, sem Vala, sem documentação) ficam iguais. Verifica que a libvte-2.91.so passa a depender da libgnutls e já não contém o texto do aviso. O xfce4-terminal não precisa de ser recompilado (a interface da biblioteca não muda).

## Ícones do diálogo "Terminar sessão" pré-desenhados em PNG
_2026-11-12 19:24_

Num PC real o diálogo "Terminar sessão de ninja" do xfce4-session 4.20.3 mostrava em todos os botões (Sair, Reiniciar, Desligar, Suspender, Trocar de utilizador) o image-missing do WhiteSur (círculo vermelho de "proibido"). O xfce4-session pede xfsm-logout/-reboot/-shutdown/-suspend/-hibernate/-switch-user (recursos system-log-out, system-reboot, system-shutdown, system-suspend, system-hibernate, system-users) e só usa um nome se gtk_icon_theme_has_icon() o encontrar; o image-missing aparece portanto quando o nome existe no tema mas o ficheiro não se desenha. Na imagem todos esses nomes existem no WhiteSur-light (apps/scalable/xfsm-*.svg -> log-out.svg, reboot.svg...), sem ligações quebradas, iguais no rootfs.squashfs da ISO, e desenham-se bem no chroot e numa sessão Xfce completa (xfce4-session + painel + xfsettingsd, como o utilizador ninja, escala 1, 2 e 3, e com a cache do hicolor refeita a meio da sessão): não foi possível reproduzir a falha fora do PC. Estes SVG são os mais pesados do tema (imagem PNG embutida em base64 + filtro feGaussianBlur), ao contrário do image-missing (vetorial simples), que se desenhou no PC. Por isso o passo icones-sessao tira o librsvg do caminho do diálogo: para cada nome grava em WhiteSur/apps/scalable um <nome>.png de 256x256 desenhado na construção pelo rsvg-convert a partir do mesmo SVG (aspeto igual). O GTK 3 prefere .png a .svg na mesma pasta, por isso a 48 px (96 px com escala 2) carrega o PNG com o leitor interno do gdk-pixbuf; nos tamanhos do painel e menus (16-32 px) continuam a ganhar as pastas fixas actions/NN e status/NN (glifos simples, inalterados). WhiteSur-light e WhiteSur-dark usam as mesmas pastas (ligações para ../WhiteSur/apps). system-users não leva PNG: só é o 2.º recurso do xfsm-switch-user e a 48 px resolve para preferences/32.

## Inherits do WhiteSur: Adwaita,hicolor
_2026-11-12 19:24_

Os index.theme do WhiteSur, WhiteSur-light e WhiteSur-dark herdam de "hicolor,breeze", mas o breeze não existe no sistema. Passam a herdar de "Adwaita,hicolor": o Adwaita (BLFS, dependência do GTK 3) está instalado e serve de recurso para nomes simbólicos que faltem ao WhiteSur. As caches (gtk-update-icon-cache -f -t) dos três temas são refeitas no fim.

## Verificador de ícones no sistema
_2026-11-12 19:24_

scripts/apps/verificar-icones.py fica instalado como /usr/bin/ianinja-verificar-icones. Sem argumentos lista, para o tema WhiteSur-light, os nomes pedidos pelo Xfce (Icon= dos .desktop de menus, autostart e plugins do painel, nomes embutidos nos binários do xfce4-session, painel e plugins, xfdesktop e xfce4-notifyd, e a lista do diálogo de sessão) que faltam (FALTA), que só existem no hicolor/Adwaita (HERDADO) ou que não se desenham (ERRO). Na construção dá FALTA só para cadeias dos binários que não são ícones (nomes de sinais e classes CSS) e HERDADO para os ícones próprios no hicolor (loja, instalar-aplicacoes, face-finder, systray). Com --estrito NOMES... exige que cada nome venha do próprio tema e se desenhe em 16-96 px, e com --exigir-png que a 48/96 px seja o PNG; o passo usa-o para WhiteSur-light e WhiteSur e grava a prova visual em /tmp/icones-sessao/ (fora da ISO). No PC, "ianinja-verificar-icones --estrito" numa sessão gráfica diz se algum ícone deixa de se desenhar lá.

## F8e — Rede: NetworkManager em vez do bootscript network (dhcpcd)
_2026-11-12 19:24_

Até aqui o cabo era ligado pelo bootscript network do LFS (dhcpcd em eth0, só a 1.ª placa) e o Wi-Fi só com o comando ligar-wifi (wpa_supplicant + dhcpcd, wlan0 com ONBOOT="no"). Para a rede funcionar sozinha e ser fácil para qualquer pessoa instala-se o NetworkManager-1.54.0 (páginas basicnet/networkmanager, libndp, newt/slang para o nmtui) e o network-manager-applet-1.34.0 (com libnma-1.10.6 e Gcr-3.41.2): cabo ligado automaticamente em qualquer placa (eth0, eth1, adaptadores USB-Ethernet, incluindo ligados a quente — o NetworkManager cria sozinho a ligação "Wired connection" por DHCP), Wi-Fi escolhido no ícone da barra superior (o painel da F8d já tem o plugin systray, onde o nm-applet aparece como ícone XEmbed), redes lembradas em /etc/NetworkManager/system-connections (numa live sem persistência perdem-se ao desligar; com IANINJA-DADOS ficam e o sistema volta a ligar-se sozinho no arranque, antes de qualquer login) e várias placas Wi-Fi (wlan0, wlan1, ...). Alternativa avaliada: iwd + applet próprio — mais leve, mas o iwd não está no BLFS 12.4, o suporte iwd no NetworkManager ainda é "experimental" (opção -D iwd), não fala com drivers só WEXT e exigiria escrever e manter um applet; o NetworkManager com wpa_supplicant é o que as distribuições generalistas usam e o que o BLFS documenta, por isso é o mais fiável. Arranque: bootscript networkmanager do blfs-bootscripts (make install-networkmanager no passo nm-bootscript; S33 em rc2-5, depois do S29dbus; K28 em rc0/1/6). Como manda o livro, os links do bootscript network (S20network/S10network e K80network) são retirados de todos os níveis, para os dois não lutarem pela mesma placa; o /etc/rc.d/init.d/network, o dhcpcd e os /etc/sysconfig/ifconfig.* ficam instalados (ONBOOT="no" e um comentário a explicar) para quem os quiser usar à mão. O nmtui/nmcli servem a consola e o SSH.

## F8e — Rede: opções de compilação e configuração do NetworkManager
_2026-11-12 19:24_

Opções do livro, mais -D vapi=false (o Vala não está instalado) e -D tests=no (os testes precisam de uma sessão com D-Bus e só atrasariam a compilação). Sem iptables/nftables (recomendado pelo livro): só faz falta para partilhar a ligação (ponto de acesso/"hotspot" com NAT), não para ligar a redes. Sem ModemManager (modems 3G/4G), PPP, OVS, team, jansson. Configuração: NetworkManager.conf do livro (plugins=keyfile, escrito com ">" em vez de ">>" para o passo poder ser repetido) e conf.d/polkit.conf (auth-polkit=true). Desvios: (1) omitido o dhcp=dhcpcd — fica o cliente DHCP interno do NetworkManager (o predefinido, mais rápido e sem processos externos; o dhcpcd continua instalado); (2) omitido o dns=none — o NetworkManager passa a escrever o /etc/resolv.conf (antes era o dhcpcd), com rc-manager=file; (3) /etc/NetworkManager/conf.d/50-ianinja.conf (scripts/apps/rede/) com wifi.scan-rand-mac-address=no (o MAC aleatório durante a procura faz alguns adaptadores USB — rtl8xxxu, rtw88_usb, mt7601u — não encontrarem redes) e wifi.powersave=2 (poupança de energia desligada: com ela os adaptadores USB e vários Realtek/MediaTek perdem a ligação; custa pouca bateria). Sem verificação de conectividade (uri vazio): o estado é "connected" logo que há IP e rota, também na VM do QEMU.

## F8e — Rede: polkit e grupo netdev
_2026-11-12 19:24_

Bloco do livro com <username> = ninja (grupo netdev, gid 86) e a regra /usr/share/polkit-1/rules.d/org.freedesktop.NetworkManager.rules alargada: dá YES a todas as ações org.freedesktop.NetworkManager.* a quem está no grupo netdev OU numa sessão local ativa (subject.local && subject.active, sessões do elogind criadas pelo pam_elogind do LightDM e do login). Assim o utilizador gere redes sem senha de administrador e sem precisar de um agente de autenticação do polkit (não há nenhum instalado), e utilizadores criados depois (assistente do 1.º arranque) também podem, mesmo sem entrar no netdev; por SSH (sessão não local) só os do netdev. Como a permissão settings.modify.system fica YES, o nm-applet guarda a senha das redes Wi-Fi na própria ligação de sistema (/etc/NetworkManager/system-connections, modo 600), e não num chaveiro do utilizador — não há gnome-keyring, e só assim a rede volta a ligar-se no arranque antes do login.

## F8e — Rede: wpa_supplicant recompilado com D-Bus
_2026-11-12 19:24_

O NetworkManager comanda o wpa_supplicant por D-Bus (fi.w1.wpa_supplicant1, lançado a pedido pelo dbus-daemon), interface que a F8c não compilou (blocos 2 e 5 da página omitidos em scripts/book-overrides.txt, porque nessa altura não havia D-Bus). Os overrides são por página e não se mexe nos da F8c, por isso o passo wpa-dbus (função, como o mesa-vulkan do bloco 3) gera o script da página, cria uma cópia (gen/blfs/basicnet/wpa_supplicant-dbus.sh) com os blocos 2 e 5 ativos e sem os blocos 6 a 10 (serviço "wpa" e ifconfig.wlan0 já instalados pela F8c) e corre-a com o run-blfs.sh e o mesmo tarball wpa_supplicant-2.11 (MD5 do livro). Confirma-se que o binário fica ligado à libdbus-1 e que os ficheiros fi.w1.wpa_supplicant1.service e /etc/dbus-1/system.d/wpa_supplicant.conf existem.

## F8e — Rede: Gcr, libnma e network-manager-applet
_2026-11-12 19:24_

Gcr-3.41.2 (requerido pelo libnma: escolha de certificados para Wi-Fi empresarial WPA-EAP, p. ex. eduroam) com -D introspection=false: com o GIR o Gcr gera também os .vapi, que exigem o Vala (não instalado), e o libnma só usa a API C; bloco da documentação (GTK-Doc) omitido. libnma com -D libnma_gtk4=false (o GTK4 não está instalado; só o gnome-control-center usaria a versão GTK4) e -D vapi=false. network-manager-applet com -D wwan=false (sem ModemManager, como o livro indica). O nm-applet instala /etc/xdg/autostart/nm-applet.desktop (arranca em todas as sessões Xfce) e o "Editor de ligações de rede" (nm-connection-editor) aparece no menu. Notificações pelo xfce4-notifyd. Fica o newt-0.52.25 sem --with-gpm-support (o GPM não está instalado; o nmtui não precisa de rato) e o slang-2.3.3. O URL do newt no livro (releases.pagure.org) responde 404: o passo rede-fontes descarrega o mesmo tarball do espelho anduin.linuxfromscratch.org/BLFS/newt (SHA-256 ef0ca9ee27850d1a5c863bb7ff9aa08096c9ed312ece9087b30f3a426828de82 fixado; o MD5 coincide com o do livro e volta a ser verificado pelo blfs-fetch).

## F8e — Rede: ligar-wifi passa a usar o nmcli
_2026-11-12 19:24_

O /usr/bin/ligar-wifi da F8c chamava o ifup com o serviço "wpa" (um wpa_supplicant e um dhcpcd próprios), que lutaria com o NetworkManager. É substituído (scripts/apps/rede/ligar-wifi) por uma versão sobre o nmcli com as mesmas opções: 'ligar-wifi <SSID> [interface]' (nmcli --ask: a senha é pedida sem eco só se a rede a tiver e nunca aparece na linha de comandos), '-l' procura, '-d' desliga, e as novas '-e' (estado) e sem argumentos num terminal (abre o nmtui-connect). Liga o rádio Wi-Fi (nmcli radio wifi on) antes. Quem não está no netdev passa a root com sudo. A rede fica guardada e o NetworkManager volta a ligar-se sozinho.

## F8e — Rede: drivers de adaptadores Wi-Fi USB
_2026-11-12 19:24_

Confirmado na configuração do kernel 6.16.1 (/boot/config-6.16.1, base Arch) e nos módulos instalados pela F7 que os drivers em árvore comuns existem como módulos: rtw88 USB (rtw88_8821cu, 8822bu, 8822cu, 8723du e — desde o 6.14 — rtw88_8821au, 8812au, 8814au, que cobrem os populares RTL8811AU/8821AU/8812AU/8814AU), rtl8xxxu (com UNTESTED=y: RTL8188EU/8188FU/8192EU/8723BU/8710BU...), rtl8192cu, mt7601u, mt76x0u, mt76x2u, mt7663u, mt7921u, mt7925u, ath9k_htc, carl9170, rt2800usb (todos os RT35xx/53xx/55xx), rt73usb, brcmfmac (USB), ath10k_usb, ath6kl_usb, zd1211rw, mwifiex_usb, rsi_usb, e os de Ethernet USB (r8152, ax88179_178a, cdc_ether, cdc_ncm, rndis_host); o firmware de todos está no linux-firmware da F8c (rtw88/rtw88xxx_fw.bin, mediatek/, htc_*.fw, carl9170-1.fw, rt2870.bin, rtlwifi/...), e o modules.alias associa os ids USB mais comuns ao driver certo (verificado no passo rede-verificar). Por isso NÃO se inclui nenhum driver fora da árvore (morrownr/8821au, aircrack-ng/rtl8812au): o rtw88 do 6.16 já cobre esses chips sem compilar nada e sem o risco de módulos externos que partem a cada versão do kernel. Lacuna conhecida: o rtw89 do 6.16 só tem PCI — os adaptadores Wi-Fi 6 USB RTL8852BU/8832BU/8851BU/8852CU (ex.: alguns TP-Link Archer TX20U/TX50U, BrosTrend AX1/AX4) só têm driver em árvore a partir do kernel 6.17/6.18; ficam sem suporte (o info-hardware mostra um AVISO quando vê um adaptador destes sem driver). Solução proposta, não aplicada: atualizar o kernel da F7 para ≥6.17 (preferível) ou compilar o driver morrownr/rtl8852bu contra os kernel-headers do bloco 3, como o OpenRazer. Acrescenta-se ainda a regra udev 70-ianinja-wifi-modo-cd.rules: muitos adaptadores Realtek recentes apresentam-se primeiro como um CD-ROM com o driver para Windows (0bda:1a2b) e só depois de ejetado esse CD passam a placa Wi-Fi; a regra corre o eject do util-linux no sr correspondente (o mesmo que o "StandardEject" do usb_modeswitch, que não está no BLFS).

## F8e — Rede: info-hardware
_2026-11-12 19:24_

A secção "Rede sem fios" do info-hardware (bloco 3) passou a "Rede": para cada placa física (Wi-Fi e cabo) mostra o barramento e o id (USB vvvv:pppp ou PCI), o nome do fabricante/produto, o driver em uso e, com o NetworkManager a correr, a versão do firmware, o estado e a ligação (nmcli device show); avisa quando há um adaptador USB de um fabricante de Wi-Fi sem nenhum driver associado. O passo rede-configurar reinstala /usr/bin/info-hardware.

## Assistente de configuração no lugar do ecrã de entrada (greeter do LightDM)
_2026-11-12 19:24_

Pedido: no 1.º arranque perguntar o nome, o utilizador e a senha e criar a conta para entrar no sistema. O assistente (scripts/apps/assistente/assistente.py, Python 3 + GTK 3 do bloco 02, pt-PT, cartão branco translúcido sobre o papel de parede da distro, cores e botões em comprimido da Loja) é um greeter do LightDM: /etc/lightdm/lightdm.conf.d/60-ianinja-assistente.conf põe greeter-session=ianinja-assistente (lido depois do 10-ianinjapelagestao.conf; o lightdm.conf não fixa greeter-session, o passo confirma-o e o lightdm --show-config mostra o valor). O greeter é /usr/libexec/ianinja-assistente/greeter (bash): pergunta o estado e, se o sistema não estiver configurado, faz exec do assistente; em todos os outros casos faz exec do /usr/bin/lightdm-gtk-greeter de sempre, com o mesmo nome de processo. Escolheu-se o greeter, e não um X próprio antes do LightDM nem o greeter-setup-script, porque: o X continua a ser arrancado pelo LightDM e vigiado pelo ianinja-dm (níveis de recurso, modo gráfico de compatibilidade e desistência para a tty1 ficam iguais — o ianinja-dm não tem limite de tempo e dá o arranque por bom quando aparece o greeter GTK ou o xfce4-session); o inittab e o ianinja-dm (F9) não mudam; e o greeter pode entrar logo na sessão Xfce da conta acabada de criar pelo protocolo do LightDM (liblightdm-gobject, LightDM-1.typelib da F8d: authenticate + respond + start_session), sem reiniciar o LightDM. O modo de texto (nível 3, entrada do GRUB 'modo texto') não tem LightDM e nunca é bloqueado.

## Fluxo, validação e o que é criado
_2026-11-12 19:24_

Páginas: boas-vindas ("Criar a minha conta" ou "Experimentar sem criar conta"; em live sem disco de dados um aviso de que a conta se perde ao desligar), teclado e fuso horário, conta, resumo, a criar, pronto. Teclados: Português (Portugal) pt/pt-latin1, Português (Brasil) br/br-abnt2, Inglês (EUA) us/us — ao mudar, o greeter faz setxkbmap para a senha já ser escrita com o teclado escolhido. Fusos: 13 (Portugal continental, Madeira, Açores, Brasil x3, Angola, Moçambique, Cabo Verde, Londres, Paris, Nova Iorque, UTC). Nome de utilizador: sugerido a partir do nome completo (sem acentos), [a-z_][a-z0-9_-]*, até 32, não pode existir como utilizador nem como grupo nem ser reservado (root, ninja, lightdm, contas de sistema, grupos conhecidos, admin, teste...). Senha: mínimo 8 caracteres, diferente do utilizador, não "muito fraca" (palavras comuns como 123456/senha/ninja/benfica descontam), confirmação igual; força em 4 segmentos (Fraca, Razoável, Boa, Forte). Ao concluir (contas.py, como root): useradd -m -k /etc/skel -U -s /bin/bash -c "<nome>" com os grupos suplementares do ninja (lpadmin, plugdev) mais wheel, audio, video, input, users, kvm, cdrom e os de GRUPOS_EXTRA que existam (netdev, render, optical, storage, scanner, bluetooth); senha pelo stdin do chpasswd (PAM, yescrypt como o ninja; nunca na linha de comandos nem em registos); se a senha falhar a conta é apagada (userdel -r). Depois: opcionalmente a mesma senha para o root (caixa marcada por omissão — a senha pública do root não deve ficar num sistema com persistência), /etc/X11/xorg.conf.d/00-keyboard.conf e KEYMAP do /etc/sysconfig/console, /etc/localtime, autologin opcional e o marcador /var/lib/ianinjapelagestao/configurado. Registo sem senhas em /var/log/ianinja-assistente.log.

## sudo do novo utilizador COM senha
_2026-11-12 19:24_

O ninja tem 'NOPASSWD: ALL' (/etc/sudoers.d/ninja) por ser a conta pública do live com senha conhecida. A conta criada pelo assistente entra no grupo wheel, que já tem '%wheel ALL=(ALL) ALL' (/etc/sudoers.d/00-sudo): o sudo pede a senha do próprio utilizador, como no macOS e nas distribuições comuns. Confirmado no ensaio: 'sudo -l -n' da conta nova responde "é necessária uma senha".

## Parte privilegiada pelo sudo do utilizador lightdm
_2026-11-12 19:24_

O greeter corre como lightdm (sem privilégios). A criação da conta passa por /usr/libexec/ianinja-assistente/aplicar (python3 -I, sys.path só com /usr/share/ianinja-assistente, root:root), autorizado em /etc/sudoers.d/ianinja-assistente: 'lightdm ALL=(root) NOPASSWD: /usr/libexec/ianinja-assistente/aplicar' (visudo -cf no passo). Só aceita as ações estado, criar (dados em JSON no stdin, validados outra vez) e experimentar; recusa --raiz e repor; criar recusa sempre que o sistema já esteja configurado. Antes da configuração o ninja já tem sudo sem senha e senha pública, por isso a regra não abre nada de novo; depois, só sobra ler o estado e o ficheiro em /run. O passo confirma que o lightdm não consegue 'aplicar repor' nem 'sudo id'.

## O utilizador ninja depois da configuração e caminho de recuperação
_2026-11-12 19:24_

Depois de criar a conta o ninja é acrescentado a hidden-users em /etc/lightdm/users.conf (deixa de aparecer no ecrã de entrada) e bloqueado (usermod -L: a senha do ninja deixa de servir); a conta, a pasta /home/ninja e o /etc/sudoers.d/ninja ficam (testes e passos que usam su - ninja continuam a funcionar como root). Recuperação: 1) a conta criada tem sudo; 2) o root entra nas consolas (Ctrl+Alt+F1) com a senha escolhida (ou a senha de origem se a caixa foi desmarcada); 3) 'sudo ianinja-assistente --repor' apaga o marcador e o autologin, desbloqueia e volta a mostrar o ninja, e o assistente volta a aparecer no próximo ecrã de entrada (as contas criadas ficam); 4) esquecidas todas as senhas, a entrada do GRUB 'sem persistência' arranca o sistema de origem (com as senhas de origem), onde o disco IANINJA-DADOS pode ser montado e a senha reposta com 'chpasswd -R <disco>/overlay/upper' (o /etc/shadow alterado está inteiro na camada de escrita). 'sudo ianinja-assistente --sem-autologin' desliga só o autologin.

## Live sem persistência, "Experimentar sem criar conta" e autologin
_2026-11-12 19:24_

Sem persistência a camada de escrita é RAM: o marcador perde-se e o assistente aparece em cada arranque (normal). "Experimentar sem criar conta" cria /run/ianinja-assistente/experimentar (pelo aplicar) e entra como ninja pelo LightDM; ao terminar a sessão aparece o greeter GTK normal com o ninja (só até desligar). Com persistência a conta, o marcador e as definições ficam na camada IANINJA-DADOS e o assistente não volta. Autologin: /etc/lightdm/lightdm.conf.d/70-ianinja-autologin.conf (autologin-user, autologin-user-timeout=0, autologin-session=xfce); o PAM lightdm-autologin do BLFS não exige grupo autologin. Na primeira vez o assistente entra logo na sessão com a senha que acabou de ser escrita, com ou sem autologin.

## Desligar o assistente: ianinja.assistente=0 (linha do kernel ou SMBIOS) para os testes
_2026-11-12 19:24_

O estado é 'desligado' com ianinja.assistente=0 na linha do kernel ou nas cadeias OEM do SMBIOS (tipo 11, /sys/firmware/dmi/entries/11-*/raw, só legível pelo root — por isso o estado é pedido pelo aplicar). Os testes F11 arrancam a entrada do GRUB por omissão e não editam a linha do kernel; o QEMU passa a cadeia sem mexer no GRUB com '-smbios type=11,value=ianinja.assistente=0' (confirmado com o kernel e o initramfs da ISO: /sys/firmware/dmi/entries/11-0/raw contém a cadeia; CONFIG_DMI_SYSFS=y). Assim o greeter faz exec do lightdm-gtk-greeter e o pidof lightdm-gtk-greeter dos testes continua certo. No VirtualBox o equivalente é a chave extradata DmiOEMVBoxVer. Não se deteta "ausência de ecrã real": na VM de teste há uma placa bochs com KMS igual à de um utilizador numa VM, e um critério assim esconderia o assistente a quem o usa num QEMU/VirtualBox.

## Robustez: o assistente nunca impede o ecrã de entrada
_2026-11-12 19:24_

Qualquer falha cai no lightdm-gtk-greeter: sudo indisponível ou estado desconhecido (o greeter só mostra o assistente se o estado for exatamente 'ativo'); python3 que não arranca (execfail); exceção no assistente antes de falar com o LightDM (os.execv do greeter GTK com os mesmos descritores do LightDM — o assistente só se liga ao LightDM no momento de entrar); se o assistente arrancar 3 vezes no mesmo arranque (contador com o boot_id em /var/lib/lightdm/.ianinja-assistente-tentativas, ex. a falhar sempre) passa ao greeter normal; no ecrã de erro há "Ir para o ecrã de entrada". Sem gestor de janelas, a janela ocupa o monitor principal (sem decorações) e pede o foco. A imagem nunca sai configurada (o passo apaga o marcador, o autologin e o contador).

## Modo de texto
_2026-11-12 19:24_

'sudo ianinja-assistente --texto' faz as mesmas perguntas na consola (getpass para a senha, força mostrada, mesmas validações e mesma aplicação). Nas consolas tty1-tty6, enquanto o sistema não estiver configurado, /etc/profile.d/ianinja-assistente.sh mostra uma linha com essa dica ao entrar (não na ttyS0 dos testes nem dentro da sessão gráfica).

## Verificação na construção sem tocar nas contas reais
_2026-11-12 19:24_

assistente-verificar: como lightdm, 'sudo -n aplicar estado' funciona e 'aplicar repor' e 'sudo id' são recusados; 'assistente.py --verificar' como lightdm importa GTK e LightDM, lê o CSS e testa a validação; uma conta completa é criada numa cópia de /etc em /tmp/assistente-teste (useradd/usermod --root, chpasswd --root -c SHA512, porque dentro da raiz alternativa não há PAM), conferida (passwd, 5 grupos, ninja bloqueado e escondido, autologin, teclado br, dono da pasta, marcador), reposta com repor e apagada; no fim confirma-se que o sistema real não tem o marcador, nem a conta, e que o ninja não ficou bloqueado. Ensaio fora da build (overlay tmpfs sobre o lfs.img montado só de leitura): os dois passos passam, lightdm --show-config dá greeter-session=ianinja-assistente, e uma conta criada pelo caminho real (lightdm -> sudo -> aplicar criar) fica com hash yescrypt, os grupos certos e sudo com senha.

## Otimizações: medição de partida
_2026-11-12 19:24_

Medido no alvo (lfs.img só-leitura, 2026-11-12): /usr 6,6 GB (/usr/lib 2,8 GB, /usr/share 2,2 GB dos quais 1,1 GB é o modelo Qwen2.5 da IA, /usr/bin 0,9 GB), /usr/lib/firmware 790 MB (já em .xz), /usr/share/doc 265 MB, /usr/share/locale 246 MB (224 línguas), /usr/share/man 102 MB, /usr/share/info 41 MB, /usr/share/clc 76 MB, testes do Python 140 MB, bibliotecas estáticas 539 MB (LLVM 240 MB, Clang 213 MB, Valgrind 46 MB). 2698 ficheiros ELF ainda tinham símbolos/depuração (os pacotes BLFS não fazem strip; o gdb sozinho tinha 181 MB): 2,2 GB que passam a 1,4 GB com strip --strip-unneeded. Os módulos do kernel já estão comprimidos em zstd e sem depuração (CONFIG_DEBUG_INFO_NONE). rootfs.squashfs xz de 128 KiB: 3,20 GB; ISO 3,25 GB. Serviços: rcS sem nada a mais; nível 5 com sysklogd, network, dbus e bluetooth (sempre, mesmo sem adaptador); CUPS e sshd desligados; autostart do Xfce: notifyd, xfsettingsd, instalar-tudo (1.º início), openrazer (já condicional), blueman-applet (sempre) e at-spi (só GNOME). Kernel com CONFIG_ZSWAP_DEFAULT_ON=y além da zram. RAM no QEMU (4 GiB, ecrã de entrada do LightDM, depois de drop_caches): 358 MiB usados.

## Strip dos executáveis e bibliotecas (passo otim-strip)
_2026-11-12 19:24_

scripts/apps/otimizacoes/strip.sh corre no chroot com o strip do próprio alvo, no fim da F8e (apanha o que todos os blocos instalaram). Só toca em ELF64 x86-64 do tipo EXEC/DYN que ainda tenham .symtab ou .debug_* (idempotente), em /usr e /opt. Fica de fora: /usr/src (headers do kernel e objtool/modpost, para NVIDIA e OpenRazer), /usr/share, /usr/include, /usr/lib/modules, /usr/lib/firmware, /usr/lib/grub (os .mod precisam da tabela de símbolos), /usr/lib/debug, todo o Valgrind, /opt/rustc*, e ld-linux/libc.so.6/libthread_db (o memcheck do Valgrind precisa dos símbolos do ld.so e o GDB os da libthread_db); também binários Go e ficheiros com dados depois do fim do ELF (o strip deitaria fora a carga anexada). O strip escreve para um ficheiro novo, copia dono, modo (setuid incluído), datas e xattrs (capabilities) do original com cp --attributes-only e faz rename por cima, por isso nada em execução fica com um ficheiro meio escrito; ligações físicas (git-core, gcc) são refeitas com ln -f, e um inode com ligações fora da lista fica como está. Uma falha de strip deixa o original e só é registada. A seguir o passo confirma que bash, python3, node, npm, gdb, gcc, clang, git, Xorg, flatpak, bwrap, valgrind, llama-cli, xfconf-query, lightdm, cmake, curl, openssl e sudo respondem, que o Python importa sqlite3/ssl/ctypes/numpy/cv2/gi/requests e que se compila e corre um programa C e um C++. Ensaio numa cópia em overlay (strip do host): 2394 ficheiros, 2070 -> 1364 MiB, 0 falhas; depois disso memcheck do Valgrind, compilação de um módulo externo contra /lib/modules/6.16.1/build, gdb com breakpoint, cv2 e node funcionaram. Perde-se: depuração simbólica dentro das bibliotecas do sistema (os programas do próprio utilizador compilados com -g continuam depuráveis).

## SquashFS: exclusões só da imagem (F9, exclusoes_live)
_2026-11-12 19:24_

A F9 gera logs/f9-exclusoes.txt (-ef do mksquashfs; o $LFS não muda). Fora da imagem: /usr/share/doc (ficam a documentação da distro referida no motd, a do lynx — é a ajuda do próprio lynx — e os ficheiros COPYING*/LICENSE*/LICENCE*/COPYRIGHT*/NOTICE*, por causa das licenças), /usr/share/gtk-doc, /usr/share/info (as páginas man ficam: são o que se usa e comprimem bem), traduções de mensagens e páginas man exceto pt, pt_PT, pt_BR, en e en_US, os testes do Python (python3.13/test, idle_test e as pastas tests dos pacotes; numpy.testing fica), as bibliotecas estáticas do LLVM/Clang/LLD/MLIR/Polly e do Valgrind (as de glibc, gcc, libstdc++ e as restantes ficam, para gcc -static), os .la do libtool (o libltdl recorre ao .so), os cargo-c (cargo-cbuild/-cinstall/-ctest/-capi, inúteis sem o cargo do /opt/rustc, que já não ia na imagem), /usr/share/clc (o libclc só é usado na compilação do Mesa; o libgallium não o referencia e não há OpenCL/rusticl) e firmware de hardware que não existe num PC x86-64: SoC ARM da Qualcomm (qcom/*, ficam aic100, qdu100 e sdx*, placas PCIe/M.2), ASIC de switches Mellanox Spectrum e Marvell Prestera e NXP DPAA2 (~350 MB já em .xz, que na ISO contavam por inteiro). Ficam /usr/include, /usr/src/linux-headers-6.16.1, todo o restante firmware (NVIDIA GSP, amdgpu, i915/xe, iwlwifi, mediatek, ath*, rtw*...) e o modelo da IA. Verificado no ensaio com unsquashfs -l: nenhum caminho da lista ficou na imagem e ficaram o README da distro, pt_PT/pt_BR, man1, libc.a, libLLVM.so, numpy/testing, qcom/aic100, nvidia/ga102, clang, headers e modelos. Limitação: um projeto CMake que faça find_package(LLVM/Clang) falha na live (os ficheiros CMake do LLVM verificam os .a); llvm-config --link-shared, clang e a libclang continuam a funcionar.

## SquashFS: zstd nível 19 com blocos de 1 MiB
_2026-11-12 19:24_

Medido com o mesmo conteúdo (depois do strip e das exclusões): xz 128 KiB 2,31 GB em 129 s; xz com filtro BCJ x86 e blocos de 1 MiB 2,22 GB em 320 s; zstd -Xcompression-level 19 -b 1M 2,29 GB em 171 s. Descompressão num núcleo (unsquashfs -p 1 de /usr/bin, /usr/libexec e python3.13, 914 MiB): xz 16,0 s, xz+BCJ 14,1 s, zstd 1,5 s. O xz+BCJ seria 64 MB mais pequeno, mas o SquashFS é lido da pen durante todo o uso (arranque, cada programa aberto) e o kernel descomprime por omissão com um só fluxo: com xz isso fica limitado pelo CPU a ~65 MB/s, abaixo de uma pen USB 3; com zstd é ~10x mais rápido e numa pen USB 2 (~30 MB/s) os 3 % a mais quase não se notam. Blocos de 1 MiB comprimem melhor; o custo (ler um bloco maior para um ficheiro pequeno) é pequeno com zstd. O kernel tem SQUASHFS_ZSTD=y (embutido), o initramfs não muda. Resultado do ensaio: rootfs.squashfs 3,20 GB -> 2,29 GB e ISO 3,25 GB -> 2,34 GB (-0,91 GB, -28 %); a ISO de ensaio arrancou no QEMU até ao ecrã do LightDM.

## zswap desligado (zswap.enabled=0 no GRUB)
_2026-11-12 19:24_

O kernel 6.16.1 tem CONFIG_ZSWAP_DEFAULT_ON=y e a swap da live é a zram (scripts/sistema/zram): o zswap guardava as páginas comprimidas num pool em RAM antes de as mandar para a zram, que as comprime outra vez — CPU e RAM gastos duas vezes. Todas as entradas do grub.cfg (F10) passam a ter zswap.enabled=0; confirmado no QEMU (/sys/module/zswap/parameters/enabled = N). Os restantes parâmetros de memória (swappiness 100, page-cluster 0) já estão certos para zram; vm.vfs_cache_pressure fica no valor por omissão (100): baixá-lo guardaria mais dentries/inodes, o contrário de poupar RAM.

## Bluetooth só com adaptador (passo otim-bluetooth)
_2026-11-12 19:24_

O bootscript do BLFS lê /etc/sysconfig/bluetooth logo no início; esse ficheiro ganha um bloco marcado que, no 'start', sai com SKIP se não houver /sys/class/bluetooth/hci* (o udev já carregou o btusb antes do S35). O bootscript e as ligações rc*.d não mudam (stop/status/restart iguais). Um adaptador ligado mais tarde (pen USB) é tratado por /etc/udev/rules.d/90-ianinja-bluetooth.rules (SUBSYSTEM bluetooth, DEVTYPE host), que chama /usr/sbin/ianinja-bluetooth-hotplug: se o bluetoothd não estiver a correr, o D-Bus já estiver e o nível for 2-5, arranca o serviço com setsid -f (fora do processo do udev). O autostart do blueman-applet (Python + GTK, dezenas de MiB por sessão) passa a chamar /usr/bin/blueman-se-houver, que só o lança com adaptador (como o openrazer-se-houver). Com adaptador ligado depois do início de sessão, o Gestor de Bluetooth abre-se pelo menu. bluetoothctl continua instalado (teste F11). Confirmado no QEMU: sem adaptador o bluetoothd (4,5 MiB) já não arranca.

## Compositor desligado em modo de recurso; miniaturas limitadas (passo otim-xfce)
_2026-11-12 19:24_

O compositor do xfwm4 fica ligado (é leve com aceleração). /usr/bin/ianinja-compositor-auto (autostart XFCE) desliga-o quando o desenho é feito pelo CPU: nomodeset na linha do kernel (entrada "modo gráfico de compatibilidade"), nível de recurso do ianinja-dm (/etc/X11/xorg.conf.d/90-ianinja-recurso.conf), nenhum /dev/dri/renderD* (simpledrm, bochs...) ou glxinfo a dizer llvmpipe/softpipe. Deixa uma marca em ~/.config/ianinjapelagestao/compositor-desligado-auto e, num arranque normal seguinte (com persistência), volta a ligá-lo; se o utilizador o desligou por sua vontade (sem marca), não lhe toca. No tumbler o PixbufThumbnailer (que lê a imagem inteira para a RAM) só faz miniaturas de ficheiros até 50 MiB (MaxFileSize=52428800); o tumblerd já é ativado a pedido pelo D-Bus e sai sozinho quando fica parado.

## O que ficou de fora e porquê
_2026-11-12 19:24_

initramfs: já é mínimo (~3 MB: bash, mount, blkid e pouco mais) e os drivers de armazenamento/USB estão embutidos no kernel; os 18 MB do microcódigo Intel+AMD têm de ir todos (não se sabe o CPU). locale-archive (25 MB, ~30 locales da glibc): reduzir obrigava a recompilar os locales e poupava ~4 MB na ISO. Ligações físicas do strip, agettys tty2-6 (~1 MiB cada, partilhada) e o at-spi (só arranca em GNOME) ficam. Não se mexeu no serviço de rede (bloco 8), no sysklogd nem no dbus. Páginas man, /usr/include, headers do kernel, Cython, Valgrind, gir-1.0 e cmake ficam (programação). threads=multi na montagem do SquashFS aceleraria ainda mais a leitura em paralelo, mas obrigava a mexer no live-init.sh e gastava memória por CPU; o zstd já resolve o essencial. A RAM no ecrã de entrada ficou igual (354 vs 358 MiB): os ganhos de RAM aparecem na sessão (blueman-applet, bluetoothd, zswap, compositor em modo de recurso) e não foram medidos numa sessão Xfce real.

## Testes F11: rede pelo NetworkManager e assistente de 1.º arranque
_2026-11-12 19:27_

Com os blocos 08 (NetworkManager no lugar do bootscript network/dhcpcd) e 09 (Assistente de configuração como greeter do LightDM) da F8e, os modos BIOS e UEFI passam de 18 para 20 critérios: 20 'Rede: NetworkManager liga o cabo sozinho' (a VM tem -nic user,model=e1000: pidof NetworkManager; nenhum link S..network em rc3.d, rc5.d nem no nível atual; nm-online -s -t 60; nmcli -t -f STATE general = connected; eth0:connected em nmcli -t -f DEVICE,STATE device; IP 10.0.2.x em eth0; nameserver no /etc/resolv.conf; /etc/xdg/autostart/nm-applet.desktop existe — o teste não abre sessão Xfce, só chega ao greeter, por isso o nm-applet em si não é testado) e 21 'Assistente desligado pela cadeia SMBIOS' (ianinja-assistente --estado como root diz exatamente 'desligado (ianinja.assistente=0 nas cadeias OEM do SMBIOS)'; a VM recebe -smbios type=11,value=ianinja.assistente=0 para o greeter fazer exec do lightdm-gtk-greeter e os critérios 12-13 continuarem certos). O critério 5 (DHCP + wget) espera agora até 120 s pelo IP, que passa a vir do NetworkManager (S33). Novo modo assistente-bios (BIOS, SEM a cadeia SMBIOS), 4 critérios: o estado é 'ativo'; o greeter do LightDM é o assistente (pgrep -f assistente.py com o lightdm a correr; se aparecer o lightdm-gtk-greeter é FAIL), com captura do ecrã em logs/11-ecra-assistente-bios.png só informativa; uma conta de ensaio ('ensaio', senha_root=false, sem autologin) criada pelo mesmo caminho do greeter (su lightdm -> sudo -n /usr/libexec/ianinja-assistente/aplicar criar, JSON no stdin) fica no grupo wheel, com senha e com o estado 'configurado'; e autentica com a senha (su ensaio a partir do ninja, que não é root, por isso a senha é pedida) e recusa uma senha errada. Tudo na camada de escrita em RAM; qualquer passo falha limpo (FAIL, ou LENTO sem KVM) sem prender os seguintes.

## F11 assistente-bios: o su pede "Palavra-passe:" e a recusa é em português
_2026-11-12 19:37_

Na 1.ª corrida do modo assistente-bios o critério 4 expirou: com o locale pt_PT o su pede "Palavra-passe:", que o padrão do teste (assword:|enha:) não apanhava, e a mensagem de recusa também não é "Authentication failure". Defeito do teste, não do sistema (a conta foi criada, no wheel e com hash yescrypt). Correção em scripts/teste-qemu.exp: o pedido de senha aceita também "asse:", e a senha errada conta como recusada quando o prompt do teste volta sem a marca AUTENT_43 (independente da língua). De caminho, o greeter (/usr/libexec/ianinja-assistente/greeter) deixava no log do LightDM "linha 16: ...-tentativas: Ficheiro ou pasta inexistente" no 1.º arranque, porque o 2>/dev/null vinha depois do < no read; a ordem foi trocada (read -r b n 2>/dev/null < $CONT). Só cosmético, mas obriga a refazer assistente-instalar/assistente-verificar e F9-F12.

## Página onde guardar os dados
_2026-11-13 14:08_

Pedido de 12/11/2026 ("na primeira sessão ele pergunta onde, você escolhe, e depois fica sempre tudo salvo"); interface com o backend em scripts/apps/persistencia/CONTRATO.md. O assistente não decide nada sobre discos: só mostra o que o backend lista e passa a escolha. Páginas novas: "dados" (entre teclado/fuso e conta), "armazenar" e "reiniciar" (depois de criar a conta). O aviso amarelo da página de início ("crie primeiro um disco de dados persistente (sudo ia-criar-persistencia)") saiu: ficou obsoleto. - Quando aparece: ao arrancar, numa thread, o assistente pede persistencia-estado e persistencia-listar (greeter: sudo -n aplicar persistencia-…; --janela --raiz / como root: /usr/sbin/ianinja-persistencia … --json, só na raiz real; sem --raiz: dados de exemplo). estado.ativo verdadeiro → a página não aparece (resumo: "No armazenamento já ativo neste sistema"); estado falha (aplicar antigo sem a ação, sudo recusado, backend ausente) → também não aparece (é o "sem backend capaz") e o fluxo é o de antes. Se o utilizador chegar à página antes da resposta, vê "A procurar pens e discos…" com o Continuar desativado; se a resposta for "ativo" ou falha, passa sozinho à conta. O indicador de passos tem 5 pontos com a página e 4 sem ela. - Conteúdo: cartões de escolha única (Gtk.RadioButton com título, detalhe e etiqueta "Recomendado" ou "Apaga o disco"), a recomendada pré-selecionada (nunca uma que apaga); por último "Não guardar — tudo se perde ao desligar". listar falhou ou veio vazio → caixa azul a explicar (com o motivo) e só "Não guardar". pen/ficheiro → "Espaço para os seus dados (GB)": Gtk.Scale + Gtk.SpinButton com o mesmo ajuste, de 1 GB a max_mb, por omissão sugerido_mb; o valor de cada opção fica lembrado ao trocar; no máximo envia-se max_mb exato (não arredondado a GB). particao (ou apaga=true) → aviso vermelho com o nome do disco e a caixa "Compreendo que tudo nesse disco é apagado"; sem ela o Continuar fica desativado e a caixa é desmarcada sempre que se troca de opção. - Resumo: linha "Dados guardados em" com o destino e o tamanho (vermelho se apaga), ou "Em lado nenhum: perdem-se ao desligar". - Execução: só depois de a conta ser criada com sucesso (o backend copia a camada de escrita atual, por isso a conta vai junto). Página "A preparar o armazenamento…" com Gtk.ProgressBar alimentada pelas linhas PROGRESSO n texto (lidas linha a linha numa thread, stderr junto ao stdout; a UI só é tocada por GLib.idle_add); OK → sucesso; ERRO texto, rc≠0 ou fim sem OK → erro com o texto, "Tentar outra vez" ou "Continuar sem guardar" (a conta já existe e fica). Para o greeter o JSON {"id","tamanho_mb","confirmo_apagar"} vai no stdin de 'sudo -n aplicar persistencia-criar'; localmente usa-se 'criar <id> --tamanho-mb N [--confirmo-apagar]'. - Fim: "Os seus dados passam a ser guardados em X. Reinicie para ativar." "Reiniciar agora" só aparece se LightDM.get_can_restart() for verdadeiro (LightDM.restart(); o sudoers do lightdm só permite o aplicar, por isso não há reboot pelo sudo); senão o texto diz para reiniciar pelo menu (Sair → Reiniciar) e há só "Continuar". No modo --raiz nunca reinicia a máquina. "Mais tarde" segue para a página "pronto" de sempre, que lembra que os dados só começam a ser guardados depois de reiniciar (e, sem destino, que tudo se perde ao desligar). - Teclado e acessibilidade: setas mudam de opção no grupo de rádio, Tab passa à escala/caixa numérica, à confirmação e aos botões; mnemónicas Alt+N (Não guardar), Alt+E (espaço), Alt+M (Compreendo…), Alt+C/Alt+V (Continuar ou Criar conta / Voltar), Alt+T/Alt+S (Tentar outra vez / Continuar sem guardar), Alt+R/Alt+M (Reiniciar agora / Mais tarde); foco visível (anel azul) nos cartões e nos botões; cada cartão tem nome e descrição ATK. - Defeitos visuais corrigidos de caminho: o rodapé (Voltar/Continuar) era escondido por ir("inicio") mas o win.show_all() seguinte voltava a mostrá-lo, por isso a 1.ª página tinha "Voltar" e um "Continuar" a duplicar "Criar a minha conta"; o rodapé passou a set_no_show_all e só ir() o mostra (nunca na página de início). Sem compositor a sombra do cartão deixava rasto quando o cartão encolhia: ir() faz queue_draw da janela. Rótulos centrados passam a ter justificação centrada. - Ensaio (host WSL com Xvfb, modo simulado; IANINJA_SIMULAR_DADOS=ativo|vazio|falha|erro): capturas de cada página (--captura … --pagina dados|dados-particao|dados-vazio|resumo|armazenar|armazenar-erro|reiniciar|pronto), percurso automático (pré-seleção, confirmação obrigatória, tamanho lembrado ao voltar, erro → tentar outra vez → reiniciar → mais tarde; erro → continuar sem guardar; ativo e estado falhado sem página; listar falhado só com "Não guardar"; backend lento) e percurso só com teclado (xdotool) numa janela real. Não ensaiado: o backend real, o sudo/aplicar com as ações novas e LightDM.get_can_restart()/restart() dentro do LightDM. O assistente-instalar já copia assistente.py e estilo.css (refazer assistente-instalar/assistente-verificar e F9-F12).

## Guardar os dados automaticamente: um backend, três destinos
_2026-11-13 14:08_

O utilizador testou a ISO num PC real e "nada fica salvo": só havia persistência com um ext4 IANINJA-DADOS feito à mão (sudo ia-criar-persistencia), que ninguém faz. O bloco 11 instala /usr/sbin/ianinja-persistencia (Python 3, root; fonte em scripts/apps/persistencia/, contrato em CONTRATO.md) com os subcomandos estado --json, listar --json e criar <id> [--tamanho-mb N] [--confirmo-apagar], e a versão do assistente que o chama (assistente.py com a página "Onde guardar os seus dados?", contas.py com as ações persistencia-estado/listar/criar e reiniciar, aplicar, sudoers). Os três tipos de destino são os do contrato: "pen" (partição nova no espaço livre a seguir à imagem ISO, na própria pen — nada é apagado), "ficheiro" (/ianinja/ianinja-dados.img com um ext4 lá dentro, numa partição NTFS, exFAT, FAT ou ext4 já existente, por exemplo o disco do Windows — nada é apagado) e "particao" (formata uma partição ou um disco sem partições — apaga tudo, só com --confirmo-apagar). O criar imprime "PROGRESSO <0-100> <texto em pt-PT>" por evento e no fim "OK <id>" ou "ERRO <texto>"; a ordem do listar é pen, ficheiros (mais espaço primeiro), partições (removíveis primeiro), e a primeira opção que não apaga dados é a recomendada. Fora do sistema live (chroot da construção) o estado diz inativo, o listar devolve [] e o criar recusa — é o que o passo persistencia-verificar confirma.

## Tipo "pen": partição a seguir à imagem na própria pen (sfdisk sobre a GPT da ISO híbrida)
_2026-11-13 14:08_

A ISO do grub-mkrescue/xorriso é híbrida: MBR protetor (0xEE) com o código de arranque BIOS do GRUB nos primeiros 440 bytes, GPT (Gap0, "EFI boot partition" FAT, HFSPLUS com o rótulo, Gap1 — 176 entradas) e o ISO9660 no disco inteiro; a cópia de segurança da GPT fica no fim da IMAGEM e não no fim da pen (o kernel avisa "backup GPT not at the end"). O criar pen: 1) sfdisk --relocate gpt-bak-std move a cópia de segurança para o fim do disco e corrige o tamanho do MBR protetor (só isto torna utilizável o espaço a seguir à imagem); 2) sfdisk --append com start = isosize alinhado a 1 MiB, type Linux filesystem (GUID 0FC63DAF…; "83" numa ISO com tabela MBR) e name=IANINJA-DADOS, com --no-reread e --no-tell-kernel porque o disco está em uso pela raiz; 3) partx -a/-u (BLKPG, que funciona com o disco em uso, ao contrário do BLKRRPART) e udevadm settle; 4) mkfs.ext4 -F -L IANINJA-DADOS na partição nova — antes de cada mkfs o backend espera (udevadm settle e até 20 s) que o dispositivo aceite uma abertura exclusiva (O_EXCL): logo a seguir ao partx o udev ainda está a examinar a partição e o mkfs.ext4 recusava com 'aparenta estar em uso pelo sistema' (EBUSY transitório apanhado pelo teste F11; nunca se usa -F -F). Ensaiado no anfitrião numa cópia da tabela da ISO num disco de 8 GiB: os 440 bytes de arranque e os setores 2-19 ficam intactos, só a GPT muda, e o teste F11 persistencia-pen confirma que a pen continua a arrancar em BIOS e em UEFI com a partição nova a ser usada. Deixa-se 1 MiB livre no fim do disco para a GPT de reserva (45 setores com 176 entradas). Só se propõe se o dispositivo da ISO for um disco inteiro com tabela gpt ou dos (nunca um CD), sem partições já a seguir à imagem, e com pelo menos 1 GiB livre; numa tabela MBR só com menos de quatro partições.

## Tipo "ficheiro": ianinja-dados.img numa partição existente
_2026-11-13 14:08_

Monta a partição (ntfs3 para NTFS; exfat; vfat; ext4), cria a pasta /ianinja e reserva o ficheiro com fallocate (ext4 e ntfs3 reservam sem escrever); em FAT/exFAT, onde o fallocate não existe, o ficheiro é escrito por blocos de 16 MiB com progresso. Em FAT32 o máximo é 4095 MiB (limite do sistema de ficheiros); nos outros, o espaço livre menos 512 MiB de margem; o sugerido é um quarto do livre entre 8 GiB e 64 GiB (ou o máximo, se for menor). Depois: losetup, mkfs.ext4 -F -L IANINJA-DADOS no loop, montagem e cópia da camada de escrita. Uma partição que já tenha /ianinja/ianinja-dados.img não é proposta de novo. Um NTFS que o Windows deixou marcado como em uso (hibernação ou arranque rápido) não monta para escrita com o ntfs3: é ignorado no listar com uma nota no stderr, e no arranque é procurado com ro,force (seguro para ler) mas nunca escrito — o initramfs avisa "desligue o Windows por completo, sem hibernação nem arranque rápido" e segue em tmpfs.

## Tipo "particao" e o ia-criar-persistencia como invólucro
_2026-11-13 14:08_

O criar particao faz wipefs -a e mkfs.ext4 -F -L IANINJA-DADOS na partição (ou disco sem partições) e exige --confirmo-apagar. As verificações de segurança são as do listar, e só se cria o que o listar propõe: nunca o dispositivo da ISO nem as suas partições (EFI, HFS+, Gap0/1 — ficam dentro do isosize), nada montado, nenhuma swap ativa, nenhum CD nem loop, partições EFI (GUID C12A7328… / tipo 0xEF), MSR, Windows RE, BitLocker ("BitLocker" no lsblk), LUKS, nem uma partição NTFS com uma pasta Windows (um Windows instalado nunca é proposto para formatar; no tipo ficheiro é o destino "Disco do Windows", sem o alterar). O antigo scripts/sistema/ia-criar-persistencia (instalado pela F9) passou a ser um invólucro: valida o argumento e chama ianinja-persistencia criar particao:<dev> --confirmo-apagar, depois de mostrar o disco e exigir a resposta SIM em maiúsculas; a mensagem de ajuda aponta para o listar/criar sem apagar nada.

## Migração da camada de escrita atual
_2026-11-13 14:08_

Depois de criar o destino copia-se /run/live/rw/upper (a camada de escrita em tmpfs desta sessão: a conta acabada de criar, a senha do Wi-Fi, etc.) para <destino>/overlay/upper com cp -a do coreutils, que preserva dono, modos, datas, xattrs (incluindo os trusted.overlay.opaque dos diretórios opacos — o cp corre como root), ACLs, ligações físicas e os whiteouts (dispositivos de carácter 0/0); confirmado no anfitrião com um overlay de teste (whiteout, opaque dir, hardlink, ACL, xattr de utilizador) e remontado com o destino como upper. Não se usa rsync porque não está no LFS. /tmp e /var/tmp da cópia são esvaziados; overlay/work fica vazio; um LEIA-ME.txt explica a pasta; sync no fim. O progresso (40–90 %) é estimado pela ocupação do destino durante a cópia. Se a persistência já estiver ativa não há nada a copiar (e o criar recusa).

## Arranque: ntfs3 e exfat como módulos no initramfs, sem recompilar o kernel
_2026-11-13 14:08_

O kernel 6.16.1 (configuração base do Arch, F7) tem ext4, vfat, loop, overlay e as partições GPT/MBR embutidos (=y) mas CONFIG_NTFS3_FS=m e CONFIG_EXFAT_FS=m. Recompilar o kernel obrigava a refazer a F7 e tudo o que se segue; em vez disso o initramfs (scripts/f09-live.sh) passou a levar o insmod (kmod) e os dois módulos descomprimidos dos .ko.zst (ntfs3 ≈ 0,5 MB, exfat ≈ 0,2 MB), que o /init carrega logo no início. O /init (scripts/live-init.sh) procura, por esta ordem, um ext4 com o rótulo IANINJA-DADOS (como antes) e depois /ianinja/ianinja-dados.img em cada partição NTFS/exFAT/FAT/ext4 montada só-leitura; se o encontrar monta a partição para escrita, liga o ficheiro a um loop e monta o ext4 interior; falhas dão um AVISO e tmpfs. Uma pen gravada em modo imagem passou a ser montada através de um dispositivo loop só-leitura sobre o disco inteiro (a montagem direta reclamava o disco em exclusivo e o kernel recusava depois montar a partição IANINJA-DADOS criada na mesma pen). O /init deixa /run/live/iso-dev (dispositivo real da ISO) e /run/live/dados-info (tipo, dispositivo, ficheiro, loop) para o estado do backend; o disco de dados fica em /mnt/dados e a partição hospedeira do ficheiro em /mnt/dados-disco. "persistencia=nao"/"semdados" continuam a desligar tudo.

## Reiniciar sem logind nem ConsoleKit: ação "reiniciar" do aplicar
_2026-11-13 14:08_

O sistema não tem logind nem ConsoleKit, por isso o LightDM.get_can_restart() do greeter devolve False e o LightDM.restart() não faz nada (o teste F11 regista o valor como INFO). O aplicar ganhou a ação "reiniciar" (sudo -n /usr/libexec/ianinja-assistente/aplicar reiniciar), que só é permitida depois de persistencia-criar ter terminado com OK neste arranque: o contas.py escreve o marcador /run/ianinja-persistencia/criado (em /run, não sobrevive ao reinício) e o reiniciar recusa sem ele; responde "OK" e lança shutdown -r now numa sessão própria. A regra do sudoers não mudou (o lightdm só pode correr o aplicar, que filtra as ações: estado, criar, experimentar, persistencia-estado, persistencia-listar, persistencia-criar, reiniciar; nunca --raiz nem repor). O greeter continua sem poder chamar o backend diretamente (persistencia-verificar confirma).

## Testes F11: persistencia-ficheiro e persistencia-pen (scripts/teste-persistencia.exp)
_2026-11-13 14:08_

Dois modos novos que chamam o backend pelo mesmo caminho do greeter (su lightdm -c "sudo -n aplicar persistencia-listar / persistencia-criar com JSON no stdin / reiniciar") em vários arranques. persistencia-ficheiro (5 critérios: listar, criar, reiniciar, initramfs/estado, dados): disco virtio de 4 GiB feito no anfitrião com GPT e uma partição NTFS (mkfs.ntfs do ntfs-3g, acrescentado à lista de pacotes do anfitrião em f00-host.sh com o exfatprogs; sem ele, exFAT ou FAT32) a fazer de disco do Windows; 1.º arranque grava um ficheiro em /home/ninja e uma ligação Wi-Fi do NetworkManager com senha, cria o ficheiro (1536 MiB) — que tem de receber a cópia desses dados — e reinicia pelo aplicar (o que se altera depois do criar e antes de reiniciar perde-se, por isso o assistente pede logo para reiniciar); 2.º arranque confirma a mensagem do initramfs, estado ativo/tipo ficheiro e os dados. persistencia-pen (8 critérios: os mesmos 5 mais estado, dados e Xorg/greeter no arranque UEFI): imagem esparsa de 8 GiB com a ISO no início ligada como pen USB (qemu-xhci + usb-storage); cria a partição a seguir à imagem e confirma nos 2.º (BIOS) e 3.º (UEFI, OVMF) arranques a persistência, os dados e o Xorg/greeter. O critério 11 antigo (ext4 por rótulo num disco virtio) e os testes pen-*/disco-* ficam iguais e continuam a passar com o /init novo.

## Riscos conhecidos
_2026-11-13 14:08_

Secure Boot: a ISO não é assinada (GRUB e kernel próprios); com Secure Boot ligado o PC não arranca a pen, com ou sem persistência — é preciso desligá-lo no firmware (não muda com este bloco). BitLocker: uma partição cifrada aparece no lsblk como "BitLocker" e nunca é proposta (nem ficheiro nem partição); o disco do Windows com BitLocker ligado não serve de destino "ficheiro" — fica a pen ou outra partição. Arranque rápido/hibernação do Windows: o NTFS fica marcado como em uso e o ntfs3 recusa a escrita — o ficheiro não é criado (listar ignora a partição) e, se já existir, o arranque avisa e segue em tmpfs. Pens com tabela MBR (ISO gravada por ferramentas que reescrevem a tabela): o tipo pen usa "83" e só com menos de quatro partições.

## initramfs: persistência em ficheiro (NTFS/exFAT/FAT/ext4) e na própria pen
_2026-11-13 14:08_

Para o assistente de 1.º arranque poder guardar os dados sem formatar nada (scripts/apps/persistencia/CONTRATO.md, bloco 11 da F8e), o /init (scripts/live-init.sh) procura agora, depois do ext4 com o rótulo IANINJA-DADOS, o ficheiro /ianinja/ianinja-dados.img em cada partição NTFS (driver ntfs3), exFAT, FAT ou ext4: monta-a só-leitura para procurar (uma NTFS que o Windows deixou marcada como em uso — hibernação ou arranque rápido — é procurada com ro,force, que é seguro para ler), e se o ficheiro existir monta-a para escrita (nunca com force), liga o ficheiro a um dispositivo loop e monta o ext4 interior como camada de escrita; se a escrita for recusada avisa ('NTFS marcado como em uso: desligue o Windows por completo') e segue em tmpfs. O ntfs3 e o exfat são módulos no kernel 6.16.1 (base Arch: CONFIG_NTFS3_FS=m, CONFIG_EXFAT_FS=m; vfat, ext4 e loop são =y): em vez de recompilar o kernel (F7 e tudo o que se segue), o initramfs passou a levar o insmod (kmod) e os dois módulos descomprimidos (ntfs3 ~0,5 MB, exfat ~0,2 MB), carregados logo no início. Uma pen gravada em modo imagem passa a ser montada através de um dispositivo loop só-leitura sobre o disco inteiro (losetup -r /dev/sda): a montagem direta reclamava o disco em exclusivo e o kernel recusava depois montar qualquer partição do mesmo disco (bd_may_claim), o que impedia a partição IANINJA-DADOS criada a seguir à imagem na própria pen (tipo 'pen' do assistente). A mensagem 'volume encontrado em /dev/sda' continua a indicar o disco real (os testes F11 leem-na); o dispositivo real fica em /run/live/iso-dev e o tipo/dispositivo do disco de dados em /run/live/dados-info (lidos pelo ianinja-persistencia estado). Mensagens: 'persistência: IANINJA-DADOS (/dev/sdb1)' para partições (iguais às de antes) e 'persistência: IANINJA-DADOS (ficheiro ianinja/ianinja-dados.img em /dev/nvme0n1p3)' para o ficheiro; a partição hospedeira fica em /mnt/dados-disco.

## Testes F11: persistência em ficheiro (disco NTFS) e na própria pen
_2026-11-13 14:14_

Dois modos novos, com scripts/teste-persistencia.exp e os ids 'persistencia-ficheiro' (5 critérios) e 'persistencia-pen' (8 critérios), que chamam o backend pelo MESMO caminho do greeter (su lightdm -> sudo -n /usr/libexec/ianinja-assistente/aplicar persistencia-listar / persistencia-criar com JSON no stdin / reiniciar). persistencia-ficheiro: um disco virtio de 4 GiB feito no host com tabela GPT e uma partição NTFS (mkfs.ntfs do ntfs-3g; sem ele, exFAT com mkfs.exfat ou FAT32 com mkfs.vfat — o teste lê o id proposto pelo listar), como o disco do Windows; no 1.º arranque (BIOS, persistência desligada) o listar tem de propor ficheiro:/dev/vdaN; gravam-se um ficheiro em /home/ninja (dono ninja) e uma ligação Wi-Fi do NetworkManager (nmcli con add, com senha) ANTES do criar, porque o criar copia a camada de escrita tal como está nesse momento (o que se altera depois perde-se até reiniciar — por isso o assistente reinicia logo); o criar (1536 MiB) tem de dar PROGRESSO ... 100 e OK, e o 'aplicar reiniciar' reinicia (só permitido depois do OK; com -no-reboot o QEMU termina); no 2.º arranque o initramfs tem de dizer 'persistência: IANINJA-DADOS (ficheiro ianinja/ianinja-dados.img em /dev/vdaN)', o estado --json tem ativo=true e tipo=ficheiro, e o ficheiro e a ligação (com a senha no .nmconnection) têm de lá estar. persistencia-pen: imagem de 8 GiB (esparsa) com a ISO gravada no início, ligada como pen USB (qemu-xhci + usb-storage, bootindex=0), como uma pen gravada em modo imagem; o listar tem de propor pen:/dev/sda (recomendado), o criar cria a partição /dev/sda5 no espaço a seguir à imagem (sfdisk: cópia da GPT movida para o fim da pen + partição nova; partx; mkfs.ext4), e nos 2.º (BIOS) e 3.º (UEFI, OVMF) arranques o initramfs tem de usar /dev/sda5 e os dados têm de lá estar; no UEFI confirma-se ainda que o Xorg e o greeter arrancam (o arranque BIOS e UEFI da pen continua a funcionar com a tabela de partições alterada). As imagens ficam em logs/ e são apagadas no fim (também se o script sair a meio). Os testes antigos (critério 11 com o ext4 por rótulo num disco virtio, pen-*/disco-*) ficam iguais.

## F8e bloco 12 — driver NVIDIA: /usr/sbin no PATH do instalar-driver-nvidia
_2026-11-19 17:56_

No teste em hardware real (RTX 5060, GB206) o atalho "Instalar driver NVIDIA" parava logo com "falta o comando modprobe": no LFS o modprobe, o depmod e o modinfo estão em /usr/sbin, e o /etc/profile só acrescenta /usr/sbin ao PATH do root; o terminal aberto pelo menu também não passa por um shell de login. O comando passa a acrescentar /usr/sbin ao próprio PATH (e verifica também cc e modinfo antes de descarregar 400 MB). Além disso /etc/profile.d/sbin.sh põe /usr/sbin no PATH de todos os utilizadores, como nas distribuições comuns.

## F8e bloco 12 — áudio: WirePlumber do BLFS e lançador do PipeWire
_2026-11-19 17:56_

O PipeWire 1.4.7 foi instalado no bloco 5 só como biblioteca (para o xdg-desktop-portal), sem gestor de sessão e sem nada que o arrancasse: o OBS (Flatpak) não mostrava nenhum dispositivo em "Captura de entrada de áudio (PulseAudio)" e o microfone não funcionava em nenhuma aplicação (o ALSA por omissão já apontava para o PipeWire, que não estava a correr). Instala-se o Lua 5.4.8 e o WirePlumber 0.5.10 pelas páginas do BLFS 12.4 (uma tentativa anterior compilava o 0.5.3 do GitLab sem SHA-256 fixado e foi descartada). Da página do WirePlumber usa-se o pipewire-launcher.sh e o /etc/xdg/autostart/pipewire.desktop, com a espera corrigida (o ciclo do livro nunca esperava) e sem o sed em /etc/pulse/client.conf (não há PulseAudio instalado). O lançador arranca pipewire, wireplumber e pipewire-pulse (servidor PulseAudio usado pelo OBS, navegadores, Discord, Zoom).

## F8e bloco 12 — áudio Bluetooth: SBC e PipeWire recompilado
_2026-11-19 17:56_

O plugin spa bluez5 não tinha sido compilado (faltava o SBC): headsets Bluetooth emparelhavam mas não davam som. Instala-se o SBC 2.1 e recompila-se o PipeWire (mesma página e mesmas opções).

## F8e bloco 12 — GNOME Keyring (org.freedesktop.secrets)
_2026-11-19 17:56_

O GitHub Desktop (Flatpak) falhava com "The name org.freedesktop.secrets was not provided by any .service files": não havia serviço de chaveiro. Instala-se o GNOME Keyring 48.0 do BLFS (o Gcr 3 já existia) com -D manpage=false (sem docbook-xsl). O serviço D-Bus é ativado a pedido; o PAM do LightDM desbloqueia o chaveiro "login" com a senha da sessão (pam_gnome_keyring auth + session auto_start; passwd com use_authtok) e os autostart secrets/pkcs11 passam a incluir o Xfce.

## F8e bloco 12 — v4l-utils
_2026-11-19 17:56_

v4l2-ctl (e v4l2grab) para diagnosticar câmaras UVC como a Razer Kiyo X (formatos, resoluções, taxas de fotogramas). A câmara já era detetada (uvcvideo) e listada pelo OBS.

