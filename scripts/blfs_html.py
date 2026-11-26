"""Leitura de páginas do BLFS 12.4, incluindo páginas com vários pacotes (python-modules,
python-dependencies, x7driver...), em que cada pacote é uma secção <div class="sect2">.

Especificação de página: "capitulo/pagina" ou "capitulo/pagina@secao" (secao = id da âncora
que abre a secção, ex.: general/python-modules@mako, x/x7driver@libinput).
"""
import os
import re

SECT2 = '<div class="sect2"'
_cache = {}


def _ler(root, page):
    path = os.path.join(root, page + ".html")
    if path not in _cache:
        _cache[path] = open(path, encoding="utf-8").read()
    return _cache[path]


def multipacote(root, page):
    """True se a página tem vários pacotes, cada um numa secção sect2 própria."""
    return _ler(root, page).count("Package Information") > 1


def secoes(t):
    """Lista de (id, inicio, fim) das secções sect2 de uma página."""
    ini = [m.start() for m in re.finditer(re.escape(SECT2), t)]
    out = []
    for i, s in enumerate(ini):
        f = ini[i + 1] if i + 1 < len(ini) else len(t)
        m = re.search(r'<a id="([^"]+)"', t[s:f])
        if m:
            out.append((m.group(1), s, f))
    return out


def secao_de(root, page, ancora):
    """id da secção sect2 que contém a âncora (ou None se a âncora estiver fora de secções)."""
    t = _ler(root, page)
    p = t.find(f'id="{ancora}"')
    if p < 0:
        return None
    for sid, s, f in secoes(t):
        if s <= p < f:
            return sid
    return None


def html(root, spec):
    """Texto HTML da página ou só da secção indicada."""
    page, _, sec = spec.partition("@")
    t = _ler(root, page)
    if not sec:
        return t
    for sid, s, f in secoes(t):
        if sid == sec:
            return t[s:f]
    raise SystemExit(f"{spec}: secção '{sec}' não encontrada")


def existe(root, spec):
    return os.path.exists(os.path.join(root, spec.partition("@")[0] + ".html"))

