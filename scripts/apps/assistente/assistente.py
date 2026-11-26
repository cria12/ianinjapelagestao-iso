#!/usr/bin/python3
"""Assistente de configuração do ianinjapelagestao (Python 3 + GTK 3, pt-PT).

Corre no 1.º arranque no lugar do ecrã de entrada (greeter do LightDM, como utilizador lightdm):
pede o nome, o nome de utilizador, a senha, o teclado e o fuso horário e onde guardar os dados
(scripts/apps/persistencia/CONTRATO.md), cria a conta (pelo sudo, com
/usr/libexec/ianinja-assistente/aplicar), prepara o armazenamento escolhido e entra logo na sessão
Xfce dessa conta através do próprio LightDM. "Experimentar sem criar conta" entra como ninja (modo live).

Modos:
  --greeter              dentro do LightDM (ecrã inteiro, sem gestor de janelas)
  --janela [--raiz DIR]  janela normal (testes); com --raiz cria a conta nessa raiz (root);
                         sem --raiz só simula
  --texto [--raiz DIR]   o mesmo em modo de texto (consola, como root)
  --captura PNG --pagina N|NOME [--largura L --altura A]   desenha a página com dados de exemplo
                         (nomes extra: dados-particao, dados-vazio, armazenar-erro)
  IANINJA_SIMULAR_DADOS=ativo|vazio|falha|erro   comportamento do armazenamento simulado
  --verificar            importa GTK/LightDM, lê o CSS e testa a validação (sem ecrã)
Qualquer erro antes de falar com o LightDM, no modo --greeter, passa o ecrã ao lightdm-gtk-greeter.
"""
import argparse
import json
import os
import subprocess
import sys
import threading
import time

DIR = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, DIR)
import contas  # noqa: E402

GREETER_GTK = "/usr/bin/lightdm-gtk-greeter"
APLICAR = "/usr/libexec/ianinja-assistente/aplicar"
SUDO = "/usr/bin/sudo"
FUNDO = os.environ.get("IANINJA_ASSISTENTE_FUNDO", "/usr/share/backgrounds/ianinja/ianinja-claro.svg")
CSS = os.path.join(DIR, "estilo.css")
PAGINAS = ["inicio", "regiao", "dados", "conta", "resumo", "criar", "armazenar", "reiniciar", "pronto"]
PASSOS = ["inicio", "regiao", "dados", "conta", "resumo"]  # páginas com ponto no indicador
DADOS_EM = "Dados guardados em"

Gtk = Gdk = GLib = GdkPixbuf = None


def importar_gtk():
    global Gtk, Gdk, GLib, GdkPixbuf
    import gi
    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    from gi.repository import Gtk as _Gtk, Gdk as _Gdk, GLib as _GLib, GdkPixbuf as _Pix
    Gtk, Gdk, GLib, GdkPixbuf = _Gtk, _Gdk, _GLib, _Pix


def ir_para_greeter_gtk(motivo=""):
    """Substitui este processo pelo greeter normal (os descritores do LightDM passam tal qual)."""
    if motivo:
        print(f"ianinja-assistente: {motivo}; a passar ao lightdm-gtk-greeter", file=sys.stderr)
    sys.stderr.flush()
    os.execv(GREETER_GTK, [GREETER_GTK])


# ------------------------------------------------------------------ operações privilegiadas

class BackendGreeter:
    """Dentro do LightDM o greeter é o utilizador lightdm: o que precisa de root vai pelo sudo
    (/etc/sudoers.d/ianinja-assistente: só este programa, sem senha)."""

    def _sudo(self, acao, entrada=None):
        r = subprocess.run([SUDO, "-n", APLICAR, acao], input=entrada, capture_output=True,
                           text=True, timeout=180)
        out = (r.stdout or "").strip()
        if r.returncode != 0:
            msg = out[6:] if out.startswith("ERRO: ") else (out or (r.stderr or "").strip())
            raise contas.ErroAssistente(msg or f"código {r.returncode}")
        return out

    def criar(self, d):
        return self._sudo("criar", json.dumps(d))

    def experimentar(self):
        self._sudo("experimentar")

    # guardar os dados (scripts/apps/persistencia/CONTRATO.md)
    def persistencia_estado(self):
        return json.loads(self._sudo("persistencia-estado"))

    def persistencia_listar(self):
        return json.loads(self._sudo("persistencia-listar") or "[]")

    def persistencia_criar(self, oid, tamanho_mb, confirmo, progresso):
        entrada = json.dumps({"id": oid, "tamanho_mb": tamanho_mb, "confirmo_apagar": bool(confirmo)})
        return ler_progresso([SUDO, "-n", APLICAR, "persistencia-criar"], entrada, progresso)

    def pode_reiniciar(self):
        # sem logind/ConsoleKit o LightDM.get_can_restart() é sempre False; o aplicar
        # só aceita "reiniciar" depois de um persistencia-criar com OK neste arranque
        return os.access(APLICAR, os.X_OK)

    def reiniciar(self):
        self._sudo("reiniciar")


PERSISTENCIA = "/usr/sbin/ianinja-persistencia"


def ler_progresso(cmd, entrada, progresso):
    """Corre o 'criar' do backend e lê o stdout linha a linha (PROGRESSO n texto / OK id / ERRO texto).
    progresso(n, texto) é chamado nesta thread (quem chama passa-o à UI com GLib.idle_add)."""
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE if entrada is not None else subprocess.DEVNULL,
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
    if entrada is not None:
        p.stdin.write(entrada)
        p.stdin.close()
    ok, erro, ultima = None, None, ""
    for linha in p.stdout:
        linha = linha.rstrip("\n")
        if linha.startswith("PROGRESSO "):
            partes = linha.split(" ", 2)
            try:
                n = max(0, min(100, int(partes[1])))
            except (IndexError, ValueError):
                continue
            progresso(n, partes[2] if len(partes) > 2 else "")
        elif linha.startswith("OK"):
            ok = linha[2:].strip()
        elif linha.startswith("ERRO"):
            erro = linha[4:].lstrip(":").strip()
        elif linha.strip():
            ultima = linha.strip()
    rc = p.wait()
    if rc != 0 or erro is not None or ok is None:
        raise contas.ErroAssistente(erro or ultima or f"código {rc}")
    return ok


class BackendLocal:
    def __init__(self, raiz):
        self.raiz = raiz

    def criar(self, d):
        return contas.aplicar(d, self.raiz)

    def experimentar(self):
        print("(teste) experimentar: nada a fazer fora do sistema")

    # como root e só na raiz real: chama o backend diretamente
    def _persistencia(self, *args):
        if self.raiz not in (None, "/") or os.geteuid() != 0 or not os.access(PERSISTENCIA, os.X_OK):
            raise contas.ErroAssistente("guardar os dados só está disponível no sistema em execução")
        r = subprocess.run([PERSISTENCIA, *args], capture_output=True, text=True, timeout=120)
        if r.returncode != 0:
            raise contas.ErroAssistente((r.stdout or r.stderr or f"código {r.returncode}").strip())
        return r.stdout

    def persistencia_estado(self):
        return json.loads(self._persistencia("estado", "--json"))

    def persistencia_listar(self):
        return json.loads(self._persistencia("listar", "--json") or "[]")

    def persistencia_criar(self, oid, tamanho_mb, confirmo, progresso):
        cmd = [PERSISTENCIA, "criar", oid]
        if tamanho_mb:
            cmd += ["--tamanho-mb", str(int(tamanho_mb))]
        if confirmo:
            cmd.append("--confirmo-apagar")
        return ler_progresso(cmd, None, progresso)

    def pode_reiniciar(self):
        return False  # modo de teste: nunca reinicia a máquina

    def reiniciar(self):
        print("(teste) reiniciaria o computador")


OPCOES_EXEMPLO = [
    {"id": "pen:/dev/sdb", "tipo": "pen", "titulo": "Esta pen USB (SanDisk 32 GB)",
     "detalhe": "27,8 GB livres no espaço que a imagem não usa", "max_mb": 28467, "sugerido_mb": 28467,
     "apaga": False, "recomendado": True},
    {"id": "ficheiro:/dev/nvme0n1p3", "tipo": "ficheiro", "titulo": "Disco do Windows (C:, 512 GB)",
     "detalhe": "Um ficheiro \\ianinja\\ianinja-dados.img; 214 GB livres, o Windows não é alterado",
     "max_mb": 219136, "sugerido_mb": 32768, "apaga": False, "recomendado": False},
    {"id": "particao:/dev/sdc1", "tipo": "particao", "titulo": "Disco externo (Toshiba 1 TB)",
     "detalhe": "Partição inteira de 931 GB formatada para o ianinjapelagestao", "max_mb": 953344,
     "sugerido_mb": 953344, "apaga": True, "recomendado": False},
]


