#!/bin/bash
# F8b — Inteligência artificial local (só CPU): CMake (BLFS 12.4), llama.cpp e um modelo de
# linguagem pequeno (Qwen2.5-1.5B-Instruct, GGUF Q4_K_M), mais os comandos ia-chat, ia-perguntar,
# ia-servidor, ia-baixar e ia-info e o chat automático na consola local do utilizador ninja.
# Downloads no host para $LFS/sources (verificados por SHA-256 fixado aqui); compilação no chroot.
set -euo pipefail
source /root/ianinjapelagestao/scripts/lib.sh
estado_init
[ "$(etapa_estado F8b)" = ok ] && exit 0
montar_lfs
montar_kernfs > /dev/null
etapa_inicio F8b

S=$P/scripts
BLFS=$P/book/blfs
FETCH="python3 $S/blfs-fetch.py"

# --- versões fixadas
LLAMA_TAG=b12121                         # release do llama.cpp de 2026-11-05
LLAMA_TB=llama.cpp-$LLAMA_TAG.tar.gz
LLAMA_URL=https://github.com/ggml-org/llama.cpp/archive/refs/tags/$LLAMA_TAG.tar.gz
LLAMA_SHA256=0b6fbcaa41a51782ccb3454ae6a1cf6b2f7d0530e8dfe6d2f9de2df8c916a33a

# Modelo: repositório oficial Qwen/Qwen2.5-1.5B-Instruct-GGUF, revisão fixada (commit do HF);
# SHA-256 = oid do ponteiro Git LFS publicado pelo Hugging Face (confirmado com sha256sum)
MODELO_REV=91cad51170dc346986eccefdc2dd33a9da36ead9
MODELO=qwen2.5-1.5b-instruct-q4_k_m.gguf
MODELO_URL=https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/$MODELO_REV/$MODELO
MODELO_SHA256=6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e
MODELO_TAM=1117320736
LICENCA_URL=https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/$MODELO_REV/LICENSE
LICENCA_SHA256=832dd9e00a68dd83b3c3fb9f5588dad7dcf337a0db50f7d9483f310cd292e92e
LICENCA_TB=qwen2.5-1.5b-instruct-gguf-LICENSE

