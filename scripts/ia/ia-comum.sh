# /usr/share/ia/ia-comum.sh — funções partilhadas pelos comandos ia-* do ianinjapelagestao.
# Carregado com "source"; não é executável por si.

IA_MODELOS_SIS=/usr/share/ia/modelos          # modelos incluídos na ISO (só leitura)
IA_MODELOS_VAR=/var/lib/ia/modelos            # modelos descarregados pelo utilizador (ia-baixar)
IA_PREDEFINIDO=$IA_MODELOS_SIS/predefinido.gguf
IA_SISTEMA="És o assistente de IA do ianinjapelagestao, um sistema operativo Linux From Scratch \
focado em inteligência artificial local, que corre inteiramente no CPU deste computador, sem \
ligação à Internet. Responde sempre em português europeu (de Portugal), de forma clara, correta \
e concisa. Se não souberes a resposta, diz que não sabes."

ia_erro() { echo "$(basename "$0"): $*" >&2; exit 1; }

# Número de núcleos físicos (sem hyper-threading); recorre ao nproc
ia_threads() {
  local n=0
  if type -P lscpu > /dev/null; then
    n=$(lscpu -p=Core,Socket 2> /dev/null | grep -v '^#' | sort -u | wc -l || true)
  fi
  if [ "${n:-0}" -le 0 ] && [ -r /proc/cpuinfo ]; then
    n=$(awk -F: '/^physical id/{p=$2} /^core id/{print p":"$2}' /proc/cpuinfo | sort -u | wc -l || true)
  fi
  local l; l=$(nproc 2> /dev/null || echo 1)
  if [ "${n:-0}" -le 0 ] || [ "$n" -gt "$l" ]; then n=$l; fi
  echo "$n"
}

# Memória disponível em MiB
ia_mem_livre() { awk '/^MemAvailable:/{print int($2/1024)}' /proc/meminfo; }

# Tamanho de contexto (tokens) consoante a RAM livre depois de carregar o modelo
ia_contexto() { # ia_contexto <modelo>
  local livre mod resto
  livre=$(ia_mem_livre)
  mod=$(( $(stat -L -c %s "$1" 2> /dev/null || echo 0) / 1048576 ))
  resto=$(( livre - mod - 512 ))
  if   [ "$resto" -ge 4096 ]; then echo 16384
  elif [ "$resto" -ge 2048 ]; then echo 8192
  elif [ "$resto" -ge 1024 ]; then echo 4096
  else echo 2048
  fi
}

# Diretório onde se guardam modelos novos: /var/lib/ia/modelos se existir (ou puder ser criado)
# e tiver permissão de escrita; senão /usr/share/ia/modelos (normalmente só para o root)
ia_dir_escrita() {
  if [ -d "$IA_MODELOS_VAR" ] || mkdir -p "$IA_MODELOS_VAR" 2> /dev/null; then
    [ -w "$IA_MODELOS_VAR" ] && { echo "$IA_MODELOS_VAR"; return 0; }
  fi
  [ -w "$IA_MODELOS_SIS" ] && { echo "$IA_MODELOS_SIS"; return 0; }
  return 1
}

# Lista os modelos .gguf (um caminho por linha)
ia_modelos() {
  local d
  for d in "$IA_MODELOS_SIS" "$IA_MODELOS_VAR"; do
    [ -d "$d" ] || continue
    find "$d" -maxdepth 1 -name '*.gguf' ! -name predefinido.gguf \( -type f -o -type l \) 2> /dev/null | sort
  done
}

ia_listar() {
  local m alvo
  alvo=$(readlink -f "$IA_PREDEFINIDO" 2> /dev/null || true)
  echo "Modelos disponíveis ($IA_MODELOS_SIS, $IA_MODELOS_VAR):"
  local n=0
  while read -r m; do
    [ -n "$m" ] || continue
    n=$((n+1))
    printf '  %-48s %6s%s\n' "$(basename "$m")" "$(du -hL "$m" | cut -f1)" \
      "$([ "$(readlink -f "$m")" = "$alvo" ] && echo '  (predefinido)')"
  done < <(ia_modelos)
  [ $n -gt 0 ] || echo "  (nenhum)"
}

# Resolve -m <ficheiro|nome> para um caminho; sem argumento devolve o modelo predefinido
ia_modelo() {
  local m=${1:-}
  if [ -z "$m" ]; then
    [ -e "$IA_PREDEFINIDO" ] || ia_erro "modelo predefinido $IA_PREDEFINIDO não encontrado"
    readlink -f "$IA_PREDEFINIDO"; return 0
  fi
  [ -f "$m" ] && { readlink -f "$m"; return 0; }
  local d
  for d in "$IA_MODELOS_VAR" "$IA_MODELOS_SIS"; do
    [ -f "$d/$m" ] && { readlink -f "$d/$m"; return 0; }
    [ -f "$d/$m.gguf" ] && { readlink -f "$d/$m.gguf"; return 0; }
  done
  ia_erro "modelo '$m' não encontrado (ver: ia-chat -l)"
}