class BackendSimulado:
    """Sem tocar no sistema. IANINJA_SIMULAR_DADOS=ativo|vazio|falha|erro muda o comportamento."""

    def __init__(self):
        self.modo = os.environ.get("IANINJA_SIMULAR_DADOS", "")
        self.tentativas = 0

    def criar(self, d):
        time.sleep(1.2)
        return "OK (simulado: nada foi alterado)"

    def experimentar(self):
        time.sleep(0.5)

    def persistencia_estado(self):
        return {"ativo": self.modo == "ativo", "tipo": None, "dispositivo": "", "livre_mb": 0, "total_mb": 0}

    def persistencia_listar(self):
        time.sleep(0.3)
        if self.modo == "falha":
            raise contas.ErroAssistente("o programa ianinja-persistencia não respondeu")
        return [] if self.modo == "vazio" else [dict(o) for o in OPCOES_EXEMPLO]

    def persistencia_criar(self, oid, tamanho_mb, confirmo, progresso):
        self.tentativas += 1
        passos = [(5, "A preparar o disco…"), (20, "A criar o sistema de ficheiros…"),
                  (45, "A copiar a sua conta e as definições…"), (80, "A copiar os programas…"),
                  (100, "Concluído")]
        for n, t in passos:
            if self.modo == "erro" and self.tentativas == 1 and n >= 45:
                raise contas.ErroAssistente("não há espaço suficiente no destino (simulado)")
            progresso(n, t)
            time.sleep(0.6)
        return oid

    def pode_reiniciar(self):
        return True

    def reiniciar(self):
        print("(teste) reiniciaria o computador")
        Gtk.main_quit()


class SessaoLightDM:
    """Entra na sessão Xfce pelo protocolo do greeter (liga-se ao LightDM só quando é preciso,
    para que um erro antes disso possa passar o ecrã ao lightdm-gtk-greeter)."""

    def __init__(self):
        self.g = None

    def entrar(self, utilizador, senha, erro_cb):
        import gi
        gi.require_version("LightDM", "1")
        from gi.repository import LightDM
        self.senha, self.erro_cb = senha, erro_cb
        if self.g is None:
            self.g = LightDM.Greeter()
            self.g.connect("show-prompt", self._pedido)
            self.g.connect("show-message", lambda g, t, tipo: print("LightDM:", t, file=sys.stderr))
            self.g.connect("authentication-complete", self._completo)
            self.g.connect_to_daemon_sync()
        if self.g.get_in_authentication():
            self.g.cancel_authentication()
        self.g.authenticate(utilizador)

    def _pedido(self, g, texto, tipo):
        g.respond(self.senha)

    def _completo(self, g):
        if g.get_is_authenticated():
            try:
                g.start_session_sync(contas.SESSAO)
                # o LightDM pára o greeter quando a sessão arranca
            except Exception as e:  # noqa: BLE001
                self.erro_cb(f"a sessão não arrancou: {e}")
        else:
            self.erro_cb("o LightDM não aceitou a senha")


class SessaoSimulada:
    def entrar(self, utilizador, senha, erro_cb):
        print(f"(teste) entraria na sessão {contas.SESSAO} como {utilizador}")
        GLib.timeout_add(600, Gtk.main_quit)


# ------------------------------------------------------------------ interface

def rotulo(texto, classes=(), xalign=0.0, wrap=True, markup=False):
    l = Gtk.Label()
    if markup:
        l.set_markup(texto)
    else:
        l.set_text(texto)
    l.set_xalign(xalign)
    if xalign == 0.5:
        l.set_justify(Gtk.Justification.CENTER)
    l.set_line_wrap(wrap)
    if wrap:
        l.set_max_width_chars(58)
    for c in classes:
        l.get_style_context().add_class(c)
    return l


def botao(texto, classe):
    b = Gtk.Button.new_with_mnemonic(texto)
    b.get_style_context().add_class(classe)
    return b


def icone(nomes, tamanho):
    tema = Gtk.IconTheme.get_default()
    for n in nomes:
        if tema.has_icon(n):
            return Gtk.Image.new_from_icon_name(n, Gtk.IconSize.DIALOG) if tamanho <= 48 else \
                Gtk.Image.new_from_pixbuf(tema.load_icon(n, tamanho, 0))
    return Gtk.Image()


