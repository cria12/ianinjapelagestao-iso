#!/usr/bin/env python3
"""Transcreve os comandos de uma página do livro LFS/BLFS (blocos <pre class="userinput"> e
<pre class="root">) para stdout, cada bloco numerado. Uso: extract-book.py pagina.html [classes]"""
import html
import re
import sys

page = sys.argv[1]
classes = sys.argv[2].split(",") if len(sys.argv) > 2 else ["userinput", "root"]
text = open(page, encoding="utf-8").read()

pat = re.compile(r'<pre class="(%s)">(.*?)</pre>' % "|".join(classes), re.S)
for n, m in enumerate(pat.finditer(text), 1):
    body = re.sub(r"<[^>]+>", "", m.group(2))
    body = html.unescape(body).strip("\n")
    print(f"# --- bloco {n} ({m.group(1)})")
    print(body)
    print()
