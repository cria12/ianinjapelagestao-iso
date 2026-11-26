#!/bin/bash
# otimizacoes/strip.sh [RAIZ] — tira os símbolos de depuração (strip --strip-unneeded) dos
# executáveis e bibliotecas ELF x86-64 do sistema. Corre no chroot do alvo (RAIZ vazia = /) pelo
# passo otim-strip da F8e (scripts/apps/funcoes-10.sh); com RAIZ serve para ensaios numa cópia.
# Seguro por construção:
#  - só ELF de 64 bits x86-64, do tipo EXEC ou DYN (nunca .o, .ko, .a, módulos do GRUB, BPF);
#  - só ficheiros que ainda têm .symtab ou .debug_* (idempotente: repetir não faz nada);
#  - fora: /usr/src (headers do kernel para NVIDIA/OpenRazer), /usr/share, /usr/include,
#    /usr/lib/{modules,firmware,grub,debug}, Valgrind (precisa dos seus símbolos), /opt/rustc*,
#    ld-linux/libc/libthread_db (o memcheck do Valgrind e o GDB precisam dos símbolos da glibc),
#    binários Go e ficheiros com dados depois do fim do ELF (instaladores com carga anexada);
#  - o strip escreve para um ficheiro novo na mesma pasta; dono, modo (incl. setuid), datas e
#    xattrs (capabilities) são copiados do original e só depois se faz rename por cima: um
#    programa ou biblioteca em uso continua com o inode antigo (nada fica meio escrito);
#  - ligações físicas (git-core, gcc...): strip uma vez por inode e as outras voltam a apontar
#    para o novo (ln -f); se houver ligações fora da lista o inode fica como está.
# Saída: uma linha de resumo "strip: N ficheiros, ANTES -> DEPOIS MiB (falhas: F)".
R=${1:-}
cd "$R/" || exit 1
PATH=/usr/bin:/usr/sbin:$PATH
lista=$(mktemp) || exit 1
trap 'rm -f "$lista"' EXIT
alvos="usr"; [ -d opt ] && alvos="$alvos opt"
# %i inode, %n n.º de ligações, %p caminho (relativo a RAIZ)
find $alvos -xdev \( -path usr/src -o -path usr/share -o -path usr/include \
    -o -path usr/lib/modules -o -path usr/lib/firmware -o -path usr/lib/grub -o -path usr/lib/debug \
    -o -path usr/lib/valgrind -o -path usr/libexec/valgrind -o -path 'opt/rustc*' \) -prune \
  -o -type f \( -perm -u+x -o -name '*.so' -o -name '*.so.*' -o -name '*.node' \) \
     ! -name 'ld-linux*' ! -name 'libc.so*' ! -name 'libthread_db*' ! -name '*.otim-strip' \
     -printf '%i %n %p\n' | sort -n -k1,1 > "$lista"

# elegivel <ficheiro> — 0 se for ELF64 x86-64 EXEC/DYN com símbolos, sem Go e sem dados anexados
elegivel() {
  local f=$1 h shoff ent num tam
  h=$(od -An -tx1 -N20 "$f" 2>/dev/null | tr -d ' \n')
  # 7f454c46 | classe 02 (64 bits) | ... | e_type 0200/0300 | e_machine 3e00 (x86-64)
  [ "${h:0:10}" = 7f454c4602 ] || return 1
  case ${h:32:4} in 0200|0300) ;; *) return 1 ;; esac
  [ "${h:36:4}" = 3e00 ] || return 1
  local s; s=$(readelf -S -W "$f" 2>/dev/null) || return 1
  grep -qE '\.symtab|\.debug_' <<< "$s" || return 1
  grep -qE '\.go\.buildinfo|\.note\.go\.buildid' <<< "$s" && return 1
  shoff=$(od -An -tu8 -j40 -N8 "$f" | tr -d ' ')
  read -r ent num < <(od -An -tu2 -j58 -N4 "$f")
  tam=$(stat -c %s "$f")
  [ "$tam" -le $((shoff + ent * num)) ] || return 1
  return 0
}

n=0; falhas=0; antes=0; depois=0
processa() {   # processa <n.º de ligações> <caminho>... (todos o mesmo inode)
  local links=$1; shift
  local f=$1 t a d o
  [ "$links" = $# ] || return 0
  elegivel "$f" || return 0
  t="$f.otim-strip"
  a=$(stat -c %s "$f")
  if strip --strip-unneeded -o "$t" "$f" 2>/dev/null \
     && cp --attributes-only --preserve=mode,ownership,timestamps,xattr "$f" "$t" \
     && mv -f "$t" "$f"; then
    shift
    for o in "$@"; do ln -f "$f" "$o" || { echo "AVISO: ln -f $f $o falhou"; falhas=$((falhas+1)); }; done
    d=$(stat -c %s "$f")
    n=$((n+1)); antes=$((antes+a)); depois=$((depois+d))
  else
    rm -f "$t"; falhas=$((falhas+1)); echo "AVISO: strip falhou (fica como estava): /$f"
  fi
}
ino=""; nl=""; grupo=()
while read -r i l p; do
  if [ "$i" != "$ino" ]; then
    [ ${#grupo[@]} -gt 0 ] && processa "$nl" "${grupo[@]}"
    ino=$i; nl=$l; grupo=()
  fi
  grupo+=("$p")
done < "$lista"
[ ${#grupo[@]} -gt 0 ] && processa "$nl" "${grupo[@]}"
echo "strip: $n ficheiros, $((antes / 1048576)) -> $((depois / 1048576)) MiB (falhas: $falhas)"
# uma falha deixa o ficheiro original intacto: não é motivo para parar a build (o passo
# confirma a seguir que os programas principais arrancam)
exit 0