class Assistente:
    def __init__(self, janela, backend, sessao, greeter=False, live=None, consultar=True):
        self.win, self.backend, self.sessao, self.greeter = janela, backend, sessao, greeter
        self.live = contas.sessao_live() and not contas.com_persistencia() if live is None else live
        self.dados = {"nome_completo": "", "utilizador": "", "senha": "", "autologin": False,
                      "senha_root": True, "teclado": contas.TECLADO_OMISSAO, "fuso": contas.FUSO_OMISSAO}
        self.utilizador_editado = False
        self.tocados = set()
        self._fundo_cache = None
        # onde guardar os dados: "a_verificar" (à espera do backend), "pronto" (página visível),
        # "ativo" (já há armazenamento: sem página) ou "nao" (sem backend capaz: sem página)
        self.dados_modo = "a_verificar"
        self.dados_opcoes, self.dados_erro, self.dados_estado = [], None, {}
        self.destino = None          # opção escolhida (dict) ou None = não guardar
        self.tamanhos = {}           # id -> GB escolhidos (mantém-se ao trocar de opção)
        self.pagina = None

        overlay = Gtk.Overlay()
        fundo = Gtk.DrawingArea()
        fundo.connect("draw", self._desenhar_fundo)
        overlay.add(fundo)

        self.cartao = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        self.cartao.get_style_context().add_class("assist-cartao")
        self.cartao.set_halign(Gtk.Align.CENTER)
        self.cartao.set_valign(Gtk.Align.CENTER)
        self.cartao.set_size_request(600, -1)
        overlay.add_overlay(self.cartao)

        self.pontos = Gtk.Box(spacing=6, halign=Gtk.Align.CENTER)
        self.lista_pontos = []
        for _ in PASSOS:
            p = Gtk.Box()
            p.set_no_show_all(True)
            p.get_style_context().add_class("assist-ponto")
            p.set_valign(Gtk.Align.CENTER)
            self.pontos.pack_start(p, False, False, 0)
            self.lista_pontos.append(p)
        self.cartao.pack_start(self.pontos, False, False, 0)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(220)
        self.stack.set_vhomogeneous(False)
        self.stack.set_interpolate_size(True)
        self.cartao.pack_start(self.stack, True, True, 0)

        # o rodapé (Voltar/Continuar) só é mostrado por ir(): set_no_show_all impede que o
        # win.show_all() o mostre na página de início (aparecia "Voltar" no 1.º passo e um
        # "Continuar" ao lado de "Criar a minha conta")
        self.rodape = Gtk.Box(spacing=10)
        self.rodape.set_no_show_all(True)
        self.b_voltar = botao("_Voltar", "assist-secundario")
        self.b_voltar.connect("clicked", lambda *_: self.voltar())
        self.b_seguir = botao("_Continuar", "assist-principal")
        self.b_seguir.connect("clicked", lambda *_: self.seguir())
        self.rodape.pack_start(self.b_voltar, False, False, 0)
        self.rodape.pack_end(self.b_seguir, False, False, 0)
        self.b_voltar.show()
        self.b_seguir.show()
        self.cartao.pack_start(self.rodape, False, False, 0)

        self._pagina_inicio()
        self._pagina_regiao()
        self._pagina_dados()
        self._pagina_conta()
        self._pagina_resumo()
        self._pagina_criar()
        self._pagina_armazenar()
        self._pagina_reiniciar()
        self._pagina_pronto()
        self.win.add(overlay)
        self.ir("inicio")
        if consultar:
            self._em_fundo(self._consultar_persistencia, self._persistencia_lida)

    # ------------------------------------------------ fundo
    def _desenhar_fundo(self, area, cr):
        w, h = area.get_allocated_width(), area.get_allocated_height()
        if self._fundo_cache is None or self._fundo_cache[0] != (w, h):
            pix = None
            try:
                orig = GdkPixbuf.Pixbuf.new_from_file(FUNDO)
                esc = max(w / orig.get_width(), h / orig.get_height())
                pix = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                    FUNDO, int(orig.get_width() * esc) + 1, int(orig.get_height() * esc) + 1, False)
            except Exception:  # noqa: BLE001
                pix = None
            self._fundo_cache = ((w, h), pix)
        pix = self._fundo_cache[1]
        if pix is not None:
            Gdk.cairo_set_source_pixbuf(cr, pix, (w - pix.get_width()) / 2, (h - pix.get_height()) / 2)
            cr.paint()
        else:
            import cairo
            g = cairo.LinearGradient(0, 0, w, h)
            g.add_color_stop_rgb(0, 0.80, 0.87, 0.98)
            g.add_color_stop_rgb(1, 0.93, 0.86, 0.97)
            cr.set_source(g)
            cr.paint()
        return False

    # ------------------------------------------------ páginas
    def _caixa(self, nome):
        b = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.stack.add_named(b, nome)
        return b

    def _pagina_inicio(self):
        b = self._caixa("inicio")
        img = icone(["system-users", "avatar-default", "user-info", "preferences-desktop-personal"], 96)
        img.set_margin_top(4)
        b.pack_start(img, False, False, 0)
        b.pack_start(rotulo("Bem-vindo ao ianinjapelagestao", ("assist-titulo",), 0.5), False, False, 0)
        b.pack_start(rotulo("Vamos criar a sua conta: o seu nome, um nome de utilizador e uma senha "
                            "para entrar no sistema. Demora menos de um minuto.",
                            ("assist-subtitulo", "assist-dim"), 0.5), False, False, 0)
        comecar = botao("_Criar a minha conta", "assist-principal")
        comecar.set_halign(Gtk.Align.CENTER)
        comecar.set_margin_top(10)
        comecar.connect("clicked", lambda *_: self.ir("regiao"))
        b.pack_start(comecar, False, False, 0)
        exp = botao("_Experimentar sem criar conta", "assist-ligacao")
        exp.set_halign(Gtk.Align.CENTER)
        exp.connect("clicked", lambda *_: self.experimentar())
        b.pack_start(exp, False, False, 0)
        b.pack_start(rotulo("Entra como ninja (modo live). O assistente volta a aparecer no próximo "
                            "arranque enquanto não houver uma conta.", ("assist-pequeno", "assist-dim"), 0.5),
                     False, False, 0)
        self.b_comecar = comecar

    def _pagina_regiao(self):
        b = self._caixa("regiao")
        b.pack_start(rotulo("Teclado e fuso horário", ("assist-titulo",)), False, False, 0)
        b.pack_start(rotulo("Escolha a disposição do seu teclado e a hora do sítio onde está.",
                            ("assist-subtitulo", "assist-dim")), False, False, 6)
        b.pack_start(rotulo("Teclado", ("assist-rotulo",)), False, False, 0)
        self.c_teclado = Gtk.ComboBoxText()
        for tid, (nome, _x, _k) in contas.TECLADOS.items():
            self.c_teclado.append(tid, nome)
        self.c_teclado.set_active_id(self.dados["teclado"])
        self.c_teclado.connect("changed", self._teclado_mudou)
        b.pack_start(self.c_teclado, False, False, 0)
        self.e_testar = Gtk.Entry(placeholder_text="Experimente aqui o teclado: ç á ã õ @ ~ ´")
        b.pack_start(self.e_testar, False, False, 0)
        b.pack_start(rotulo("Fuso horário", ("assist-rotulo",)), False, False, 6)
        self.c_fuso = Gtk.ComboBoxText()
        for fid, nome in contas.FUSOS:
            self.c_fuso.append(fid, nome)
        self.c_fuso.set_active_id(self.dados["fuso"])
        self.c_fuso.connect("changed", lambda c: self.dados.__setitem__("fuso", c.get_active_id()))
        b.pack_start(self.c_fuso, False, False, 0)

    # ------------------------------------------------ onde guardar os dados
    def _pagina_dados(self):
        b = self._caixa("dados")
        b.pack_start(rotulo("Onde guardar os seus dados?", ("assist-titulo",)), False, False, 0)
        b.pack_start(rotulo("O sistema está a correr de uma pen. Escolha onde ficam a sua conta, fotos, "
                            "vídeos, documentos, programas e senhas do Wi-Fi, para não se perderem "
                            "ao desligar.", ("assist-subtitulo", "assist-dim")), False, False, 4)

        self.d_carregar = Gtk.Box(spacing=10, halign=Gtk.Align.CENTER)
        self.d_carregar.set_no_show_all(True)
        self.d_spinner = Gtk.Spinner()
        self.d_carregar.pack_start(self.d_spinner, False, False, 0)
        self.d_carregar.pack_start(rotulo("A procurar pens e discos…", ("assist-dim",), wrap=False),
                                   False, False, 0)
        self.d_carregar.set_margin_top(14)
        self.d_carregar.set_margin_bottom(14)
        b.pack_start(self.d_carregar, False, False, 0)

        self.d_info = Gtk.Box()
        self.d_info.get_style_context().add_class("assist-info")
        self.l_info = rotulo("", ("assist-pequeno",))
        self.d_info.pack_start(self.l_info, True, True, 0)
        self.d_info.set_no_show_all(True)
        self.l_info.show()
        b.pack_start(self.d_info, False, False, 0)

        self.d_lista = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        rol = Gtk.ScrolledWindow()
        rol.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        rol.set_propagate_natural_height(True)
        rol.set_max_content_height(340)
        rol.add(self.d_lista)
        b.pack_start(rol, False, False, 0)

        # tamanho (pen e ficheiro): escala + caixa numérica com o mesmo ajuste, em GB
        self.d_tamanho = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.d_tamanho.set_no_show_all(True)
        self.adj_tamanho = Gtk.Adjustment(value=8, lower=1, upper=8, step_increment=1, page_increment=4)
        self.adj_tamanho.connect("value-changed", self._tamanho_mudou)
        l_tam = Gtk.Label.new_with_mnemonic("_Espaço para os seus dados (GB)")
        l_tam.set_xalign(0)
        l_tam.get_style_context().add_class("assist-rotulo")
        linha = Gtk.Box(spacing=12)
        self.s_tamanho = Gtk.Scale(orientation=Gtk.Orientation.HORIZONTAL, adjustment=self.adj_tamanho)
        self.s_tamanho.set_digits(0)
        self.s_tamanho.set_draw_value(False)
        self.s_tamanho.set_hexpand(True)
        self.n_tamanho = Gtk.SpinButton(adjustment=self.adj_tamanho, climb_rate=1, digits=0)
        self.n_tamanho.set_numeric(True)
        self.n_tamanho.set_width_chars(6)
        l_tam.set_mnemonic_widget(self.n_tamanho)
        linha.pack_start(self.s_tamanho, True, True, 0)
        linha.pack_start(self.n_tamanho, False, False, 0)
        self.l_tam_ajuda = rotulo("", ("assist-pequeno", "assist-dim"))
        for w in (l_tam, linha, self.l_tam_ajuda):
            self.d_tamanho.pack_start(w, False, False, 0)
            w.show_all()
        self.d_tamanho.set_margin_top(6)
        b.pack_start(self.d_tamanho, False, False, 0)

        # partição inteira: aviso vermelho e confirmação obrigatória
        self.d_perigo = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.d_perigo.get_style_context().add_class("assist-perigo")
        self.d_perigo.set_no_show_all(True)
        self.l_perigo = rotulo("", ("assist-pequeno",))
        self.k_apagar = Gtk.CheckButton.new_with_mnemonic("Co_mpreendo que tudo nesse disco é apagado")
        self.k_apagar.connect("toggled", lambda *_: self._validar_dados())
        for w in (self.l_perigo, self.k_apagar):
            self.d_perigo.pack_start(w, False, False, 0)
            w.show_all()
        b.pack_start(self.d_perigo, False, False, 4)
        self.radios = []
        self._encher_opcoes()

    def _consultar_persistencia(self):
        """Na thread: estado e lista de destinos. Uma exceção em estado = sem backend capaz."""
        est = self.backend.persistencia_estado() or {}
        if est.get("ativo"):
            return "ativo", est, None, []
        try:
            lst = [o for o in (self.backend.persistencia_listar() or [])
                   if isinstance(o, dict) and o.get("id")]
            return "pronto", est, None, lst
        except Exception as e:  # noqa: BLE001
            return "pronto", est, str(e), []

    def _persistencia_lida(self, ok, r):
        if not ok:
            print(f"ianinja-assistente: guardar os dados indisponível: {r}", file=sys.stderr)
            self.dados_modo = "nao"
        else:
            self.dados_modo, self.dados_estado, self.dados_erro, self.dados_opcoes = r
        self._encher_opcoes()
        if self.pagina == "dados" and self.dados_modo != "pronto":
            self.ir("conta")
        elif self.pagina in PASSOS:
            self.ir(self.pagina)  # atualiza os pontos e o botão Continuar
        return False

    def _cartao_opcao(self, grupo, titulo, detalhe, etiqueta=None, perigo=False, mnemonica=False):
        rb = Gtk.RadioButton.new_from_widget(grupo)
        rb.get_style_context().add_class("assist-opcao")
        caixa = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        topo = Gtk.Box(spacing=8)
        if mnemonica:
            lt = Gtk.Label.new_with_mnemonic(titulo)
            lt.set_mnemonic_widget(rb)
        else:
            lt = Gtk.Label(label=titulo)
        lt.set_xalign(0)
        lt.set_line_wrap(True)
        lt.set_max_width_chars(46)
        lt.get_style_context().add_class("assist-opcao-titulo")
        topo.pack_start(lt, False, False, 0)
        if etiqueta:
            le = Gtk.Label(label=etiqueta)
            le.set_valign(Gtk.Align.CENTER)
            le.get_style_context().add_class("assist-etiqueta-perigo" if perigo else "assist-etiqueta")
            topo.pack_start(le, False, False, 0)
        caixa.pack_start(topo, False, False, 0)
        if detalhe:
            caixa.pack_start(rotulo(detalhe, ("assist-pequeno", "assist-dim")), False, False, 0)
        rb.add(caixa)
        acc = rb.get_accessible()
        if acc is not None:
            acc.set_name(titulo.replace("_", "") + (f" ({etiqueta})" if etiqueta else ""))
            acc.set_description(detalhe or "")
        rb.connect("toggled", self._opcao_mudou)
        return rb

    def _encher_opcoes(self):
        for f in self.d_lista.get_children():
            f.destroy()
        self.radios = []
        a_verificar = self.dados_modo == "a_verificar"
        if a_verificar:
            for f in self.d_carregar.get_children():
                f.show()
            self.d_carregar.show()  # show_all() não faz nada num widget com no_show_all
            self.d_spinner.start()
        else:
            self.d_spinner.stop()
            self.d_carregar.hide()
        if self.dados_modo != "pronto":
            self.d_info.hide()
            self.d_tamanho.hide()
            self.d_perigo.hide()
            return
        grupo = None
        escolhida = None
        for o in self.dados_opcoes:
            apaga = self._apaga(o)
            etiqueta = "Apaga o disco" if apaga else ("Recomendado" if o.get("recomendado") else None)
            rb = self._cartao_opcao(grupo, str(o.get("titulo") or o["id"]), str(o.get("detalhe") or ""),
                                    etiqueta, perigo=apaga)
            rb.opcao = o
            grupo = grupo or rb
            self.radios.append(rb)
            self.d_lista.pack_start(rb, False, False, 0)
            if escolhida is None and o.get("recomendado") and not apaga:
                escolhida = rb
        nao = self._cartao_opcao(grupo, "_Não guardar — tudo se perde ao desligar",
                                 "A conta, os ficheiros e as definições só duram até desligar o computador; "
                                 "o assistente volta a aparecer no próximo arranque.", mnemonica=True)
        nao.opcao = None
        self.radios.append(nao)
        self.d_lista.pack_start(nao, False, False, 0)
        if self.dados_erro or not self.dados_opcoes:
            motivo = f" ({self.dados_erro})" if self.dados_erro else ""
            self.l_info.set_text("Não foi encontrado nenhum sítio onde guardar os seus dados" + motivo + ". "
                                 "Pode continuar sem guardar; mais tarde ligue uma pen ou um disco com "
                                 "espaço livre e reinicie: o assistente volta a perguntar.")
            self.d_info.show()
        else:
            self.d_info.hide()
        # mantém a escolha anterior (ao voltar atrás); senão a recomendada; senão "Não guardar"
        anterior = self.destino["id"] if self.destino else None
        for r in self.radios:
            if r.opcao and r.opcao["id"] == anterior:
                escolhida = r
        (escolhida or nao).set_active(True)
        self.d_lista.show_all()
        self._opcao_mudou(None)

    @staticmethod
    def _apaga(o):
        return bool(o) and (bool(o.get("apaga")) or o.get("tipo") == "particao")

    def _opcao_escolhida(self):
        for r in self.radios:
            if r.get_active():
                return r.opcao
        return None

    def _opcao_mudou(self, rb):
        if rb is not None and not rb.get_active():
            return  # o botão que ficou ativo trata do sinal
        o = self._opcao_escolhida()
        if o and o.get("tipo") in ("pen", "ficheiro"):
            max_mb = max(1024, int(o.get("max_mb") or 1024))
            max_gb = max(1, max_mb // 1024)
            sug = int(o.get("sugerido_mb") or max_mb)
            gb = self.tamanhos.get(o["id"], max(1, min(max_gb, round(sug / 1024))))
            self.adj_tamanho.configure(gb, 1, max_gb, 1, max(1, max_gb // 10), 0)
            self.l_tam_ajuda.set_text(f"Entre 1 e {max_gb} GB. Mais espaço permite guardar mais fotos, "
                                      "vídeos e programas; o resto do disco fica livre.")
            self.d_tamanho.show()
        else:
            self.d_tamanho.hide()
        if self._apaga(o):
            self.l_perigo.set_markup("<b>Atenção: tudo o que está em «" + GLib.markup_escape_text(
                str(o.get("titulo") or o["id"])) + "» vai ser apagado</b> — documentos, fotos e qualquer "
                "outro sistema que lá esteja. Não é possível desfazer.")
            if rb is not None:
                self.k_apagar.set_active(False)
            self.d_perigo.show()
        else:
            self.k_apagar.set_active(False)
            self.d_perigo.hide()
        self._validar_dados()

    def _tamanho_mudou(self, adj):
        o = self._opcao_escolhida()
        if o and o.get("tipo") in ("pen", "ficheiro"):
            self.tamanhos[o["id"]] = int(adj.get_value())

    def _validar_dados(self):
        o = self._opcao_escolhida()
        ok = self.dados_modo == "pronto" and (not self._apaga(o) or self.k_apagar.get_active())
        if self.pagina == "dados":
            self.b_seguir.set_sensitive(ok)
        return ok

    def _guardar_destino(self):
        o = self._opcao_escolhida()
        if not o:
            self.destino = None
            return
        tam = None
        if o.get("tipo") in ("pen", "ficheiro"):
            gb = int(self.adj_tamanho.get_value())
            max_mb = int(o.get("max_mb") or gb * 1024)
            tam = max_mb if gb >= max_mb // 1024 else gb * 1024
        self.destino = {"id": o["id"], "tipo": o.get("tipo"), "titulo": str(o.get("titulo") or o["id"]),
                        "tamanho_mb": tam, "confirmo_apagar": self._apaga(o) and self.k_apagar.get_active()}

    def _texto_destino(self):
        d = self.destino
        if not d:
            return None
        if d["tamanho_mb"]:
            gb = d["tamanho_mb"] / 1024
            return f"{d['titulo']}, {gb:.0f} GB" if gb >= 10 else f"{d['titulo']}, {gb:.1f} GB".replace(".", ",")
        return d["titulo"] + (" (o disco é apagado)" if d["confirmo_apagar"] else "")

    def _pagina_armazenar(self):
        b = self._caixa("armazenar")
        img = icone(["drive-removable-media", "drive-harddisk", "media-flash"], 64)
        img.set_pixel_size(64)
        img.set_margin_top(6)
        b.pack_start(img, False, False, 0)
        self.a_titulo = rotulo("A preparar o armazenamento…", ("assist-titulo",), 0.5)
        b.pack_start(self.a_titulo, False, False, 0)
        self.a_destino = rotulo("", ("assist-subtitulo", "assist-dim"), 0.5)
        b.pack_start(self.a_destino, False, False, 0)
        self.a_barra = Gtk.ProgressBar()
        self.a_barra.set_show_text(True)
        self.a_barra.set_margin_top(12)
        b.pack_start(self.a_barra, False, False, 0)
        self.a_estado = rotulo("", ("assist-pequeno", "assist-dim"), 0.5)
        b.pack_start(self.a_estado, False, False, 0)
        self.a_falha = Gtk.Box()
        self.a_falha.get_style_context().add_class("assist-falha")
        self.l_a_falha = rotulo("", ("assist-pequeno",))
        self.a_falha.pack_start(self.l_a_falha, True, True, 0)
        self.a_falha.set_no_show_all(True)
        self.l_a_falha.show()
        b.pack_start(self.a_falha, False, False, 0)
        self.a_botoes = Gtk.Box(spacing=10, halign=Gtk.Align.CENTER)
        self.a_botoes.set_no_show_all(True)
        self.b_sem_guardar = botao("Continuar _sem guardar", "assist-secundario")
        self.b_sem_guardar.connect("clicked", lambda *_: self._sem_guardar())
        self.b_repetir = botao("_Tentar outra vez", "assist-principal")
        self.b_repetir.connect("clicked", lambda *_: self.armazenar())
        for w in (self.b_sem_guardar, self.b_repetir):
            self.a_botoes.pack_start(w, False, False, 0)
            w.show()
        self.a_botoes.set_margin_top(8)
        b.pack_start(self.a_botoes, False, False, 0)

    def _pagina_reiniciar(self):
        b = self._caixa("reiniciar")
        img = icone(["emblem-ok-symbolic", "emblem-default", "object-select-symbolic", "dialog-ok"], 64)
        img.set_pixel_size(64)
        img.set_margin_top(8)
        b.pack_start(img, False, False, 0)
        b.pack_start(rotulo("Armazenamento preparado", ("assist-titulo",), 0.5), False, False, 0)
        self.r_texto = rotulo("", ("assist-subtitulo",), 0.5)
        b.pack_start(self.r_texto, False, False, 0)
        self.r_nota = rotulo("", ("assist-pequeno", "assist-dim"), 0.5)
        b.pack_start(self.r_nota, False, False, 0)
        self.r_falha = rotulo("", ("assist-pequeno", "assist-erro"), 0.5)
        self.r_falha.set_no_show_all(True)
        b.pack_start(self.r_falha, False, False, 0)
        caixa = Gtk.Box(spacing=10, halign=Gtk.Align.CENTER)
        caixa.set_margin_top(12)
        self.b_mais_tarde = botao("_Mais tarde", "assist-secundario")
        self.b_mais_tarde.connect("clicked", lambda *_: self._mostrar_pronto())
        self.b_reiniciar = botao("_Reiniciar agora", "assist-principal")
        self.b_reiniciar.set_no_show_all(True)
        self.b_reiniciar.connect("clicked", lambda *_: self._reiniciar())
        caixa.pack_start(self.b_mais_tarde, False, False, 0)
        caixa.pack_start(self.b_reiniciar, False, False, 0)
        b.pack_start(caixa, False, False, 0)

    def _campo(self, caixa, titulo, entrada, ajuda=""):
        caixa.pack_start(rotulo(titulo, ("assist-rotulo",)), False, False, 0)
        caixa.pack_start(entrada, False, False, 0)
        erro = rotulo(ajuda, ("assist-pequeno", "assist-dim"))
        erro.ajuda = ajuda
        caixa.pack_start(erro, False, False, 0)
        return erro

    def _pagina_conta(self):
        b = self._caixa("conta")
        topo = Gtk.Box(spacing=16)
        self.avatar = Gtk.DrawingArea()
        self.avatar.set_size_request(64, 64)
        self.avatar.set_valign(Gtk.Align.CENTER)
        self.avatar.connect("draw", self._desenhar_avatar)
        topo.pack_start(self.avatar, False, False, 0)
        t = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        t.set_valign(Gtk.Align.CENTER)
        t.pack_start(rotulo("A sua conta", ("assist-titulo",)), False, False, 0)
        t.pack_start(rotulo("É com ela que entra no sistema e instala programas (sudo).",
                            ("assist-dim",)), False, False, 0)
        topo.pack_start(t, True, True, 0)
        b.pack_start(topo, False, False, 4)

        grelha = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.e_nome = Gtk.Entry(placeholder_text="ex.: Maria Silva")
        self.l_nome = self._campo(grelha, "Nome completo", self.e_nome)
        self.e_user = Gtk.Entry(placeholder_text="ex.: maria")
        self.e_user.set_max_length(32)
        self.l_user = self._campo(grelha, "Nome de utilizador", self.e_user,
                                  "Minúsculas, algarismos, _ e -; é o nome da sua pasta pessoal.")
        self.e_senha = Gtk.Entry(visibility=False, placeholder_text=f"pelo menos {contas.SENHA_MINIMA} caracteres")
        self.e_senha.set_input_purpose(Gtk.InputPurpose.PASSWORD)
        self.e_senha.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, "view-reveal-symbolic")
        self.e_senha.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, "Mostrar/esconder a senha")
        self.e_senha.connect("icon-press", self._mostrar_senha)
        grelha.pack_start(rotulo("Senha", ("assist-rotulo",)), False, False, 0)
        grelha.pack_start(self.e_senha, False, False, 0)
        forca = Gtk.Box(spacing=5)
        self.segmentos = []
        for _ in range(4):
            s = Gtk.Box()
            s.get_style_context().add_class("assist-forca")
            s.set_valign(Gtk.Align.CENTER)
            forca.pack_start(s, True, True, 0)
            self.segmentos.append(s)
        self.l_forca = rotulo("", ("assist-pequeno", "assist-dim"), wrap=False)
        self.l_forca.set_size_request(90, -1)
        forca.pack_start(self.l_forca, False, False, 6)
        forca.set_margin_top(4)
        grelha.pack_start(forca, False, False, 0)
        self.e_conf = Gtk.Entry(visibility=False, placeholder_text="repita a senha")
        self.e_conf.set_input_purpose(Gtk.InputPurpose.PASSWORD)
        self.l_senha = self._campo(grelha, "Confirmar a senha", self.e_conf)
        b.pack_start(grelha, False, False, 0)

        self.k_auto = Gtk.CheckButton(label="Iniciar sessão automaticamente (sem pedir a senha ao ligar)")
        self.k_root = Gtk.CheckButton(label="Usar esta senha também para o administrador (root)")
        self.k_root.set_active(True)
        b.pack_start(self.k_auto, False, False, 0)
        b.pack_start(self.k_root, False, False, 0)

        for e in (self.e_nome, self.e_user, self.e_senha, self.e_conf):
            e.connect("changed", self._mudou)
            e.connect("focus-out-event", self._tocou)
            e.connect("activate", lambda *_: self.seguir() if self.b_seguir.get_sensitive() else None)

    def _pagina_resumo(self):
        b = self._caixa("resumo")
        b.pack_start(rotulo("Tudo certo?", ("assist-titulo",)), False, False, 0)
        b.pack_start(rotulo("Confirme antes de criar a conta.", ("assist-subtitulo", "assist-dim")),
                     False, False, 4)
        self.resumo = Gtk.Grid(column_spacing=18, row_spacing=8)
        caixa = Gtk.Box()
        caixa.get_style_context().add_class("assist-resumo")
        caixa.pack_start(self.resumo, True, True, 8)
        b.pack_start(caixa, False, False, 0)
        b.pack_start(rotulo("Para tarefas de administração use sudo: pede a SUA senha. "
                            "O utilizador ninja do modo live deixa de aparecer no ecrã de entrada.",
                            ("assist-pequeno", "assist-dim")), False, False, 4)

    def _pagina_criar(self):
        b = self._caixa("criar")
        self.spinner = Gtk.Spinner()
        self.spinner.set_size_request(40, 40)
        self.spinner.set_margin_top(20)
        b.pack_start(self.spinner, False, False, 0)
        self.l_criar = rotulo("A criar a sua conta…", ("assist-subtitulo",), 0.5)
        b.pack_start(self.l_criar, False, False, 10)
        self.falha = Gtk.Box()
        self.falha.get_style_context().add_class("assist-falha")
        self.l_falha = rotulo("", ("assist-pequeno",))
        self.falha.pack_start(self.l_falha, True, True, 0)
        self.falha.set_no_show_all(True)
        b.pack_start(self.falha, False, False, 0)
        self.b_greeter = botao("Ir para o ecrã de entrada", "assist-ligacao")
        self.b_greeter.set_halign(Gtk.Align.CENTER)
        self.b_greeter.set_no_show_all(True)
        self.b_greeter.connect("clicked", lambda *_: self._para_greeter())
        b.pack_start(self.b_greeter, False, False, 0)

    def _pagina_pronto(self):
        b = self._caixa("pronto")
        img = icone(["emblem-ok-symbolic", "emblem-default", "object-select-symbolic", "dialog-ok"], 64)
        img.set_pixel_size(64)
        img.set_margin_top(8)
        b.pack_start(img, False, False, 0)
        self.l_pronto = rotulo("Tudo pronto!", ("assist-titulo",), 0.5)
        b.pack_start(self.l_pronto, False, False, 0)
        self.l_pronto2 = rotulo("", ("assist-subtitulo", "assist-dim"), 0.5)
        b.pack_start(self.l_pronto2, False, False, 0)
        self.b_entrar = botao("Começar a usar", "assist-principal")
        self.b_entrar.set_halign(Gtk.Align.CENTER)
        self.b_entrar.set_margin_top(12)
        self.b_entrar.connect("clicked", lambda *_: self.entrar())
        b.pack_start(self.b_entrar, False, False, 0)

    # ------------------------------------------------ desenho do avatar
    def _desenhar_avatar(self, area, cr):
        import math
        w = area.get_allocated_width()
        cr.arc(w / 2, w / 2, w / 2, 0, 2 * math.pi)
        import cairo
        g = cairo.LinearGradient(0, 0, w, w)
        g.add_color_stop_rgb(0, 0.17, 0.55, 1.0)
        g.add_color_stop_rgb(1, 0.42, 0.36, 1.0)
        cr.set_source(g)
        cr.fill()
        partes = [p for p in self.e_nome.get_text().split() if p[:1].isalpha()]
        ini = (partes[0][0] + (partes[-1][0] if len(partes) > 1 else "")).upper() if partes else "?"
        cr.set_source_rgb(1, 1, 1)
        cr.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
        cr.set_font_size(w * 0.38)
        ext = cr.text_extents(ini)
        cr.move_to(w / 2 - ext.width / 2 - ext.x_bearing, w / 2 - ext.height / 2 - ext.y_bearing)
        cr.show_text(ini)
        return False

    # ------------------------------------------------ navegação
    def usa_dados(self):
        """A página "Onde guardar os seus dados?" faz parte do percurso (ou ainda pode fazer)."""
        return self.dados_modo in ("a_verificar", "pronto")

    def passos(self):
        return [p for p in PASSOS if p != "dados" or self.usa_dados()]

    def ir(self, nome):
        self.stack.set_visible_child_name(nome)
        # sem compositor (greeter), a sombra do cartão deixava rasto quando o cartão encolhia
        self.win.queue_draw()
        i = PAGINAS.index(nome)
        passos = {p: k for k, p in enumerate(self.passos())}
        self.pontos.set_visible(nome in passos)
        for k, p in enumerate(self.lista_pontos):
            p.set_visible(k < len(passos))
            ctx = p.get_style_context()
            ctx.remove_class("assist-ponto-atual")
            ctx.remove_class("assist-ponto-feito")
            if nome in passos:
                if k == passos[nome]:
                    ctx.add_class("assist-ponto-atual")
                elif k < passos[nome]:
                    ctx.add_class("assist-ponto-feito")
        # o rodapé não existe na 1.ª página: lá só há "Criar a minha conta" / "Experimentar"
        self.rodape.set_visible(nome in ("regiao", "dados", "conta", "resumo"))
        self.b_voltar.set_visible(nome != "inicio")
        self.b_seguir.set_visible(True)
        self.b_seguir.set_label("_Criar conta" if nome == "resumo" else "_Continuar")
        self.pagina = nome
        if nome == "dados":
            self._validar_dados()
            for r in self.radios:
                if r.get_active():
                    GLib.idle_add(r.grab_focus)
        elif nome == "conta":
            self._validar()
            GLib.idle_add(self.e_nome.grab_focus)
        elif nome == "resumo":
            self._encher_resumo()
            self.b_seguir.set_sensitive(True)
        elif nome == "regiao":
            self.b_seguir.set_sensitive(True)
        elif nome == "inicio":
            GLib.idle_add(self.b_comecar.grab_focus)
        return i

    def seguir(self):
        if self.pagina == "regiao":
            self.ir("dados" if self.usa_dados() else "conta")
        elif self.pagina == "dados" and self._validar_dados():
            self._guardar_destino()
            self.ir("conta")
        elif self.pagina == "conta" and self._validar(todos=True):
            self.ir("resumo")
        elif self.pagina == "resumo":
            self.criar()

    def voltar(self):
        if self.pagina in ("resumo_erro", "erro"):
            self.voltar_de_erro()
            return
        anterior = {"regiao": "inicio", "dados": "regiao", "resumo": "conta",
                    "conta": "dados" if self.usa_dados() else "regiao"}
        if self.pagina in anterior:
            self.ir(anterior[self.pagina])

    # ------------------------------------------------ validação
    def _teclado_mudou(self, c):
        self.dados["teclado"] = c.get_active_id()
        if self.greeter:
            xkb = contas.TECLADOS[self.dados["teclado"]][1]
            try:
                subprocess.Popen(["setxkbmap", "-layout", xkb], stdout=subprocess.DEVNULL,
                                 stderr=subprocess.DEVNULL)
            except OSError:
                pass

    def _mostrar_senha(self, e, pos, ev):
        v = not self.e_senha.get_visibility()
        self.e_senha.set_visibility(v)
        self.e_conf.set_visibility(v)
        self.e_senha.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY,
                                             "view-conceal-symbolic" if v else "view-reveal-symbolic")

    def _tocou(self, e, ev):
        if e.get_text():
            self.tocados.add(e)
            self._validar()
        return False

    def _mudou(self, e):
        if e is self.e_nome:
            if not self.utilizador_editado:
                self.e_user.handler_block_by_func(self._mudou)
                self.e_user.set_text(contas.sugerir_utilizador(self.e_nome.get_text()))
                self.e_user.handler_unblock_by_func(self._mudou)
            self.avatar.queue_draw()
        if e is self.e_user:
            self.utilizador_editado = bool(e.get_text())
            pos = e.get_position()
            baixo = e.get_text().lower()
            if baixo != e.get_text():
                e.handler_block_by_func(self._mudou)
                e.set_text(baixo)
                e.set_position(pos)
                e.handler_unblock_by_func(self._mudou)
        if e is self.e_conf and len(e.get_text()) >= len(self.e_senha.get_text()):
            self.tocados.add(e)
        self._validar()

    def _mostrar(self, l, entrada, erro, ver):
        ctx = l.get_style_context()
        for c in ("assist-erro", "assist-ok", "assist-dim"):
            ctx.remove_class(c)
        if erro and ver:
            l.set_text(erro)
            ctx.add_class("assist-erro")
            entrada.get_style_context().add_class("assist-invalido")
        else:
            l.set_text(getattr(l, "ajuda", ""))
            ctx.add_class("assist-dim")
            entrada.get_style_context().remove_class("assist-invalido")

    def _validar(self, todos=False):
        if todos:
            self.tocados.update((self.e_nome, self.e_user, self.e_senha, self.e_conf))
        nome, user = self.e_nome.get_text(), self.e_user.get_text()
        senha, conf = self.e_senha.get_text(), self.e_conf.get_text()
        e_nome = contas.validar_nome_completo(nome)
        e_user = contas.validar_utilizador(user, getattr(self, "raiz_validacao", "/"))
        e_senha = contas.validar_senha(senha, conf, user)
        self._mostrar(self.l_nome, self.e_nome, e_nome, self.e_nome in self.tocados)
        self._mostrar(self.l_user, self.e_user, e_user, self.e_user in self.tocados or bool(user))
        ver_senha = self.e_conf in self.tocados or (self.e_senha in self.tocados and e_senha
                                                    and "coincidem" not in e_senha)
        self._mostrar(self.l_senha, self.e_conf, e_senha, ver_senha)
        nivel, txt = contas.forca_senha(senha, user)
        for k, s in enumerate(self.segmentos):
            ctx = s.get_style_context()
            for n in range(1, 5):
                ctx.remove_class(f"nivel-{n}")
            if senha and k < max(1, nivel):
                ctx.add_class(f"nivel-{max(1, nivel)}")
        self.l_forca.set_text(txt)
        ok = not (e_nome or e_user or e_senha)
        if self.pagina == "conta":
            self.b_seguir.set_sensitive(ok)
        return ok

    def _encher_resumo(self):
        d = self.dados
        d.update(nome_completo=self.e_nome.get_text().strip(), utilizador=self.e_user.get_text(),
                 senha=self.e_senha.get_text(), autologin=self.k_auto.get_active(),
                 senha_root=self.k_root.get_active())
        for f in self.resumo.get_children():
            self.resumo.remove(f)
        linhas = [("Nome", d["nome_completo"]), ("Utilizador", d["utilizador"]),
                  ("Pasta pessoal", f"/home/{d['utilizador']}"),
                  ("Teclado", contas.TECLADOS[d["teclado"]][0]),
                  ("Fuso horário", dict(contas.FUSOS)[d["fuso"]]),
                  ("Entrar sem senha", "Sim" if d["autologin"] else "Não"),
                  ("Senha do root", "A mesma que a sua" if d["senha_root"] else "Mantém-se")]
        if self.dados_modo == "pronto":
            linhas.append((DADOS_EM, self._texto_destino() if self.destino
                           else "Em lado nenhum: perdem-se ao desligar"))
        elif self.dados_modo == "ativo":
            linhas.append((DADOS_EM, "No armazenamento já ativo neste sistema"))
        for i, (k, v) in enumerate(linhas):
            self.resumo.attach(rotulo(k, ("assist-resumo-chave",), wrap=False), 0, i, 1, 1)
            lv = rotulo(v, ("assist-resumo-valor",), wrap=k == DADOS_EM)
            if k == DADOS_EM:
                lv.set_max_width_chars(40)
                if self.destino and self.destino.get("confirmo_apagar"):
                    lv.get_style_context().add_class("assist-erro")
            self.resumo.attach(lv, 1, i, 1, 1)
        self.resumo.show_all()

    # ------------------------------------------------ ações
    def _em_fundo(self, funcao, fim):
        def corre():
            try:
                r = (True, funcao())
            except Exception as e:  # noqa: BLE001
                r = (False, str(e))
            GLib.idle_add(fim, *r)
        threading.Thread(target=corre, daemon=True).start()

    def _a_trabalhar(self, texto):
        self.l_criar.set_text(texto)
        self.falha.hide()
        self.b_greeter.hide()
        self.spinner.show()
        self.spinner.start()
        self.ir("criar")

    def _erro(self, texto, voltar=True):
        self.spinner.stop()
        self.spinner.hide()
        self.l_criar.set_text("Não foi possível continuar")
        self.l_falha.set_text(texto)
        self.falha.show_all()
        if self.greeter:
            self.b_greeter.show()
        if voltar:
            self.rodape.set_visible(True)
            self.b_seguir.set_visible(False)
            self.pagina = "erro"
        return False

    def criar(self):
        d = dict(self.dados)
        self._a_trabalhar("A criar a sua conta…")

        def fim(ok, msg):
            if not ok:
                self._erro(f"A conta não foi criada: {msg}")
                self.rodape.set_visible(True)
                self.b_seguir.set_visible(False)
                self.pagina = "resumo_erro"
                return False
            self.spinner.stop()
            if self.destino and self.dados_modo == "pronto":
                self.armazenar()
            else:
                self._mostrar_pronto()
            return False
        self._em_fundo(lambda: self.backend.criar(d), fim)

    def _mostrar_pronto(self):
        d = self.dados
        primeiro = d["nome_completo"].split()[0] if d["nome_completo"].split() else d["utilizador"]
        self.l_pronto.set_text(f"Tudo pronto, {primeiro}!")
        if self.pagina == "reiniciar":
            nota = " Os seus dados começam a ser guardados depois de reiniciar o computador."
        elif self.dados_modo == "pronto" and not self.destino:
            nota = " Atenção: a conta e os ficheiros só duram até desligar o computador."
        else:
            nota = ""
        self.l_pronto2.set_text(
            f"A conta «{d['utilizador']}» foi criada. "
            + ("Da próxima vez o sistema entra sozinho na sua sessão."
               if d["autologin"] else "Da próxima vez escolha o seu nome no ecrã de entrada.") + nota)
        self.ir("pronto")
        GLib.idle_add(self.b_entrar.grab_focus)
        return False

    # ------------------------------------------------ preparar o armazenamento (depois da conta)
    def armazenar(self):
        dest = dict(self.destino)
        self.a_titulo.set_text("A preparar o armazenamento…")
        self.a_destino.set_text(f"Os seus dados vão ficar em {self._texto_destino()}. "
                                "Não desligue o computador nem retire a pen.")
        self.a_barra.set_fraction(0)
        self.a_barra.set_text("0 %")
        self.a_barra.show()
        self.a_estado.set_text("A começar…")
        self.a_falha.hide()
        self.a_botoes.hide()
        self.ir("armazenar")

        def progresso(n, texto):
            GLib.idle_add(self._progresso, n, texto)

        def fim(ok, msg):
            if ok:
                self._progresso(100, "Concluído")
                self._mostrar_reiniciar()
            else:
                self.a_titulo.set_text("O armazenamento não ficou pronto")
                self.a_destino.set_text(f"Destino escolhido: {self._texto_destino()}.")
                self.a_barra.hide()
                self.a_estado.set_text("")
                self.l_a_falha.set_text(f"{msg}\n\nA sua conta já foi criada. Pode tentar outra vez ou "
                                        "continuar sem guardar (os dados perdem-se ao desligar).")
                self.a_falha.show()
                self.a_botoes.show()
                GLib.idle_add(self.b_repetir.grab_focus)
            return False
        self._em_fundo(lambda: self.backend.persistencia_criar(
            dest["id"], dest["tamanho_mb"], dest["confirmo_apagar"], progresso), fim)

    def _progresso(self, n, texto):
        self.a_barra.set_fraction(n / 100)
        self.a_barra.set_text(f"{n} %")
        if texto:
            self.a_estado.set_text(texto)
        return False

    def _sem_guardar(self):
        self.destino = None
        self._mostrar_pronto()

    def _mostrar_reiniciar(self):
        self.r_texto.set_text(f"Os seus dados passam a ser guardados em {self.destino['titulo']}. "
                              "Reinicie para ativar.")
        pode = False
        try:
            pode = self.backend.pode_reiniciar()
        except Exception:  # noqa: BLE001
            pode = False
        self.b_reiniciar.set_visible(pode)
        self.r_falha.hide()
        if pode:
            self.r_nota.set_text("O que fizer antes de reiniciar pode não ficar guardado.")
            self.b_mais_tarde.set_label("_Mais tarde")
        else:
            self.r_nota.set_text("Quando quiser, reinicie o computador pelo menu (Sair → Reiniciar). "
                                 "O que fizer antes disso pode não ficar guardado.")
            self.b_mais_tarde.set_label("_Continuar")
        self.ir("reiniciar")
        GLib.idle_add((self.b_reiniciar if pode else self.b_mais_tarde).grab_focus)

    def _reiniciar(self):
        try:
            self.backend.reiniciar()
        except Exception as e:  # noqa: BLE001
            self.r_falha.set_text(f"Não foi possível reiniciar ({e}). Reinicie pelo menu (Sair → Reiniciar).")
            self.r_falha.show()
            self.b_reiniciar.hide()
            self.b_mais_tarde.set_label("_Continuar")

    def voltar_de_erro(self):
        self.b_seguir.set_visible(True)
        self.ir("resumo" if self.pagina == "resumo_erro" else "inicio")

    def entrar(self):
        d = self.dados
        self._a_trabalhar("A abrir a sua sessão…")
        self.sessao.entrar(d["utilizador"], d["senha"],
                           lambda m: self._erro(f"A conta foi criada, mas a sessão não abriu ({m}). "
                                                "Entre pelo ecrã de entrada com o seu utilizador e senha.",
                                                voltar=False))

    def experimentar(self):
        self._a_trabalhar("A abrir o modo live (utilizador ninja)…")

        def fim(ok, msg):
            if not ok:
                print(f"ianinja-assistente: experimentar: {msg}", file=sys.stderr)
            self.sessao.entrar(contas.UTILIZADOR_LIVE, "ninja",
                               lambda m: self._erro(f"Não foi possível entrar como ninja ({m}).", voltar=False))
            return False
        self._em_fundo(self.backend.experimentar, fim)

    def _para_greeter(self):
        if self.greeter:
            ir_para_greeter_gtk("pedido no ecrã de erro")
        Gtk.main_quit()


