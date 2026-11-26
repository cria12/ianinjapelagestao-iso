#!/usr/bin/env python3
"""Gera scripts/gen/<livro>/<capitulo>/<pagina>.sh a partir das páginas do livro.

Cada bloco <pre class="userinput"> (e <pre class="root"> no BLFS) é transcrito literalmente.
O ficheiro scripts/book-overrides.txt indica, por página e nº de bloco:
  skip      — bloco não executado (interativo/explicativo/alternativa), com motivo
  test      — bloco de test suite: corre, mas falhas não interrompem a build
  must      — força bloco a ser normal (anula a deteção automática de testes)
  replace   — substitui o bloco pelo conteúdo de scripts/replace/<pagina>.<n>.sh
Uso: gen-scripts.py <livro: lfs|blfs> <raiz-html> <capitulo/pagina> ...
"""
import html
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blfs_html  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
TEST_RE = re.compile(
    r"^\s*(make|ninja|meson test|python3 -m pytest|pytest)\b[^\n]*\b(check|test|tests)\b"
    r"|^\s*su tester|^\s*su -s /usr/bin/expect tester|TESTSUITEFLAGS=|runtests|^\s*make -k check",
    re.M,
)


def load_overrides():
    ov = {}
    paths = [os.path.join(HERE, "book-overrides.txt")]
    d = os.path.join(HERE, "book-overrides.d")
    if os.path.isdir(d):
        paths += [os.path.join(d, f) for f in sorted(os.listdir(d)) if f.endswith(".txt")]
    for line in (l for p in paths for l in open(p, encoding="utf-8")):
        line = line.split("#", 1)
        motivo = line[1].strip() if len(line) > 1 else ""
        parts = line[0].split()
        if len(parts) < 3:
            continue
        page, kind = parts[0], parts[1]
        for n in parts[2].split(","):
            ov[(page, int(n))] = (kind, motivo)
    return ov


def blocks(text, classes):
    pat = re.compile(r'<pre class="(%s)">(.*?)</pre>' % "|".join(classes), re.S)
    for m in pat.finditer(text):
        body = html.unescape(re.sub(r"<[^>]+>", "", m.group(2))).strip("\n")
        yield m.group(1), body


def main():
    book, root, pages = sys.argv[1], sys.argv[2], sys.argv[3:]
    classes = ["userinput"] if book == "lfs" else ["userinput", "root"]
    ov = load_overrides()
    for page in pages:
        key = f"{book}/{page}"
        out = os.path.join(HERE, "gen", book, page + ".sh")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        lines = [f"# Gerado de {book.upper()} 12.4 {page}.html — NÃO EDITAR (ver book-overrides.txt)\n"]
        for n, (cls, body) in enumerate(blocks(blfs_html.html(root, page) if book == "blfs" else open(os.path.join(root, page + ".html"), encoding="utf-8").read(), classes), 1):
            kind, motivo = ov.get((key, n), (None, ""))
            if kind is None:
                kind = "test" if TEST_RE.search(body) else "run"
            if kind == "must":
                kind = "run"
            if kind == "replace":
                rep = os.path.join(HERE, "replace", f"{book}-{page.replace('/', '-')}.{n}.sh")
                lines.append(f"# --- bloco {n} [substituído: {motivo}]\n")
                lines.append(open(rep, encoding="utf-8").read().rstrip("\n") + "\n\n")
            elif kind == "skip":
                lines.append(f"# --- bloco {n} [omitido: {motivo}]\n")
                lines.append("".join("#   " + l + "\n" for l in body.split("\n")) + "\n")
            elif kind == "test":
                lines.append(f"# --- bloco {n} [teste]\n")
                lines.append(f"echo '>>> bloco {n} (teste)'\n")
                lines.append("if ! (\n" + body + "\n); then echo '[AVISO-TESTE] bloco %d terminou com falhas'; fi\n\n" % n)
            else:
                lines.append(f"# --- bloco {n} ({cls})\n")
                lines.append(f"echo '>>> bloco {n}'\n")
                lines.append(body + "\n\n")
        with open(out, "w", encoding="utf-8") as f:
            f.writelines(lines)
        print(out)


if __name__ == "__main__":
    main()
