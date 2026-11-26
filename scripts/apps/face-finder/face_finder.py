#!/usr/bin/env python3
"""Face Finder — encontra e marca rostos em fotografias (deteção, NÃO reconhecimento).

Usa o detetor YuNet (cv2.FaceDetectorYN, modelo ONNX do opencv_zoo, licença MIT) e funciona
sem rede. Para cada imagem desenha uma caixa à volta de cada rosto, os 5 pontos de referência
(olhos, ponta do nariz e cantos da boca) e a confiança; grava as imagens marcadas, um
resultados.json e um relatorio.html com miniaturas e contagens.

Uso:
    face-finder <ficheiro|pasta> [-o saida/] [--limiar 0.8] [--abrir]
"""
import argparse
import datetime
import html
import json
import os
import shutil
import subprocess
import sys

import cv2
import numpy as np

VERSAO = "1.0"
NOME_MODELO = "face_detection_yunet_2023mar.onnx"
EXTENSOES = (".jpg", ".jpeg", ".png", ".bmp", ".webp", ".tif", ".tiff")
AQUI = os.path.dirname(os.path.abspath(__file__))
# os 5 pontos devolvidos pelo YuNet, por esta ordem (lado do ponto de vista da pessoa)
PONTOS = ("olho_direito", "olho_esquerdo", "nariz", "boca_direita", "boca_esquerda")
CORES_PONTOS = ((255, 0, 0), (0, 0, 255), (0, 255, 0), (255, 0, 255), (0, 255, 255))  # BGR
MAX_LADO = 1920   # imagens maiores são reduzidas para a deteção (as caixas voltam à escala original)


def procurar_modelo(pedido=None):
    """Caminho do modelo: --modelo, $FACE_FINDER_MODELO, ./modelos/ do projeto ou /usr/share/face-finder/."""
    candidatos = [pedido, os.environ.get("FACE_FINDER_MODELO"),
                  os.path.join(AQUI, "modelos", NOME_MODELO),
                  os.path.join(AQUI, NOME_MODELO),
                  os.path.join("/usr/share/face-finder", NOME_MODELO)]
    for c in candidatos:
        if c and os.path.isfile(c):
            return c
    raise FileNotFoundError(f"modelo {NOME_MODELO} não encontrado (procurei em: "
                            + ", ".join(c for c in candidatos if c) + ")")


def carregar_detetor(modelo=None, limiar=0.8, nms=0.3):
    """Cria o detetor YuNet. O tamanho de entrada é acertado em cada imagem."""
    return cv2.FaceDetectorYN.create(procurar_modelo(modelo), "", (320, 320), limiar, nms, 5000)


def ler_imagem(caminho):
    """Lê uma imagem (também com acentos no nome); devolve BGR ou None."""
    try:
        dados = np.fromfile(caminho, dtype=np.uint8)
    except OSError:
        return None
    if dados.size == 0:
        return None
    return cv2.imdecode(dados, cv2.IMREAD_COLOR)


def gravar_imagem(caminho, img):
    ext = os.path.splitext(caminho)[1] or ".jpg"
    ok, buf = cv2.imencode(ext, img, [cv2.IMWRITE_JPEG_QUALITY, 90])
    if not ok:
        raise OSError(f"não foi possível codificar {caminho}")
    buf.tofile(caminho)