def carregar_css():
    prov = Gtk.CssProvider()
    prov.load_from_path(CSS)
    # acima do gtk.css do utilizador lightdm (/var/lib/lightdm/.config/gtk-3.0), que é do greeter GTK
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), prov,
                                             Gtk.STYLE_PROVIDER_PRIORITY_USER + 1)


def definicoes_gtk():
    s = Gtk.Settings.get_default()
    for chave, valor in (("gtk-theme-name", "WhiteSur-Light"), ("gtk-icon-theme-name", "WhiteSur-light"),
                         ("gtk-cursor-theme-name", "WhiteSur-cursors"), ("gtk-font-name", "Inter 11"),
                         ("gtk-application-prefer-dark-theme", False)):
        try:
            s.set_property(chave, valor)
        except TypeError:
            pass


# ------------------------------------------------------------------ modos

def modo_grafico(args):
    importar_gtk()
    if not Gtk.init_check(None)[0]:
        raise RuntimeError("sem ecrã (DISPLAY)")
    definicoes_gtk()
    carregar_css()
    if args.greeter:
        backend, sessao = BackendGreeter(), SessaoLightDM()
    elif args.raiz:
        backend, sessao = BackendLocal(args.raiz), SessaoSimulada()
    else:
        backend, sessao = BackendSimulado(), SessaoSimulada()

    if args.captura:
        win = Gtk.OffscreenWindow()
    else:
        win = Gtk.Window(title="Assistente de configuração")
    win.get_style_context().add_class("assist-janela")
    a = Assistente(win, backend, sessao, greeter=args.greeter, live=True if args.live else None,
                   consultar=not args.captura)
    if args.raiz:
        a.raiz_validacao = args.raiz

    if args.greeter:
        win.set_decorated(False)
        ecra = Gdk.Display.get_default()
        mon = ecra.get_primary_monitor() or ecra.get_monitor(0)
        g = mon.get_geometry()
        win.move(g.x, g.y)
        win.set_default_size(g.width, g.height)
        win.set_size_request(g.width, g.height)
        raiz = Gdk.get_default_root_window()
        try:
            raiz.set_cursor(Gdk.Cursor.new_from_name(ecra, "default"))
        except Exception:  # noqa: BLE001
            pass
    else:
        win.set_default_size(args.largura, args.altura)
        win.set_size_request(args.largura, args.altura)
        win.connect("destroy", Gtk.main_quit)

    if args.captura:
        win.show_all()
        exemplo(a, args.pagina)

        def guardar():
            pix = win.get_pixbuf()
            pix.savev(args.captura, "png", [], [])
            print(f"captura: {args.captura} ({pix.get_width()}x{pix.get_height()})")
            Gtk.main_quit()
            return False
        GLib.timeout_add(900, guardar)
    else:
        win.show_all()
        win.present()
        if args.greeter:
            def foco():
                gw = win.get_window()
                if gw:
                    gw.focus(Gdk.CURRENT_TIME)
                return False
            GLib.timeout_add(300, foco)
    Gtk.main()


