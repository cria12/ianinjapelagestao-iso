#!/bin/bash
# Verificação a seco da F8e (não descarrega nem compila): gera os scripts das páginas, confirma
# que cada pacote tem tarball e que cada --extra corresponde a um download da página, e que
# todas as funções usadas nos passos existem. Uso: bash scripts/apps/verificar-passos.sh
cd /root/ianinjapelagestao/scripts
BLFS=../book/blfs
erros=0
mapfile -t PASSOS < <(cat apps/passos-[0-9][0-9].txt | sed 's/[[:space:]]*#.*$//' | grep -v '^[[:space:]]*$')
echo "passos: ${#PASSOS[@]}"
dup=$(printf '%s\n' "${PASSOS[@]}" | cut -d'|' -f1 | sort | uniq -d)
[ -z "$dup" ] || { echo "ERRO ids repetidos: $dup"; erros=1; }
# funções definidas pela etapa + pelos ficheiros funcoes-NN.sh
def=$( { grep -ho '^[a-z_][a-z0-9_]*()' f08e-apps.sh* apps/funcoes-[0-9][0-9].sh; echo "in_chroot()"; } | tr -d '()' | sort -u)
for l in "${PASSOS[@]}"; do
  read -r -a c <<< "${l#*|}"
  case ${c[0]} in
    pacote|pacote_rede)
      python3 gen-scripts.py blfs $BLFS "${c[1]}" > /dev/null || { echo "ERRO gen ${c[1]}"; erros=1; }
      python3 blfs-fetch.py tarball $BLFS "${c[1]}" > /dev/null 2>&1 || { echo "ERRO tarball ${c[1]}"; erros=1; }
      lista=$(python3 blfs-fetch.py list $BLFS "${c[1]}" 2>/dev/null)
      for ((i=2; i<${#c[@]}; i++)); do
        if [ "${c[i]}" = --extra ]; then
          i=$((i+1))
          grep -qF -- "${c[i]}" <<< "$lista" || { echo "ERRO ${c[1]}: --extra ${c[i]} não corresponde a nenhum download"; erros=1; }
        fi
      done ;;
    pagina_config|pagina_rede)
      python3 gen-scripts.py blfs $BLFS "${c[1]}" > /dev/null || { echo "ERRO gen ${c[1]}"; erros=1; } ;;
    *)
      grep -qx "${c[0]}" <<< "$def" || { echo "ERRO função inexistente: ${c[0]} (passo ${l%%|*})"; erros=1; } ;;
  esac
done
for f in apps/funcoes-[0-9][0-9].sh replace/blfs-*.sh gen/blfs/*/*.sh; do bash -n "$f" || { echo "ERRO sintaxe $f"; erros=1; }; done
# overrides que apontam para blocos inexistentes
python3 - <<'EOF' || erros=1
import os, re, sys
sys.path.insert(0, ".")
import blfs_html
ok = True
for f in sorted(os.listdir("book-overrides.d")):
    for line in open(os.path.join("book-overrides.d", f), encoding="utf-8"):
        p = line.split("#", 1)[0].split()
        if len(p) < 3:
            continue
        spec = p[0].removeprefix("blfs/")
        n = len(re.findall(r'<pre class="(userinput|root)">', blfs_html.html("../book/blfs", spec)))
        for b in p[2].split(","):
            if int(b) > n:
                print(f"ERRO {f}: {spec} bloco {b} > {n}"); ok = False
            if p[1] == "replace" and not os.path.exists(f"replace/blfs-{spec.replace('/', '-')}.{b}.sh"):
                print(f"ERRO {f}: falta replace/blfs-{spec.replace('/', '-')}.{b}.sh"); ok = False
sys.exit(0 if ok else 1)
EOF
[ $erros = 0 ] && echo "verificação OK" || { echo "verificação com ERROS"; exit 1; }
