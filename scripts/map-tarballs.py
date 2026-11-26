#!/usr/bin/env python3
"""Associa cada página do livro ao tarball em sources. Uso: map-tarballs.py <raiz-html> <dir-sources> < paginas"""
import html
import os
import re
import sys

root, src = sys.argv[1], sys.argv[2]
files = [f for f in os.listdir(src) if re.search(r"\.tar\.(xz|gz|bz2|zst)$|\.tgz$", f) and "-html" not in f]
SPECIAL = {"tcl": "tcl8.6", "expect": "expect5", "xml::parser": "xml-parser", "flit-core": "flit_core"}
NOPKG = {"changingowner", "kernfs", "chroot", "creatingdirs", "createfiles", "cleanup", "stripping"}

for page in sys.stdin.read().split():
    name = page.split("/")[1]
    if name in NOPKG:
        print(page, "-")
        continue
    t = open(os.path.join(root, page + ".html"), encoding="utf-8").read()
    title = html.unescape(re.sub(r"<[^>]+>", "", re.search(r"<h1[^>]*>(.*?)</h1>", t, re.S).group(1)))
    title = re.sub(r"^\s*[\d.]+\s*", "", " ".join(title.split()))
    word = title.split(" from ")[-1].split()[0] if " from " in title else title.split()[0]
    base = word.lower()
    m = re.match(r"(.+?)-(\d.*)$", base)
    pkg, ver = (m.group(1), m.group(2)) if m else (base, "")
    cands = [f for f in files if f.lower().startswith(base + ".tar") or f.lower().startswith(base + "-src")]
    if not cands and pkg in SPECIAL:
        cands = [f for f in files if f.lower().startswith(SPECIAL[pkg]) and ver.split("-")[0] in f]
    if not cands:
        cands = [f for f in files if f.lower().startswith(pkg) and ver and ver in f]
    if len(cands) != 1:
        print(page, "ERRO", title, cands, file=sys.stderr)
        print(page, "ERRO")
        continue
    print(page, cands[0])
