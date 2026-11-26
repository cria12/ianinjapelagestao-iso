#!/usr/bin/env python3
# scripts/apps/verificar-icones.py — verifica no sistema-alvo (corre DENTRO do chroot, ou no próprio
# sistema live) se os ícones que o Xfce pede existem no tema efetivo (WhiteSur-light por omissão) e se
# o GTK os consegue desenhar. Nomes verificados: Icon= de todos os .desktop (menus, autostart,
# plugins do painel) + nomes de ícones embutidos nos binários do xfce4-session, do painel (plugins
# actions/applicationsmenu/...), do xfce4-notifyd e do xfdesktop + lista fixa dos diálogos de sessão.
# Instalado no sistema como /usr/bin/ianinja-verificar-icones (passo icones-sessao da F8e).
# Uso: python3 verificar-icones.py [--tema WhiteSur-light] [--estrito [NOME...]] [--exigir-png] [--png DIR]
#   --estrito: nomes que TÊM de vir do próprio tema (não de hicolor/Adwaita) e desenhar-se — se algum
#              falhar o script sai com 1 (usado pelo passo icones-sessao da F8e).
#   --png DIR: grava DIR/<tema>-<tamanho>.png com os ícones --estrito desenhados (prova visual).
# Saída: uma linha por nome com problema (FALTA = nem no tema nem nos herdados; HERDADO = só em
# hicolor/Adwaita; ERRO = o ficheiro existe mas não se desenha) e um resumo.
import argparse, glob, os, re, subprocess, sys
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gtk, GdkPixbuf

SESSAO = ["xfsm-logout", "xfsm-reboot", "xfsm-shutdown", "xfsm-suspend", "xfsm-hibernate",
          "xfsm-switch-user", "xfsm-lock", "system-log-out", "system-reboot", "system-shutdown",
          "system-suspend", "system-hibernate", "system-suspend-hibernate", "system-users",
          "system-switch-user", "system-lock-screen"]

ap = argparse.ArgumentParser()
ap.add_argument("--tema", default="WhiteSur-light")
ap.add_argument("--estrito", nargs="*", default=None)
ap.add_argument("--png")
ap.add_argument("--exigir-png", action="store_true",
                help="com --estrito: a 48 e 96 px o ficheiro escolhido tem de ser .png (passo icones-sessao)")
ap.add_argument("--todos", action="store_true", help="mostra também os nomes sem problema")
a = ap.parse_args()

def icones_desktop():
    nomes = set()
    for d in ("/usr/share/applications", "/usr/local/share/applications", "/etc/xdg/autostart",
              "/usr/share/xfce4/panel/plugins"):
        for f in glob.glob(d + "/*.desktop"):
            try:
                for l in open(f, encoding="utf-8", errors="replace"):
                    if l.startswith("Icon="):
                        v = l[5:].strip()
                        if v and not v.startswith("/"):
                            nomes.add(re.sub(r"\.(png|svg|xpm)$", "", v))
            except OSError:
                pass
    return nomes

# nomes de ícones dentro dos binários do Xfce (cadeias que parecem nomes freedesktop/xfce)
PADRAO = re.compile(r"^(xfsm|xfce|xfpm|xfwm|org\.xfce|system|application|preferences|view|window|"
                    r"document|edit|go|list|media|process|user|dialog|emblem|folder|network|"
                    r"battery|audio|notification|appointment|weather|computer|drive|help|image)"
                    r"-[a-z0-9.-]+$")
def icones_binarios():
    nomes = set()
    bins = ["/usr/bin/xfce4-session", "/usr/bin/xfce4-session-logout", "/usr/bin/xfce4-panel",
            "/usr/bin/xfdesktop", "/usr/bin/xfce4-notifyd", "/usr/lib/xfce4/notifyd/xfce4-notifyd"]
    bins += glob.glob("/usr/lib/xfce4/panel/plugins/*.so")
    for b in bins:
        if not os.path.exists(b):
            continue
        try:
            s = subprocess.run(["strings", "-n", "6", b], capture_output=True, text=True).stdout
        except OSError:
            continue
        for l in s.split("\n"):
            l = l.strip()
            if PADRAO.match(l) and not l.endswith((".c", ".h", ".so", ".desktop", ".ui")) \
               and "--" not in l and len(l) < 48:
                nomes.add(l)
    return nomes

t = Gtk.IconTheme.new()
t.set_custom_theme(a.tema)
base = [p for p in t.get_search_path()]
def origem(f):
    for p in base:
        if f.startswith(p.rstrip("/") + "/"):
            return f[len(p.rstrip("/")) + 1:].split("/")[0]
    return "?"

def verifica(n, tam):
    i = t.lookup_icon(n, tam, 0)
    if i is None:
        return "FALTA", None
    f = i.get_filename()
    try:
        pb = i.load_icon()
        if pb is None or pb.get_width() < 1:
            return "ERRO", f
    except Exception as e:
        return "ERRO", "%s (%s)" % (f, e)
    o = origem(f) if f else "embutido"
    return ("OK" if o.lower() == a.tema.lower() else "HERDADO:" + o), f

if a.estrito is not None:
    nomes = a.estrito or SESSAO
    falhas = 0
    for n in nomes:
        for tam in (16, 24, 32, 48, 64, 96):
            r, f = verifica(n, tam)
            if r == "OK" and a.exigir_png and tam in (48, 96) and not str(f).endswith(".png"):
                r = "NAO-PNG"
            if r != "OK":
                falhas += 1
            if r != "OK" or a.todos or tam == 48:
                print("%-8s %-26s %3d  %s" % (r, n, tam, f))
    if a.png:
        os.makedirs(a.png, exist_ok=True)
        for tam in (24, 48):
            W = tam
            dst = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, len(nomes) * (W + 6) + 6, W + 12)
            dst.fill(0xffffffff)
            for k, n in enumerate(nomes):
                try:
                    pb = t.load_icon(n, W, Gtk.IconLookupFlags.FORCE_SIZE)
                    pb.composite(dst, k * (W + 6) + 6, 6, W, W, k * (W + 6) + 6, 6, 1, 1,
                                 GdkPixbuf.InterpType.BILINEAR, 255)
                except Exception:
                    pass
            dst.savev("%s/%s-%d.png" % (a.png, a.tema, tam), "png", [], [])
    print("verificados %d nomes; %d falhas" % (len(nomes), falhas))
    sys.exit(1 if falhas else 0)

nomes = sorted(icones_desktop() | icones_binarios() | set(SESSAO))
contagem = {}
for n in nomes:
    r, f = verifica(n, 48)
    if r == "OK":
        r2, f2 = verifica(n, 16)          # tamanho do painel/menus
        if r2 != "OK":
            r, f = r2 + "@16", f2
    contagem[r.split(":")[0].split("@")[0]] = contagem.get(r.split(":")[0].split("@")[0], 0) + 1
    if r != "OK" or a.todos:
        print("%-22s %-40s %s" % (r, n, f or ""))
print("resumo (%d nomes, tema %s):" % (len(nomes), a.tema),
      ", ".join("%s=%d" % kv for kv in sorted(contagem.items())))
