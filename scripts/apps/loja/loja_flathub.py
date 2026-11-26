"""loja_flathub — cliente da API pública do Flathub (https://flathub.org/api/v2) com cache em disco.

Sem dependências fora da biblioteca padrão (não importa o GTK): pode ser testado sozinho.
Endpoints usados (confirmados em 2026-11):
  POST /search                     {"query": "...", "filters": []} -> {"hits": [...]}
  GET  /appstream/<app_id>         detalhes (nome, resumo, descrição HTML, ícone, capturas...)
  GET  /summary/<app_id>           tamanhos (download_size, installed_size)
  GET  /collection/popular         mais instaladas      (?page=&per_page=)
  GET  /collection/category/<C>    por categoria         (?page=&per_page=)
  GET  /collection/category/<C>/subcategories?subcategory=<S>
Cache: ~/.cache/loja/api (JSON, 6 h) e ~/.cache/loja/imagens (ícones e capturas).
"""
import hashlib
import http.client
import json
import os
import re
import socket
import ssl
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from html import unescape

API = os.environ.get("LOJA_API", "https://flathub.org/api/v2")
AGENTE = "Loja-ianinjapelagestao/1.0 (+https://flathub.org)"
VALIDADE = 6 * 3600          # segundos de validade da cache das respostas da API
TEMPO_LIMITE = 20

CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "loja")

# Categorias da página inicial: (nome em pt-PT, categoria do Flathub, subcategoria ou None, ícone)
CATEGORIAS = [
    ("Internet", "Network", None, "applications-internet"),
    ("Música", "AudioVideo", "Audio", "applications-multimedia"),
    ("Jogos", "Game", None, "applications-games"),
    ("Gráficos", "Graphics", None, "applications-graphics"),
    ("Programação", "Development", None, "applications-development"),
    ("Escritório", "Office", None, "applications-office"),
]

# Destaques (aplicações populares; os IDs foram confirmados na API)
DESTAQUES = [
    "org.mozilla.firefox", "com.spotify.Client", "com.discordapp.Discord", "org.videolan.VLC",
    "org.gimp.GIMP", "com.obsproject.Studio", "com.valvesoftware.Steam",
    "org.libreoffice.LibreOffice", "org.telegram.desktop", "org.blender.Blender",
]


class ErroFlathub(Exception):
    """Qualquer falha ao obter dados do Flathub (a interface mostra str(e))."""


class ErroRede(ErroFlathub):
    """Sem ligação: rede em baixo, DNS, tempo esgotado, ligação recusada/cortada."""


class ErroCertificado(ErroFlathub):
    """A ligação TLS falhou (certificado inválido; muitas vezes a data/hora do sistema está errada)."""


class ErroServidor(ErroFlathub):
    """O Flathub respondeu, mas com erro HTTP (não 404) ou com dados inválidos."""


def _contexto_ssl():
    for f in (os.environ.get("SSL_CERT_FILE"), "/etc/pki/tls/certs/ca-bundle.crt",
              "/etc/ssl/certs/ca-certificates.crt"):
        if f and os.path.isfile(f):
            return ssl.create_default_context(cafile=f)
    return ssl.create_default_context()


_SSL = None


def _erro_ligacao(e, url):
    """Converte uma exceção do urllib/socket/ssl na ErroFlathub certa."""
    motivo = getattr(e, "reason", None) or e
    if isinstance(motivo, ssl.SSLCertVerificationError):
        return ErroCertificado(f"o certificado do Flathub não foi aceite ({motivo.verify_message}). "
                               f"Confirme a data e a hora do sistema (comando: date).")
    if isinstance(motivo, ssl.SSLError):
        return ErroCertificado(f"falha na ligação segura (TLS) ao Flathub: {motivo}")
    if isinstance(motivo, socket.gaierror):
        return ErroRede(f"sem ligação ao Flathub: o nome {urllib.parse.urlparse(url).hostname} "
                        f"não foi resolvido (DNS) — {motivo.strerror or motivo}")
    if isinstance(motivo, TimeoutError):
        return ErroRede(f"sem ligação ao Flathub: o servidor não respondeu em {TEMPO_LIMITE} s")
    return ErroRede(f"sem ligação ao Flathub: {getattr(motivo, 'strerror', None) or motivo}")


