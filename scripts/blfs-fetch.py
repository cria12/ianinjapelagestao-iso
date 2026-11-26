#!/usr/bin/env python3
"""Lê a secção "Package Information" / "Additional Downloads" de uma página do BLFS 12.4 e
obtém os URLs (HTTP), as somas MD5 e os patches — para que versões e URLs venham do livro.

Uso:
  blfs-fetch.py list    <raiz-blfs> <cap/pagina> ...        mostra o que foi resolvido
  blfs-fetch.py tarball <raiz-blfs> <cap/pagina>            imprime o nome do tarball principal
  blfs-fetch.py fetch   <raiz-blfs> <destino> <cap/pagina> [--extra TEXTO]... [--md5 SOMA]
        descarrega (com wget) o tarball principal, os patches obrigatórios ("Required patch")
        e os downloads adicionais cujo URL contenha TEXTO; verifica o MD5 indicado no livro.
        --md5 só é aceite para o tarball principal quando a página não indica MD5.
Errata BLFS 12.4: ftp.gnu.org/gnu/ -> ftpmirror.gnu.org/ (mesmo caminho).
"""
import hashlib
import html
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blfs_html  # noqa: E402

ERRATA = [(re.compile(r"^https?://ftp\.gnu\.org/gnu/"), "https://ftpmirror.gnu.org/")]


def errata(url):
    for pat, rep in ERRATA:
        url = pat.sub(rep, url)
    return url


def texto(s):
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", s))).strip()


def parse(root, page):
    """Devolve lista de dicts {tipo, url, md5, nota} pela ordem da página."""
    t = blfs_html.html(root, page)  # page pode ser "cap/pagina@secao"
    ini = t.find("Package Information")
    if ini < 0:
        raise SystemExit(f"{page}: secção 'Package Information' não encontrada")
    # termina no 1.º cabeçalho de dependências / instalação / kernel / notas seguintes
    fim = len(t)
    for marca in (r"<h3>\s*[^<]*Dependencies", r'<h2 class="sect2">', r"<h3>\s*Kernel"):
        m = re.compile(marca).search(t, ini)
        if m and m.start() < fim:
            fim = m.start()
    sec = t[ini:fim]
    adicionais = sec.find("Additional Downloads")
    out = []
    titulo = ""
    for m in re.finditer(r'<p class="title">(.*?)</p>|<li class="listitem">(.*?)</li>', sec, re.S):
        if m.group(1) is not None:
            titulo = texto(m.group(1))
            continue
        li = m.group(2)
        txt = texto(li)
        href = re.search(r'class="ulink" href=\s*"([^"]+)"', li)
        md5 = re.search(r"MD5 sum:\s*([0-9a-f]{32})", txt, re.I)
        if md5 and not href:
            if out and out[-1]["md5"] is None:
                out[-1]["md5"] = md5.group(1)
            continue
        if not href:
            continue
        url = href.group(1).strip()
        if txt.startswith("Download (FTP)"):
            continue
        extra = adicionais >= 0 and m.start() > adicionais
        if not extra and re.match(r"Download( \(HTTP\))?:", txt) and not any(d["tipo"] == "principal" for d in out):
            tipo = "principal"
        elif re.match(r"Required patch", txt, re.I):
            tipo = "patch-obrigatorio"
        elif re.match(r"Recommended patch", txt, re.I):
            tipo = "patch-recomendado"
        elif re.match(r"Optional patch", txt, re.I):
            tipo = "patch-opcional"
        else:
            tipo = "adicional"
        out.append({"tipo": tipo, "url": url, "md5": None, "nota": titulo})
    if not any(d["tipo"] == "principal" for d in out):
        raise SystemExit(f"{page}: URL 'Download (HTTP)' não encontrado")
    return out


def md5sum(path):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for bloco in iter(lambda: f.read(1 << 20), b""):
            h.update(bloco)
    return h.hexdigest()


def baixar(url, md5, dest):
    url = errata(url)
    nome = os.path.basename(url)
    alvo = os.path.join(dest, nome)
    if os.path.exists(alvo) and md5 and md5sum(alvo) == md5:
        print(f"[ok] {nome} já presente (MD5 {md5})")
        return
    tmp = alvo + ".part"
    print(f"[wget] {url}")
    subprocess.run(["wget", "-nv", "--tries=3", "--timeout=60", "-O", tmp, url], check=True)
    real = md5sum(tmp)
    if md5 and real != md5:
        os.remove(tmp)
        raise SystemExit(f"MD5 errado para {nome}: {real} (livro: {md5})")
    os.replace(tmp, alvo)
    print(f"[ok] {nome} MD5 {real}" + ("" if md5 else " (sem MD5 no livro — não verificado)"))


def main():
    sys.stdout.reconfigure(line_buffering=True)  # não misturar com a saída do wget nos logs
    a = sys.argv[1:]
    if not a:
        raise SystemExit(__doc__)
    cmd = a.pop(0)
    if cmd == "list":
        root = a.pop(0)
        for page in a:
            for d in parse(root, page):
                nota = f"  [{d['nota']}]" if d["nota"] else ""
                print(f"{page}\t{d['tipo']}\t{errata(d['url'])}\t{d['md5'] or '-'}{nota}")
    elif cmd == "tarball":
        root, page = a
        d = [x for x in parse(root, page) if x["tipo"] == "principal"][0]
        print(os.path.basename(errata(d["url"])))
    elif cmd == "fetch":
        root, dest, page = a[0], a[1], a[2]
        extras, md5_manual, i = [], None, 3
        while i < len(a):
            if a[i] == "--extra":
                extras.append(a[i + 1]); i += 2
            elif a[i] == "--md5":
                md5_manual = a[i + 1]; i += 2
            else:
                raise SystemExit(f"opção desconhecida: {a[i]}")
        for d in parse(root, page):
            if d["tipo"] == "principal":
                md5 = d["md5"] or md5_manual
                if not md5:
                    raise SystemExit(f"{page}: o livro não indica MD5 e não foi dado --md5")
                baixar(d["url"], md5, dest)
            elif d["tipo"] == "patch-obrigatorio" or any(e in d["url"] for e in extras):
                if not d["md5"]:
                    print(f"[aviso] {d['url']}: sem MD5 no livro")
                baixar(d["url"], d["md5"], dest)
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
