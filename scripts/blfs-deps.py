#!/usr/bin/env python3
"""Resolve a árvore de dependências BLFS 12.4 (Required + Recommended) de um conjunto de páginas
e imprime-as por ordem de instalação (dependências primeiro).

Páginas com vários pacotes (python-modules, x7driver...) são tratadas por secção: cap/pagina@secao.
Uso: blfs-deps.py <raiz-blfs> [--feitas FICHEIRO] [--sem PAGINA]... ALVO...
  --feitas   ficheiro com páginas já instaladas (uma por linha, ex.: general/git) — omitidas
  --sem      páginas a ignorar (ex.: dependências recomendadas que não se querem)
  --runtime  inclui também "Required (runtime)" / "Recommended (runtime)"
As ligações para o livro LFS (fora do BLFS) são ignoradas — já fazem parte do sistema base.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blfs_html  # noqa: E402

SEC_RE = re.compile(r'<p class="(required|recommended)">(.*?)</p>', re.S)
HREF_RE = re.compile(r'class="xref" href=\s*"([^"#]*)(?:#([^"]*))?"')


def deps(root, page, runtime):
    t = blfs_html.html(root, page)
    # páginas: "<h3>... Dependencies</h3>" + <h4>Required</h4>; secções: <h4> + <h5>
    m = re.search(r"Dependencies\s*</h[34]>", t)
    if not m:
        return []
    ini = m.start()
    fim = t.find('<h2 class="sect2">', ini)
    sec = t[ini:fim if fim > 0 else len(t)]
    out = []
    # o título <h4> antes de cada <p> diz se é "(runtime)"
    for m in SEC_RE.finditer(sec):
        h = max(sec.rfind("<h4>", 0, m.start()), sec.rfind("<h5>", 0, m.start()))
        titulo = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", sec[h:m.start()])).lower()
        if "runtime" in titulo and not runtime:
            continue
        for href, ancora in HREF_RE.findall(m.group(2)):
            if href.startswith("http") or "/lfs/" in href:
                continue
            if not href:  # ligação para outra secção da mesma página
                href = os.path.basename(page.partition("@")[0]) + ".html"
            alvo = os.path.normpath(os.path.join(os.path.dirname(page), href))
            alvo = alvo.replace(os.sep, "/")
            if alvo.endswith(".html"):
                alvo = alvo[:-5]
            if alvo.startswith("..") or not os.path.exists(os.path.join(root, alvo + ".html")):
                continue
            # páginas com vários pacotes: a dependência é só a secção da âncora
            if ancora and blfs_html.multipacote(root, alvo):
                sid = blfs_html.secao_de(root, alvo, ancora)
                if sid:
                    alvo = f"{alvo}@{sid}"
            if alvo != page and alvo not in out:
                out.append(alvo)
    return out


def main():
    a = sys.argv[1:]
    root = a.pop(0)
    feitas, sem, alvos, runtime = set(), set(), [], False
    while a:
        x = a.pop(0)
        if x == "--feitas":
            feitas |= {l.split("#")[0].strip() for l in open(a.pop(0)) if l.split("#")[0].strip()}
        elif x == "--sem":
            sem.add(a.pop(0))
        elif x == "--runtime":
            runtime = True
        else:
            alvos.append(x)
    ordem, estado, pais = [], {}, {}

    def visita(p, cadeia):
        if p in feitas or p in sem:
            return
        if estado.get(p) == 2:
            return
        if estado.get(p) == 1:
            print(f"# ciclo: {' -> '.join(cadeia + [p])}", file=sys.stderr)
            return
        estado[p] = 1
        for d in deps(root, p, runtime):
            pais.setdefault(d, p)
            visita(d, cadeia + [p])
        estado[p] = 2
        ordem.append(p)

    for t in alvos:
        visita(t, [])
    for p in ordem:
        print(f"{p:45s} # pedido por {pais.get(p, '(alvo)')}")


if __name__ == "__main__":
    main()
