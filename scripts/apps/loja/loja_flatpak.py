"""loja_flatpak — chamadas ao comando flatpak (modo --user: sem sudo, em ~/.local/share/flatpak)
e estado da sessão live (persistência). Sem GTK: pode ser testado sozinho.

O progresso só é escrito pelo flatpak quando a saída é um terminal: as operações correm num
pseudo-terminal (módulo pty) e lê-se o texto "Installing 2/3… ████  45%" (LC_ALL=C.UTF-8).
Variáveis para testes: LOJA_FLATPAK=<caminho do binário flatpak>.
"""
import os
import pty
import re
import shutil
import signal
import subprocess

FLATPAK = os.environ.get("LOJA_FLATPAK") or shutil.which("flatpak") or "flatpak"
REMOTE = "flathub"
FLATHUB_REPO = "/usr/share/loja/flathub.flatpakrepo"
FLATHUB_URL = "https://dl.flathub.org/repo/flathub.flatpakrepo"

_ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
_PROG = re.compile(r"(Installing|Updating|Uninstalling)\s*(?:(\d+)/(\d+))?\S*\s.*?(\d{1,3})%")
_FASE = re.compile(r"^(Installing|Updating|Uninstalling)\s+(?:(\d+)/(\d+))?")


def _env():
    e = dict(os.environ)
    e["LC_ALL"] = "C.UTF-8"
    e.pop("LANGUAGE", None)
    return e


def disponivel():
    return bool(shutil.which(FLATPAK) or os.access(FLATPAK, os.X_OK))


def _correr(args, tempo=120):
    r = subprocess.run([FLATPAK] + args, capture_output=True, text=True, env=_env(), timeout=tempo)
    return r.returncode, r.stdout, r.stderr


def preparar_remote():
    """Garante o remote flathub na instalação do utilizador (ficheiro local: não usa a rede)."""
    rc, out, _ = _correr(["remote-list", "--user", "--columns=name"])
    if rc == 0 and REMOTE in out.split():
        return True, ""
    origem = FLATHUB_REPO if os.path.exists(FLATHUB_REPO) else FLATHUB_URL
    rc, _, err = _correr(["remote-add", "--user", "--if-not-exists", REMOTE, origem])
    return rc == 0, err.strip()


def _tabela(out, ncol):
    linhas = []
    for l in out.splitlines():
        p = l.split("\t")
        if len(p) >= ncol and p[0]:
            linhas.append(p[:ncol])
    return linhas


def instaladas():
    """Aplicações instaladas (utilizador e sistema): lista de dicionários."""
    rc, out, _ = _correr(["list", "--app", "--columns=application,name,version,size,installation,origin"])
    if rc != 0:
        return []
    r = []
    for a, n, v, s, inst, orig in _tabela(out, 6):
        r.append({"id": a, "nome": n or a, "versao": v, "tamanho": s,
                  "instalacao": inst, "origem": orig})
    return sorted(r, key=lambda x: x["nome"].lower())


def ids_instalados():
    return {a["id"]: a["instalacao"] for a in instaladas()}


def atualizacoes():
    """Aplicações do utilizador com atualização no Flathub (precisa de rede)."""
    rc, out, err = _correr(["remote-ls", "--user", "--updates", "--app",
                            "--columns=application,name,version"], tempo=180)
    if rc != 0:
        raise RuntimeError(err.strip() or "flatpak remote-ls falhou")
    return [{"id": a, "nome": n or a, "versao": v} for a, n, v in _tabela(out, 3)]


def icone_instalado(app_id):
    """Ícone exportado pela aplicação instalada (se houver)."""
    bases = [os.path.join(os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"),
                          "flatpak/exports/share/icons/hicolor"),
             "/var/lib/flatpak/exports/share/icons/hicolor"]
    for b in bases:
        for t in ("128x128", "256x256", "scalable", "64x64", "512x512", "48x48"):
            for ext in (".png", ".svg"):
                f = os.path.join(b, t, "apps", app_id + ext)
                if os.path.exists(f):
                    return f
    return None


def abrir(app_id):
    subprocess.Popen([FLATPAK, "run", app_id], stdin=subprocess.DEVNULL,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def interpretar(texto, estado):
    """Lê um pedaço da saída do flatpak e atualiza estado = {"fracao", "texto"}; devolve True se mudou."""
    mudou = False
    for parte in re.split(r"[\r\n]+", _ANSI.sub("", texto)):
        parte = parte.strip()
        if not parte:
            continue
        m = _PROG.search(parte)
        if m:
            i, n, pct = int(m.group(2) or 1), int(m.group(3) or 1), min(int(m.group(4)), 100)
            estado["fracao"] = max(0.0, min(1.0, ((i - 1) + pct / 100) / max(n, 1)))
            verbo = {"Installing": "A instalar", "Updating": "A atualizar",
                     "Uninstalling": "A remover"}[m.group(1)]
            estado["texto"] = f"{verbo} {i} de {n}… {pct}%" if n > 1 else f"{verbo}… {pct}%"
            mudou = True
        elif parte.startswith("Looking for matches"):
            estado["texto"] = "A procurar no Flathub…"
            mudou = True
        elif parte.startswith(("error:", "Error:")):
            estado["erro"] = parte.split(":", 1)[1].strip()
            mudou = True
    return mudou


class Operacao:
    """Uma operação do flatpak num pseudo-terminal, lida aos bocados (para a barra de progresso)."""

    def __init__(self, args):
        self.args = [FLATPAK] + args
        self.estado = {"fracao": 0.0, "texto": "A preparar…"}
        self.saida = ""
        self.pid = None
        self.fd = None

    def iniciar(self):
        pid, fd = pty.fork()
        if pid == 0:
            try:
                os.execvpe(self.args[0], self.args, _env())
            finally:
                os._exit(127)
        self.pid, self.fd = pid, fd

    def ler(self):
        """Lê o que houver; devolve False quando o processo terminou."""
        try:
            b = os.read(self.fd, 4096)
        except OSError:
            b = b""
        if not b:
            return False
        t = b.decode("utf-8", "replace")
        self.saida += t
        interpretar(t, self.estado)
        return True

    def terminar(self):
        try:
            os.close(self.fd)
        except OSError:
            pass
        _, st = os.waitpid(self.pid, 0)
        return os.waitstatus_to_exitcode(st)

    def cancelar(self):
        if self.pid:
            try:
                os.kill(self.pid, signal.SIGINT)
            except ProcessLookupError:
                pass

    def erro(self):
        if self.estado.get("erro"):
            return self.estado["erro"]
        linhas = [l.strip() for l in _ANSI.sub("", self.saida).splitlines() if l.strip()]
        return linhas[-1] if linhas else "o flatpak terminou com erro"


def op_instalar(app_id):
    return Operacao(["install", "--user", "-y", REMOTE, app_id])


def op_remover(app_id, sistema=False):
    return Operacao(["uninstall", "--system" if sistema else "--user", "-y", app_id])


def op_atualizar(app_id=None):
    return Operacao(["update", "--user", "-y"] + ([app_id] if app_id else []))


# --- sessão live do ianinjapelagestao (ver scripts/live-init.sh)
def sessao_live():
    return os.path.ismount("/run/live/iso")


def com_persistencia():
    return os.path.ismount("/mnt/dados") or os.path.ismount("/run/live/dados")


def espaco_livre():
    d = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    while not os.path.exists(d):
        d = os.path.dirname(d)
    return shutil.disk_usage(d).free