EXTRA_CAPTURA = {"dados-particao": "dados", "dados-vazio": "dados", "armazenar-erro": "armazenar",
                 "conta-erro": "conta"}


def exemplo(a, pagina):
    """Dados de exemplo para as capturas (pagina: número em PAGINAS ou nome, ver EXTRA_CAPTURA)."""
    nome = PAGINAS[int(pagina)] if str(pagina).isdigit() and int(pagina) < len(PAGINAS) else str(pagina)
    base = EXTRA_CAPTURA.get(nome, nome if nome in PAGINAS else "inicio")
    k = PAGINAS.index(base)
    # a consulta do armazenamento corre aqui sem thread (a captura é tirada logo a seguir)
    if nome == "dados-vazio":
        a.backend.modo = "vazio"
    try:
        a._persistencia_lida(True, a._consultar_persistencia())
    except Exception as e:  # noqa: BLE001
        a._persistencia_lida(False, str(e))
    if nome == "dados-particao":
        for r in a.radios:
            if a._apaga(r.opcao):
                r.set_active(True)
    if k >= PAGINAS.index("conta"):
        a.e_nome.set_text("Maria Silva")
        a.e_senha.set_text("Pastel-de-nata9")
        a.e_conf.set_text("Pastel-de-nata9" if nome != "conta-erro" else "x")
        a.k_auto.set_active(True)
        a._guardar_destino()
    if k >= PAGINAS.index("resumo"):
        a._encher_resumo()
    a.ir(base)
    if base == "criar":
        a.spinner.start()
    elif base == "armazenar":
        a.a_destino.set_text(f"Os seus dados vão ficar em {a._texto_destino()}. "
                             "Não desligue o computador nem retire a pen.")
        a._progresso(45, "A copiar a sua conta e as definições…")
        if nome == "armazenar-erro":
            a.a_titulo.set_text("O armazenamento não ficou pronto")
            a.a_destino.set_text(f"Destino escolhido: {a._texto_destino()}.")
            a.a_barra.hide()
            a.a_estado.set_text("")
            a.l_a_falha.set_text("não há espaço suficiente no destino (simulado)\n\nA sua conta já foi "
                                 "criada. Pode tentar outra vez ou continuar sem guardar (os dados perdem-se "
                                 "ao desligar).")
            a.a_falha.show()
            a.a_botoes.show()
    elif base == "reiniciar":
        a._mostrar_reiniciar()
    elif base == "pronto":
        a.pagina = "reiniciar" if a.destino else "resumo"
        a._mostrar_pronto()


