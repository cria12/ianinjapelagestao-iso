#!/usr/bin/env python3
"""Converte os blocos de menuconfig (<pre class="screen">) da página do kernel do LFS em
linhas 'OPCAO=y|n|m' para scripts/config. Uso: kconfig-from-book.py kernel.html [blocos]"""
import html
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
want = set(int(x) for x in sys.argv[2].split(",")) if len(sys.argv) > 2 else None
screens = [html.unescape(re.sub(r"<[^>]+>", "", s)) for s in re.findall(r'<pre class="screen">(.*?)</pre>', text, re.S)]
for n, s in enumerate(screens, 1):
    if want and n not in want:
        continue
    state = None
    for line in s.split("\n"):
        m = re.match(r"\s*(\[\*\]|\[ \]|<\*>|< >|<M>|\(\S*\))", line)
        if m:
            state = {"[*]": "y", "<*>": "y", "[ ]": "n", "< >": "n", "<M>": "m"}.get(m.group(1))
        opt = re.search(r"\[([A-Z0-9_]+)\]\s*$", line)
        if opt and state:
            print(f"{opt.group(1)}={state}")
            state = None