def detetar(img, detetor):
    """Deteta rostos numa imagem BGR. Devolve uma lista de dicionários (caixa, confiança, pontos)."""
    h, w = img.shape[:2]
    escala = min(1.0, MAX_LADO / max(h, w))
    peq = cv2.resize(img, (round(w * escala), round(h * escala)), interpolation=cv2.INTER_AREA) if escala < 1 else img
    detetor.setInputSize((peq.shape[1], peq.shape[0]))
    _, faces = detetor.detect(peq)
    rostos = []
    if faces is None:
        return rostos
    for f in faces:
        v = [float(x) / escala for x in f[:14]]
        x, y, cw, ch = v[0:4]
        x0, y0 = max(0.0, x), max(0.0, y)
        caixa = [round(x0), round(y0), round(min(w, x + cw) - x0), round(min(h, y + ch) - y0)]
        pontos = {n: [round(v[4 + 2 * i]), round(v[5 + 2 * i])] for i, n in enumerate(PONTOS)}
        rostos.append({"caixa": caixa, "confianca": round(float(f[14]), 4), "pontos": pontos})
    # ordem de leitura: da esquerda para a direita, de cima para baixo (por "filas" aproximadas)
    rostos.sort(key=lambda r: (r["caixa"][1] // max(1, r["caixa"][3]), r["caixa"][0]))
    return rostos


def desenhar(img, rostos):
    """Devolve uma cópia da imagem com caixas, pontos e confiança desenhados."""
    out = img.copy()
    h, w = out.shape[:2]
    esp = max(1, round(max(h, w) / 600))
    for i, r in enumerate(rostos, 1):
        x, y, cw, ch = r["caixa"]
        # verde para confiança alta, amarelo/laranja para mais baixa
        c = r["confianca"]
        cor = (0, 200, 0) if c >= 0.9 else (0, 200, 255) if c >= 0.8 else (0, 140, 255)
        e = max(1, min(esp, cw // 25 + 1))
        cv2.rectangle(out, (x, y), (x + cw, y + ch), cor, e, cv2.LINE_AA)
        raio = max(1, min(esp + 2, cw // 30))
        for (px, py), cp in zip(r["pontos"].values(), CORES_PONTOS):
            cv2.circle(out, (px, py), raio, cp, -1, cv2.LINE_AA)
        if cw < 45:
            continue   # rosto pequeno (multidão): sem etiqueta, para não tapar os vizinhos
        texto = f"{i}: {c:.2f}"
        fs = max(0.35, min(1.2, cw / 140))
        (tw, th), base = cv2.getTextSize(texto, cv2.FONT_HERSHEY_SIMPLEX, fs, 1)
        ty = y - 4 if y - th - 6 > 0 else y + ch + th + 4
        cv2.rectangle(out, (x, ty - th - 3), (x + tw + 4, ty + base - 1), cor, -1)
        cv2.putText(out, texto, (x + 2, ty - 1), cv2.FONT_HERSHEY_SIMPLEX, fs, (0, 0, 0), 1, cv2.LINE_AA)
    return out


def listar_imagens(entrada):
    if os.path.isdir(entrada):
        return sorted(os.path.join(entrada, f) for f in os.listdir(entrada)
                      if f.lower().endswith(EXTENSOES) and not f.startswith("."))
    if os.path.isfile(entrada):
        return [entrada]
    raise FileNotFoundError(f"não existe: {entrada}")


def processar(entrada, saida, detetor, limiar, modelo_nome=NOME_MODELO, mensagens=print):
    """Processa um ficheiro ou pasta; grava imagens marcadas, resultados.json e relatorio.html."""
    imagens = listar_imagens(entrada)
    if not imagens:
        raise FileNotFoundError(f"nenhuma imagem ({', '.join(EXTENSOES)}) em {entrada}")
    os.makedirs(saida, exist_ok=True)
    resultados = []
    for caminho in imagens:
        img = ler_imagem(caminho)
        nome = os.path.basename(caminho)
        if img is None:
            mensagens(f"  aviso: não consegui ler {nome} (ignorada)")
            resultados.append({"ficheiro": caminho, "erro": "imagem ilegível", "rostos": []})
            continue
        t0 = cv2.getTickCount()
        rostos = detetar(img, detetor)
        ms = (cv2.getTickCount() - t0) * 1000 / cv2.getTickFrequency()
        base = os.path.splitext(nome)[0]
        marcada = f"{base}_rostos.jpg"
        gravar_imagem(os.path.join(saida, marcada), desenhar(img, rostos))
        resultados.append({"ficheiro": caminho, "saida": marcada, "largura": img.shape[1],
                           "altura": img.shape[0], "tempo_ms": round(ms, 1), "rostos": rostos})
        mensagens(f"  {nome:<32} {len(rostos):>4} rosto(s)   ({ms:.0f} ms)")
    dados = {
        "programa": f"face-finder {VERSAO}",
        "opencv": cv2.__version__,
        "modelo": modelo_nome,
        "limiar": limiar,
        "gerado_em": datetime.datetime.now().isoformat(timespec="seconds"),
        "total_imagens": len(resultados),
        "total_rostos": sum(len(r["rostos"]) for r in resultados),
        "imagens": resultados,
    }
    with open(os.path.join(saida, "resultados.json"), "w", encoding="utf-8") as f:
        json.dump(dados, f, ensure_ascii=False, indent=2)
    escrever_html(dados, os.path.join(saida, "relatorio.html"))
    return dados


def escrever_html(dados, destino):
    e = html.escape
    cartoes = []
    for r in dados["imagens"]:
        nome = os.path.basename(r["ficheiro"])
        if "erro" in r:
            cartoes.append(f'<figure class="erro"><figcaption>{e(nome)}: {e(r["erro"])}</figcaption></figure>')
            continue
        n = len(r["rostos"])
        conf = ", ".join(f'{x["confianca"]:.2f}' for x in r["rostos"][:12]) + (" …" if n > 12 else "")
        cartoes.append(
            f'<figure><a href="{e(r["saida"])}"><img src="{e(r["saida"])}" alt="{e(nome)}" loading="lazy"></a>'
            f'<figcaption><b>{e(nome)}</b><span class="n">{n} rosto{"s" if n != 1 else ""}</span>'
            f'<small>{r["largura"]}×{r["altura"]} · {r["tempo_ms"]:.0f} ms'
            f'{" · confiança: " + e(conf) if n else ""}</small></figcaption></figure>')
    pagina = f"""<!doctype html>
<html lang="pt-PT"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Face Finder — relatório</title>
<style>
 :root {{ color-scheme: light dark; --fundo:#f5f5f7; --cartao:#fff; --texto:#1d1d1f; --suave:#6e6e73; --real:#0a7d32; }}
 @media (prefers-color-scheme: dark) {{ :root {{ --fundo:#1c1c1e; --cartao:#2c2c2e; --texto:#f5f5f7; --suave:#a1a1a6; --real:#30d158; }} }}
 body {{ margin:0; padding:24px 16px; font-family: system-ui, sans-serif; background:var(--fundo); color:var(--texto); }}
 header {{ max-width:1200px; margin:0 auto 16px; }}
 h1 {{ margin:0 0 4px; font-size:1.6rem; }}
 p {{ margin:4px 0; color:var(--suave); }}
 .total {{ color:var(--real); font-weight:600; }}
 main {{ max-width:1200px; margin:0 auto; display:grid; gap:16px; grid-template-columns:repeat(auto-fill, minmax(260px, 1fr)); }}
 figure {{ margin:0; background:var(--cartao); border-radius:12px; overflow:hidden; box-shadow:0 1px 3px #0003; }}
 figure img {{ width:100%; height:200px; object-fit:cover; display:block; }}
 figcaption {{ padding:10px 12px; display:grid; gap:2px; }}
 .n {{ color:var(--real); font-weight:600; }}
 small {{ color:var(--suave); }}
 footer {{ max-width:1200px; margin:24px auto 0; font-size:.85rem; color:var(--suave); }}
</style></head><body>
<header><h1>Face Finder — relatório</h1>
<p><span class="total">{dados["total_rostos"]} rostos</span> em {dados["total_imagens"]} imagens ·
limiar {dados["limiar"]} · modelo {e(dados["modelo"])} · OpenCV {e(dados["opencv"])} · {e(dados["gerado_em"])}</p>
<p>Deteção de rostos: o programa encontra <em>onde</em> há rostos; não identifica <em>quem</em> são.</p></header>
<main>
{chr(10).join(cartoes)}
</main>
<footer>Gerado por {e(dados["programa"])}. Dados completos em <a href="resultados.json">resultados.json</a>.</footer>
</body></html>
"""
    with open(destino, "w", encoding="utf-8") as f:
        f.write(pagina)


def abrir(saida, dados):
    """Abre as imagens marcadas no Ristretto (ou, sem ele, o relatório com xdg-open)."""
    marcadas = [os.path.join(saida, r["saida"]) for r in dados["imagens"] if "saida" in r]
    if shutil.which("ristretto") and marcadas:
        cmd = ["ristretto", marcadas[0]]
    elif shutil.which("xdg-open"):
        cmd = ["xdg-open", os.path.join(saida, "relatorio.html")]
    else:
        print("aviso: nem ristretto nem xdg-open disponíveis; abra à mão:", saida)
        return
    subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def main(argv=None):
    p = argparse.ArgumentParser(
        prog="face-finder",
        description="Encontra e marca rostos em fotografias (deteção com YuNet/OpenCV; não identifica pessoas).",
        epilog="Exemplo: face-finder ~/Projetos/face-finder/fotos -o saida --abrir")
    p.add_argument("entrada", help="ficheiro de imagem ou pasta com imagens")
    p.add_argument("-o", "--saida", default="saida", help="pasta para os resultados (omissão: ./saida)")
    p.add_argument("--limiar", type=float, default=0.8,
                   help="confiança mínima de 0 a 1 (omissão: 0.8; mais baixo encontra mais rostos e mais enganos)")
    p.add_argument("--nms", type=float, default=0.3, help="limiar de sobreposição para juntar caixas repetidas (omissão: 0.3)")
    p.add_argument("--modelo", help=f"caminho do {NOME_MODELO}")
    p.add_argument("--abrir", action="store_true", help="no fim, abre os resultados no Ristretto (ou com xdg-open)")
    p.add_argument("--versao", action="version", version=f"face-finder {VERSAO} (OpenCV {cv2.__version__})")
    a = p.parse_args(argv)
    if not 0.0 < a.limiar <= 1.0:
        p.error("--limiar tem de estar entre 0 e 1")
    try:
        modelo = procurar_modelo(a.modelo)
        detetor = carregar_detetor(modelo, a.limiar, a.nms)
        print(f"Face Finder {VERSAO} — OpenCV {cv2.__version__}, modelo {os.path.basename(modelo)}, limiar {a.limiar}")
        dados = processar(a.entrada, a.saida, detetor, a.limiar, os.path.basename(modelo))
    except (FileNotFoundError, cv2.error, OSError) as erro:
        print(f"face-finder: erro: {erro}", file=sys.stderr)
        return 1
    print(f"Total: {dados['total_rostos']} rosto(s) em {dados['total_imagens']} imagem(ns).")
    print(f"Resultados em {os.path.abspath(a.saida)}/ (imagens *_rostos.jpg, resultados.json, relatorio.html)")
    if a.abrir:
        abrir(a.saida, dados)
    return 0


if __name__ == "__main__":
    sys.exit(main())