def _pedido(url, dados=None):
    """GET/POST; devolve os bytes (None se 404). Levanta ErroRede/ErroCertificado/ErroServidor."""
    global _SSL
    cab = {"User-Agent": AGENTE, "Accept": "application/json"}
    corpo = None
    if dados is not None:
        corpo = json.dumps(dados).encode()
        cab["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=corpo, headers=cab, method="POST" if corpo else "GET")
    try:
        if _SSL is None:
            _SSL = _contexto_ssl()
        with urllib.request.urlopen(req, timeout=TEMPO_LIMITE, context=_SSL) as r:
            return r.read()
    except urllib.error.HTTPError as e:      # subclasse de URLError: tem de vir primeiro
        if e.code == 404:
            return None
        raise ErroServidor(f"o Flathub respondeu com o erro HTTP {e.code} {e.reason} ({url})") from e
    except (urllib.error.URLError, http.client.HTTPException, OSError) as e:   # inclui ssl e socket
        raise _erro_ligacao(e, url) from e


def _ficheiro_cache(sub, chave, ext):
    """Caminho do ficheiro de cache (não cria nada; a escrita é que cria as pastas)."""
    h = hashlib.sha1(chave.encode()).hexdigest()
    return os.path.join(CACHE, sub, h + ext)


def _guardar(f, bruto):
    """Escrita atómica (temporário na mesma pasta + os.replace), criando as pastas que faltem.
    Devolve True se ficou guardado; uma falha da cache nunca é erro para quem chama."""
    tmp = None
    try:
        d = os.path.dirname(f)
        os.makedirs(d, exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=d, prefix=".tmp-", suffix=os.path.splitext(f)[1])
        with os.fdopen(fd, "wb") as h:
            h.write(bruto)
        os.replace(tmp, f)
        return True
    except OSError:
        if tmp:
            try:
                os.unlink(tmp)
            except OSError:
                pass
        return False


def _ler_cache(f):
    try:
        with open(f, encoding="utf-8") as h:
            return json.load(h)
    except (OSError, ValueError):
        return None


def _json(caminho, dados=None, validade=VALIDADE):
    """GET/POST à API com cache; devolve o JSON (ou None se 404). Sem rede usa a cache antiga."""
    url = API + caminho
    f = _ficheiro_cache("api", url + (json.dumps(dados, sort_keys=True) if dados else ""), ".json")
    try:
        recente = time.time() - os.path.getmtime(f) < validade
    except OSError:
        recente = False
    if recente:
        obj = _ler_cache(f)
        if obj is not None:
            return obj
    try:
        bruto = _pedido(url, dados)
    except ErroFlathub:
        obj = _ler_cache(f)          # cache antiga é melhor do que nada
        if obj is not None:
            return obj
        raise                        # o erro do pedido (e não o da cache, que não existe)
    if bruto is None:
        return None
    try:
        obj = json.loads(bruto)
    except ValueError as e:
        raise ErroServidor(f"o Flathub devolveu dados inválidos ({url}): {e}") from e
    _guardar(f, json.dumps(obj).encode())
    return obj


def _resumo(hit):
    """Normaliza um resultado da pesquisa/coleção num dicionário pequeno."""
    return {
        "id": hit.get("app_id") or hit.get("id", ""),
        "nome": hit.get("name") or hit.get("app_id", ""),
        "resumo": hit.get("summary") or "",
        "icone": hit.get("icon") or "",
        "programador": hit.get("developer_name") or "",
        "instalacoes": hit.get("installs_last_month") or 0,
        "verificado": bool(hit.get("verification_verified")),
    }


def _so_apps(hits):
    return [_resumo(h) for h in hits
            if h.get("type", "desktop-application") in ("desktop-application", "desktop", "console-application")]


def pesquisar(texto, limite=48):
    texto = texto.strip()
    if not texto:
        return []
    r = _json("/search", {"query": texto, "filters": []}, validade=1800) or {}
    return _so_apps(r.get("hits", []))[:limite]


def categoria(cat, sub=None, quantos=36):
    if sub:
        q = urllib.parse.urlencode({"subcategory": sub, "page": 1, "per_page": quantos})
        r = _json(f"/collection/category/{cat}/subcategories?{q}")
    else:
        r = _json(f"/collection/category/{cat}?page=1&per_page={quantos}")
    return _so_apps((r or {}).get("hits", []))


def populares(quantos=24):
    r = _json(f"/collection/popular?page=1&per_page={quantos}")
    return _so_apps((r or {}).get("hits", []))


def _texto_descricao(html):
    """Descrição do AppStream (HTML simples: p, ul/ol/li, em, code) -> texto para Pango markup."""
    if not html:
        return ""
    t = re.sub(r"\s+", " ", html)
    t = re.sub(r"<li[^>]*>\s*", "\n  •  ", t)
    t = re.sub(r"</p>\s*|</ul>\s*|</ol>\s*", "\n\n", t)
    def marca(nome, m):   # \x01 e \x02 guardam o lugar de < e > das marcas Pango que ficam
        return f"\x01{nome}\x02{m.group(m.lastindex)}\x01/{nome}\x02"
    t = re.sub(r"<(em|i)>(.*?)</\1>", lambda m: marca("i", m), t)
    t = re.sub(r"<(b|strong)>(.*?)</\1>", lambda m: marca("b", m), t)
    t = re.sub(r"<code>(.*?)</code>", lambda m: marca("tt", m), t)
    t = re.sub(r"<[^>]+>", "", t)
    t = unescape(t)
    t = t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    t = t.replace("\x01", "<").replace("\x02", ">")
    t = re.sub(r"[ \t]*\n[ \t]*", "\n", t)
    t = re.sub(r"\n{3,}", "\n\n", t)
    return t.strip()


def _melhor_captura(cap, largura=624):
    tam = cap.get("sizes") or []
    if not tam:
        return None
    def w(s):
        try:
            return int(s.get("width", 0))
        except ValueError:
            return 0
    maiores = [s for s in tam if w(s) >= largura]
    s = min(maiores, key=w) if maiores else max(tam, key=w)
    return s.get("src")


def detalhes(app_id):
    """Detalhes de uma aplicação (ou None se o Flathub não a conhecer)."""
    a = _json(f"/appstream/{urllib.parse.quote(app_id)}")
    if not a:
        return None
    try:
        s = _json(f"/summary/{urllib.parse.quote(app_id)}") or {}
    except ErroFlathub:
        s = {}
    rel = a.get("releases") or []
    urls = a.get("urls") or {}
    return {
        "id": app_id,
        "nome": a.get("name") or app_id,
        "resumo": a.get("summary") or "",
        "descricao": _texto_descricao(a.get("description") or ""),
        "icone": a.get("icon") or "",
        "programador": a.get("developer_name") or "",
        "licenca": a.get("project_license") or "",
        "versao": (rel[0].get("version") if rel else "") or "",
        "site": urls.get("homepage") or "",
        "capturas": [u for u in (_melhor_captura(c) for c in (a.get("screenshots") or [])[:6]) if u],
        "tamanho_download": s.get("download_size") or 0,
        "tamanho_instalado": s.get("installed_size") or 0,
    }


def imagem(url):
    """Caminho local (cache) de uma imagem do Flathub; descarrega se faltar. None se falhar."""
    if not url:
        return None
    ext = os.path.splitext(urllib.parse.urlparse(url).path)[1] or ".png"
    f = _ficheiro_cache("imagens", url, ext)
    try:
        if os.path.getsize(f) > 0:
            return f
    except OSError:
        pass
    try:
        bruto = _pedido(url)
    except ErroFlathub:
        return None
    if not bruto:
        return None
    if _guardar(f, bruto):
        return f
    # cache sem escrita (disco cheio, pasta só de leitura...): mostra-se na mesma, de /tmp
    f = os.path.join(tempfile.gettempdir(), f"loja-{os.getuid()}-" + os.path.basename(f))
    return f if _guardar(f, bruto) else None


def tamanho_legivel(n):
    if not n:
        return "—"
    for u in ("B", "KB", "MB", "GB"):
        if n < 1000 or u == "GB":
            return (f"{n:.0f} {u}" if u in ("B", "KB") else f"{n:.1f} {u}").replace(".", ",")
        n /= 1000