# Página do CMake transcrita do livro (bloco 1 substituído, ver book-overrides.txt)
python3 $S/gen-scripts.py blfs $BLFS general/cmake > /dev/null
mkdir -p $LFS/sources/ianinja/gen/blfs/general $LFS/sources/ianinja/ia
cp $S/gen/blfs/general/cmake.sh $LFS/sources/ianinja/gen/blfs/general/
cp $S/run-blfs.sh $LFS/sources/ianinja/
cp $S/ia/* $LFS/sources/ianinja/ia/
chmod -R a+rX $LFS/sources/ianinja

# --- funções (correm dentro de corre_passo: errexit não se aplica, por isso || return 1)

# pacote <cap/pagina> — download+MD5 do livro no host, build no chroot (como na F8)
pacote() {
  local page=$1 tb; shift
  $FETCH fetch $BLFS $LFS/sources "$page" "$@" || return 1
  tb=$($FETCH tarball $BLFS "$page") || return 1
  in_chroot "bash /sources/ianinja/run-blfs.sh $page $tb"
}

# baixar <url> <ficheiro em $LFS/sources> <sha256> — reutiliza se já existir com a soma certa
baixar() {
  local url=$1 f=$LFS/sources/$2 sha=$3
  if [ -f "$f" ] && echo "$sha  $f" | sha256sum -c --status; then
    echo "já descarregado e verificado: $f"; return 0
  fi
  rm -f "$f"
  wget -nv -c -O "$f.part" "$url" || return 1
  echo "$sha  $f.part" | sha256sum -c || { echo "SHA-256 errado em $f.part (apagado)"; rm -f "$f.part"; return 1; }
  mv -v "$f.part" "$f"
}

llama_fonte() { baixar $LLAMA_URL $LLAMA_TB $LLAMA_SHA256; }

llama() {
  in_chroot "bash /sources/ianinja/ia/compilar-llama.sh $LLAMA_TB $LLAMA_TAG" || return 1
  # o diretório de fontes é apagado pelo script; confirmar
  [ ! -d $LFS/sources/llama.cpp-$LLAMA_TAG ] || return 1
}

modelo_baixar() {
  local df; df=$(df -Pk $LFS/sources | awk 'NR==2{print $4}')
  [ $((df*1024)) -gt $((MODELO_TAM*3)) ] || { echo "pouco espaço em $LFS ($df KiB)"; return 1; }
  baixar $MODELO_URL $MODELO $MODELO_SHA256 || return 1
  baixar $LICENCA_URL $LICENCA_TB $LICENCA_SHA256 || return 1
  [ "$(stat -c %s $LFS/sources/$MODELO)" = $MODELO_TAM ] || return 1
  ls -la $LFS/sources/$MODELO
}

modelo_instalar() {
  local d=$LFS/usr/share/ia/modelos doc=$LFS/usr/share/doc/qwen2.5-1.5b-instruct
  install -v -d -m755 $d $doc || return 1
  install -v -m644 $LFS/sources/$MODELO $d/$MODELO || return 1
  echo "$MODELO_SHA256  $d/$MODELO" | sha256sum -c || return 1
  ln -sfnv $MODELO $d/predefinido.gguf || return 1
  install -v -m644 $LFS/sources/$LICENCA_TB $doc/LICENSE || return 1
  cat > $doc/README.pt <<EOF || return 1
Modelo: Qwen2.5-1.5B-Instruct (Alibaba Cloud / equipa Qwen), quantização GGUF Q4_K_M
Origem: https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF (revisão $MODELO_REV)
Ficheiro: /usr/share/ia/modelos/$MODELO ($MODELO_TAM bytes)
SHA-256: $MODELO_SHA256
Licença: Apache License 2.0 (ver LICENSE neste diretório)
EOF
}

comandos() {
  local c
  install -v -d -m755 $LFS/usr/share/ia || return 1
  install -v -m644 $S/ia/ia-comum.sh $S/ia/autoarranque.sh $LFS/usr/share/ia/ || return 1
  for c in ia-chat ia-perguntar ia-servidor ia-baixar ia-info; do
    install -v -m755 $S/ia/$c $LFS/usr/bin/$c || return 1
  done
  # bootscript ao estilo do BLFS; NÃO ativado (sem links S* nos níveis de execução)
  install -v -m754 $S/ia/ia-servidor.init $LFS/etc/rc.d/init.d/ia-servidor || return 1
  install -v -m644 $S/ia/ia-servidor.conf $LFS/etc/sysconfig/ia-servidor || return 1
  rm -fv $LFS/etc/rc.d/rc?.d/S*ia-servidor || return 1
  # modelos descarregados pelo utilizador: grupo ninja com escrita (setgid)
  in_chroot "install -v -d -m755 /var/lib/ia && install -v -d -o root -g ninja -m2775 /var/lib/ia/modelos" || return 1
  in_chroot "bash -n /usr/bin/ia-chat && bash -n /usr/bin/ia-perguntar && bash -n /usr/bin/ia-baixar && bash -n /usr/bin/ia-info && bash -n /usr/bin/ia-servidor && bash -n /etc/rc.d/init.d/ia-servidor && bash -n /usr/share/ia/ia-comum.sh && bash -n /usr/share/ia/autoarranque.sh"
}

# Chat automático no login do ninja numa consola virtual (linha acrescentada uma só vez)
MARCA='# ianinjapelagestao: chat de IA automático nas consolas tty1-tty6 (desativar: IA_SEM_CHAT=1)'
autoarranque() {
  local f
  for f in $LFS/home/ninja/.bash_profile $LFS/etc/skel/.bash_profile; do
    [ -f "$f" ] || { echo "falta $f"; return 1; }
    if ! grep -qF "$MARCA" "$f"; then
      sed -i '/^# End ~\/.bash_profile/d' "$f" || return 1
      printf '%s\n[ -r /usr/share/ia/autoarranque.sh ] && . /usr/share/ia/autoarranque.sh\n\n# End ~/.bash_profile\n' "$MARCA" >> "$f" || return 1
    fi
    tail -4 "$f"
  done
  # o root nunca arranca o chat
  ! grep -q autoarranque $LFS/root/.bash_profile 2> /dev/null
}

verificacao() {
  in_chroot 'set -e
falha() { echo "FALTA: $*"; exit 1; }
for c in cmake llama-cli llama-completion llama-server llama-bench ia-chat ia-perguntar ia-servidor ia-baixar ia-info; do
  p=$(type -P $c) || falha "programa $c"
  printf "%-18s %s\n" "$c" "$p"
done
cmake --version | head -1
llama-cli --version 2>&1 | grep -v "^$"
ls /usr/lib/ggml/libggml-cpu-*.so > /dev/null 2>&1 || ls /usr/lib/libggml-cpu*.so > /dev/null || falha "backend CPU do ggml"
ls /usr/lib/ggml/ 2>/dev/null || true
test -L /usr/share/ia/modelos/predefinido.gguf || falha "symlink predefinido.gguf"
test -s "$(readlink -f /usr/share/ia/modelos/predefinido.gguf)" || falha "modelo predefinido"
test -x /etc/rc.d/init.d/ia-servidor || falha "bootscript ia-servidor"
if ls /etc/rc.d/rc?.d/S*ia-servidor 2>/dev/null; then falha "(não devia haver) arranque automático do ia-servidor"; fi
grep -q autoarranque /home/ninja/.bash_profile || falha "autoarranque no ~/.bash_profile do ninja"
grep -q autoarranque /etc/skel/.bash_profile || falha "autoarranque em /etc/skel/.bash_profile"
echo "--- ia-perguntar \"Responde apenas com a palavra OK.\""
t0=$(date +%s.%N)
r=$(ia-perguntar "Responde apenas com a palavra OK." < /dev/null)
t1=$(date +%s.%N)
echo "resposta: [$r]"
echo "tempo: $(echo "$t1 - $t0" | bc) s"
[ -n "$r" ] || falha "resposta vazia do ia-perguntar"
echo "--- ia-info"
ia-info'
}

PASSOS=(
  "cmake|pacote general/cmake"
  "llama-fonte|llama_fonte"
  "llama|llama"
  "modelo-baixar|modelo_baixar"
  "modelo-instalar|modelo_instalar"
  "comandos|comandos"
  "autoarranque|autoarranque"
  "verificacao|verificacao"
)
TOTAL=${#PASSOS[@]}
n=0
for linha in "${PASSOS[@]}"; do
  n=$((n+1))
  nome=${linha%%|*}
  read -r -a cmd <<< "${linha#*|}"
  corre_passo "f8b-$nome" "$P/logs/f8b-$nome.log" "${cmd[@]}" \
    || { etapa_fim F8b falhou "falhou em $nome ($n/$TOTAL) — ver logs/f8b-$nome.log"; exit 1; }
  etapa_nota F8b "$n/$TOTAL — último: $nome"
done

variante=$(grep '^variantes CPU' $LFS/usr/share/ia/compilacao.txt | cut -d' ' -f3 || true)
tempo=$(grep -o '^tempo: .*' $P/logs/f8b-verificacao.log | tail -1 | cut -d' ' -f2 || true)

# --- Decisões
decisao "IA: llama.cpp $LLAMA_TAG (só CPU)" \
"O motor de inferência é o llama.cpp, release $LLAMA_TAG (tarball do GitHub $LLAMA_URL, SHA-256 $LLAMA_SHA256 fixado em scripts/f08b-ia.sh). Compilado no chroot com CMake 4.1.0 (página do BLFS) e Ninja, em Release, bibliotecas partilhadas em /usr/lib, programas em /usr/bin (llama-cli, llama-completion, llama-server, llama-bench e restantes ferramentas). OpenMP ativo (libgomp do GCC 15.2.0). Testes e exemplos do llama.cpp não são compilados. O diretório de fontes é apagado no fim. Pequena alteração às fontes: no chat do llama-cli, '/sair' é aceite como sinónimo de '/exit' (sed em tools/cli/cli-context.cpp)."
decisao "IA: variantes do backend CPU (GGML_BACKEND_DL + GGML_CPU_ALL_VARIANTS)" \
"A ISO tem de correr em qualquer PC x86_64, mas compilar com -march=native (GGML_NATIVE, por omissão) prenderia o binário ao CPU do host de construção (AVX-512 noutros CPUs dá 'Illegal instruction'), e compilar só para a linha de base x86-64 (SSE2) tornaria a inferência várias vezes mais lenta. Por isso usou-se GGML_NATIVE=OFF, GGML_BACKEND_DL=ON e GGML_CPU_ALL_VARIANTS=ON: são geradas bibliotecas libggml-cpu-<variante>.so (x64, sse42, sandybridge, haswell/AVX2, skylakex/AVX-512, icelake, alderlake/AVX-VNNI, sapphirerapids/AMX, zen4, ...) em /usr/lib/ggml (GGML_BACKEND_DIR), e o ggml escolhe no arranque a melhor que o CPU suporta. Variante efetivamente compilada: ${variante:-?} (se a combinação falhasse, o script recorre à versão portátil x86-64 e regista-o em /usr/share/ia/compilacao.txt)."
decisao "IA: cURL/HTTPS e interface web do llama.cpp" \
"Pedia-se LLAMA_CURL=ON, mas no llama.cpp $LLAMA_TAG essa opção está obsoleta (o CMake só emite um aviso e ignora-a): os downloads de modelos (-hf/-mu) usam o cliente HTTP interno (cpp-httplib) com OpenSSL, ativado com LLAMA_OPENSSL=ON — o OpenSSL do LFS é usado. O ia-baixar usa o cURL do sistema (F8). A interface web do llama-server não é incluída: obtê-la exigiria npm (LLAMA_BUILD_UI) ou descarregar durante a compilação um pacote pré-gerado do Hugging Face sem soma fixada (LLAMA_USE_PREBUILT_UI), e o chroot não tem rede; a API compatível com a OpenAI (/v1/chat/completions, /v1/completions, /v1/models, /health) funciona normalmente."
decisao "IA: CMake do BLFS com bibliotecas internas" \
"O CMake 4.1.0 segue a página do BLFS (URL e MD5 do livro). As dependências recomendadas libarchive, libuv e nghttp2 não estão instaladas, por isso o bootstrap usa as cópias incluídas no CMake (--no-system-libarchive/--no-system-libuv/--no-system-nghttp2, além das jsoncpp/cppdap/librhash que o livro já indica); cURL, zlib, bzip2, xz, zstd e expat são as do sistema. Acrescentou-se --parallel=\$(nproc) ao bootstrap. Opcionais (Qt, sphinx, gfortran...) não instalados; a test suite (bin/ctest, só no texto da página) não foi corrida."
decisao "IA: modelo predefinido Qwen2.5-1.5B-Instruct Q4_K_M (Apache 2.0)" \
"Modelo incluído na ISO: $MODELO do repositório oficial Qwen/Qwen2.5-1.5B-Instruct-GGUF no Hugging Face (revisão $MODELO_REV), $MODELO_TAM bytes, SHA-256 $MODELO_SHA256 (oid do ponteiro Git LFS publicado pelo Hugging Face, confirmado com sha256sum após o download). Licença Apache 2.0 (permite redistribuição; texto em /usr/share/doc/qwen2.5-1.5b-instruct/LICENSE). Escolha: 1,5 mil milhões de parâmetros em Q4_K_M (~1,1 GB) é o melhor compromisso para uma ISO live que corre só no CPU — responde em português com qualidade razoável, gera várias dezenas de tokens por segundo num CPU moderno com AVX2 e cabe em máquinas com 4 GB de RAM; modelos maiores (3B/7B) duplicariam ou quadruplicariam a ISO e a RAM necessária. Instalado em /usr/share/ia/modelos/ com o link predefinido.gguf. O download é feito no host para \$LFS/sources (excluído do SquashFS) e reutilizado se já existir com a soma certa."
decisao "IA: comandos ia-* e servidor" \
"Comandos em /usr/bin (bash, mensagens em pt-PT; funções comuns em /usr/share/ia/ia-comum.sh): ia-chat (chat interativo com llama-cli; threads = núcleos físicos via lscpu, contexto 2048-16384 tokens consoante a RAM livre após carregar o modelo; prompt de sistema em pt-PT a identificar-se como assistente do ianinjapelagestao; -m modelo, -l lista), ia-perguntar (pergunta única via llama-completion -cnv -st, sem TTY, imprime só a resposta; semente 42, temperatura 0,1, máx. 64 tokens), ia-servidor {start|stop|restart|status} (chama /etc/rc.d/init.d/ia-servidor, bootscript ao estilo do BLFS que lança o llama-server como 'nobody' em 127.0.0.1:8080, configurável em /etc/sysconfig/ia-servidor; NÃO ativado no arranque — só escuta localmente, mas consome RAM/CPU), ia-baixar (descarrega outro GGUF por URL ou dono/repo/ficheiro.gguf do Hugging Face para /var/lib/ia/modelos — grupo ninja, 2775 —, com barra de progresso, verificação de espaço livre e do cabeçalho GGUF) e ia-info (CPU e extensões AVX2/AVX-512/AMX, variantes ggml, RAM, swap/zram, modelos, versão; -b corre llama-bench)."
decisao "IA: chat automático no login do ninja" \
"No fim de /home/ninja/.bash_profile e /etc/skel/.bash_profile foi acrescentada (uma só vez, com marcador) a linha que carrega /usr/share/ia/autoarranque.sh. Este lança o ia-chat, após a mensagem 'A iniciar o chat de IA… (Ctrl+C ou /sair para voltar à shell)', apenas se: o utilizador não for root, o stdin for um terminal, a consola for /dev/tty1-tty6, não for uma sessão ssh (SSH_CONNECTION/SSH_TTY), a variável IA_SEM_CHAT não estiver definida e existir modelo predefinido. Ao sair do chat fica a shell normal. Na consola série ttyS0 (usada pelos testes automáticos), por ssh e para o root nunca arranca."

if [ "$variante" = todas ]; then
  etapa_fim F8b ok "CMake 4.1.0, llama.cpp $LLAMA_TAG (todas as variantes CPU), Qwen2.5-1.5B Q4_K_M; ia-perguntar em ${tempo:-?} s no chroot"
else
  etapa_fim F8b aviso "llama.cpp $LLAMA_TAG compilado só para x86-64 portátil (variantes CPU falharam); Qwen2.5-1.5B Q4_K_M; ia-perguntar em ${tempo:-?} s"
fi