def modo_texto(args):
    import getpass
    raiz = args.raiz or "/"
    if os.geteuid() != 0:
        print("Corra como root: sudo ianinja-assistente --texto")
        return 1
    if contas.configurado(raiz):
        print("O sistema já está configurado. Para voltar a pedir: sudo ianinja-assistente --repor")
        return 0
    print("\n=== Assistente de configuração do ianinjapelagestao (modo de texto) ===\n")

    def pedir(pergunta, validar, omissao=""):
        while True:
            v = input(f"{pergunta}{f' [{omissao}]' if omissao else ''}: ").strip() or omissao
            erro = validar(v)
            if not erro:
                return v
            print("  ->", erro)

    def escolher(titulo, opcoes, omissao):
        print(titulo)
        chaves = list(opcoes)
        for i, k in enumerate(chaves, 1):
            print(f"  {i}) {opcoes[k]}{'  (omissão)' if k == omissao else ''}")
        while True:
            v = input("Número: ").strip()
            if not v:
                return omissao
            if v.isdigit() and 1 <= int(v) <= len(chaves):
                return chaves[int(v) - 1]

    d = {}
    d["nome_completo"] = pedir("Nome completo", contas.validar_nome_completo)
    d["utilizador"] = pedir("Nome de utilizador", lambda u: contas.validar_utilizador(u, raiz),
                            contas.sugerir_utilizador(d["nome_completo"]))
    while True:
        s1 = getpass.getpass(f"Senha (mínimo {contas.SENHA_MINIMA} caracteres): ")
        print("  força:", contas.forca_senha(s1, d["utilizador"])[1])
        s2 = getpass.getpass("Repita a senha: ")
        erro = contas.validar_senha(s1, s2, d["utilizador"])
        if not erro:
            break
        print("  ->", erro)
    d["senha"] = s1
    d["teclado"] = escolher("Teclado:", {k: v[0] for k, v in contas.TECLADOS.items()}, contas.TECLADO_OMISSAO)
    d["fuso"] = escolher("Fuso horário:", dict(contas.FUSOS), contas.FUSO_OMISSAO)
    d["autologin"] = input("Iniciar sessão gráfica automaticamente? [s/N]: ").strip().lower().startswith("s")
    d["senha_root"] = not input("Usar a mesma senha para o root? [S/n]: ").strip().lower().startswith("n")
    try:
        print(contas.aplicar(d, raiz))
    except contas.ErroAssistente as e:
        print("ERRO:", e)
        return 1
    print(f"\nConta «{d['utilizador']}» criada. Entre com ela (o utilizador ninja ficou bloqueado).")
    return 0


