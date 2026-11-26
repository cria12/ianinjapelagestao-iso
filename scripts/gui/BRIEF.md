# F8d — Interface gráfica (Xorg + Xfce, aspeto estilo macOS) — instruções para agentes

## Contexto
- Distribuição "ianinjapelagestao": LFS 12.4 (System V) + BLFS 12.4, entregue como ISO live.
  Já construída e testada SEM interface gráfica (só consola). Agora acrescenta-se a etapa F8d.
- Tudo vive no WSL2 (Ubuntu 24.04), utilizador root, em `/root/ianinjapelagestao`
  (no Windows: `\\wsl$\Ubuntu-24.04\root\ianinjapelagestao` — use este caminho com Read/Edit/Write).
- Correr comandos: `MSYS_NO_PATHCONV=1 wsl.exe -u root --exec bash -c '...'` (a partir do Git Bash).
  NÃO use `wsl.exe -- bash -lc` (a expansão de `$` parte-se).
- Livro BLFS local (HTML): `/root/ianinjapelagestao/book/blfs/<cap>/<pagina>.html`.
- Sistema-alvo montado em `/mnt/lfs` (imagem loop). Só LEITURA para si (ls/cat para ver o que já
  está instalado). NÃO compile, NÃO faça chroot que altere nada, NÃO mexa em progresso.json,
  logs/, run-all, nem em /mnt/lfs.
- Idioma de tudo o que escrever (comentários, motivos, decisões): português de Portugal, no estilo
  dos ficheiros existentes (ver `scripts/book-overrides.txt`, `scripts/f08-blfs.sh`, `docs/DECISOES.md`).

## Como uma página do livro vira um passo da build
1. `scripts/gen-scripts.py blfs ../book/blfs <spec>` transcreve cada `<pre class="userinput|root">`
   da página para `scripts/gen/blfs/<spec>.sh` (blocos numerados 1..n; veja o ficheiro gerado).
   `<spec>` = `cap/pagina` ou `cap/pagina@secao` (só uma secção de páginas com vários pacotes,
   ex.: `general/python-modules@Mako`, `x/x7driver@libinput`).
2. Overrides por bloco (formato igual ao de `scripts/book-overrides.txt`):
   `blfs/<spec>  <skip|test|must|replace>  <n[,n...]>  # motivo`
   - skip: não corre (documentação que precisa de ferramentas ausentes — Doxygen, gtk-doc,
     Sphinx, texlive, docbook-xsl/xmlto, asciidoc...; alternativas; exemplos com <placeholders>;
     comandos interativos; testes que precisam de um servidor X/sessão D-Bus a correr; passos
     "se tiver instalado X" quando X não está instalado).
   - test: test suite — corre mas falhas não param a build (blocos com make check/ninja test
     são detetados sozinhos; marque test os que escapem à deteção).
   - must: força "normal" um bloco detetado como teste por engano.
   - replace: substitui pelo conteúdo de `scripts/replace/blfs-<spec com / trocado por ->.<n>.sh`
     (ex.: `scripts/replace/blfs-x-xorg7.1.sh`). Use para trocar <placeholders> por valores reais.
   Cada agente escreve SÓ no seu ficheiro `scripts/book-overrides.d/gui-NN-<nome>.txt`
   (é lido automaticamente). Exemplo já feito: `scripts/book-overrides.d/gui-00-xorg7.txt`.
3. Execução: no host, `blfs-fetch.py fetch` descarrega o tarball principal (+ patches obrigatórios,
   + adicionais escolhidos com `--extra TEXTO`) e verifica o MD5 do livro; depois, no chroot,
   `run-blfs.sh <spec> <tarball>` extrai em /sources, entra no diretório, corre o script gerado
   com `bash -e`, e apaga o diretório. Páginas sem tarball usam `-` e correm em /sources.
   - Corre-se como ROOT no chroot (não há sudo/utilizador; `as_root cmd` = `cmd`, ver
     `scripts/blfs-env.sh`, que também carrega /etc/profile.d/xorg.sh e rustc.sh).
   - XORG_PREFIX=/usr. MAKEFLAGS=-j12. PATH=/usr/bin:/usr/sbin. Sem servidor X, sem D-Bus a correr.
   - O chroot NÃO tem rede, exceto nos passos marcados com rede (wrapper `com_rede`).
4. No script da etapa (`scripts/f08c-gui.sh`, escrito pelo coordenador) cada passo é uma linha
   `"id|comando"` com estes comandos disponíveis:
   - `pacote <spec> [--extra TEXTO]...` — download no host + build no chroot
   - `pacote_rede <spec> ...` — igual, mas com DNS no chroot (página que descarrega coisas)
   - `pagina_config <spec>` — página sem tarball (só configuração)
   - `pagina_rede <spec>` — página sem tarball que descarrega no chroot (ex.: x7lib, x7app,
     x7font: o livro faz `wget -i-` + `md5sum -c` de uma lista; ficam verificados pelo MD5 do livro)
   - ou o nome de uma função bash própria que defina em `scripts/gui/funcoes-NN.sh`
     (funções correm sob `corre_passo`: sem errexit — termine cada comando com `|| return 1`;
     use `in_chroot "..."` para correr no chroot e `$LFS/...` para ficheiros do alvo).

## Já instalado (não repetir)
- LFS 12.4 completo (Cap. 5-8: inclui Python 3.13.7, Meson, Ninja, Perl, OpenSSL, Expat, XML::Parser,
  zlib, bzip2, xz, zstd, libffi, gperf, Flit-core, Wheel, Setuptools, Packaging, Jinja2, MarkupSafe,
  pkgconf, gettext, bison, flex, intltool, Systemd-udev 257.8, kmod, Linux-PAM só via BLFS).
- BLFS (F8, F8b, F8c): ver `scripts/gui/feitas.txt` (CMake 4.1.0 da F8b; F8c "Drivers e firmware": linux-firmware, microcódigo, libnl, wpa_supplicant, iw, alsa-lib, alsa-utils).
- Lista completa e ordenada da F8d: `scripts/gui/ordem.txt` (o que vem antes de uma página já
  estará instalado quando ela correr; dependências OPCIONAIS fora dessa lista NÃO estão).

## Entregáveis de cada agente de páginas (prefixo NN atribuído)
1. `scripts/book-overrides.d/gui-NN-<nome>.txt` e eventuais `scripts/replace/blfs-*.sh`.
2. `scripts/gui/passos-NN.txt`: uma linha por passo, pela ordem de `ordem.txt`, no formato
   `id|comando` (id curto: nome do pacote; ex.: `freetype2-harfbuzz|pacote general/freetype2`).
3. `scripts/gui/funcoes-NN.sh` (se precisar de funções próprias; pode não existir).
4. `scripts/gui/decisoes-NN.txt`: desvios ao livro, um por parágrafo, com título
   (`## Título` + texto), no estilo de docs/DECISOES.md (escolhas de opções, blocos omitidos e porquê).
5. Para verificar: corra `python3 scripts/gen-scripts.py blfs ../book/blfs <specs>` (a partir de
   `scripts/`) e leia os `gen/blfs/*.sh` resultantes — confirme que cada página fica com comandos
   corretos e completos para um build não interativo como root. Corra também
   `python3 scripts/blfs-fetch.py list ../book/blfs <spec>` para ver downloads/patches/adicionais.
6. Relatório final curto: o que fez, pontos de risco/dúvidas, e alterações que precisaria nos
   ficheiros partilhados (gen-scripts.py, blfs-fetch.py, run-blfs.sh, blfs-env.sh, lib.sh) —
   NÃO edite esses ficheiros partilhados; descreva a alteração no relatório.