def verificar():
    importar_gtk()
    import gi
    gi.require_version("LightDM", "1")
    from gi.repository import LightDM  # noqa: F401
    Gtk.CssProvider().load_from_path(CSS)
    assert contas.validar_utilizador("Maria") and contas.validar_utilizador("1abc")
    assert contas.validar_utilizador("root") and contas.validar_utilizador("ninja")
    assert contas.validar_utilizador("maria-silva_2", "/nao-existe") is None
    assert contas.validar_senha("curta", "curta") and contas.validar_senha("Pastel-de-nata9", "outra")
    assert contas.validar_senha("Pastel-de-nata9", "Pastel-de-nata9", "maria") is None
    assert contas.sugerir_utilizador("José Conceição") == "jose"
    assert contas.forca_senha("123456789")[0] <= 1 and contas.forca_senha("Pastel-de-nata9")[0] >= 3
    print("ianinja-assistente --verificar: GTK, LightDM (GIR), CSS e validação OK; estado:",
          " ".join(contas.estado()))
    return 0


def main():
    p = argparse.ArgumentParser(description="Assistente de configuração do ianinjapelagestao")
    p.add_argument("--greeter", action="store_true")
    p.add_argument("--janela", action="store_true")
    p.add_argument("--texto", action="store_true")
    p.add_argument("--verificar", action="store_true")
    p.add_argument("--raiz")
    p.add_argument("--live", action="store_true", help="(obsoleto: o aviso deu lugar à página dos dados)")
    p.add_argument("--captura")
    p.add_argument("--pagina", default="0")
    p.add_argument("--largura", type=int, default=1100)
    p.add_argument("--altura", type=int, default=760)
    args = p.parse_args()
    if args.verificar:
        return verificar()
    if args.texto:
        return modo_texto(args)
    if args.greeter:
        try:
            modo_grafico(args)
        except SystemExit:
            raise
        except BaseException as e:  # noqa: BLE001
            ir_para_greeter_gtk(f"erro no assistente: {e!r}")
        return 0
    modo_grafico(args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
