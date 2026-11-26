#!/usr/bin/env python3
"""Loja — loja de aplicações do ianinjapelagestao (Flatpak + Flathub), em Python + GTK 3.

Página inicial com destaques e categorias, pesquisa no Flathub, página de cada aplicação
(Instalar/Abrir/Remover com barra de progresso), Instaladas, Atualizações e Aplicações oficiais
(VS Code, Chrome, Claude Code, Codex, através do comando instalar-aplicacoes).
Instala em modo --user (~/.local/share/flatpak, sem sudo).

Uso: loja [--verificar]     (--verificar: confirma GTK, CSS e flatpak sem abrir a janela)
"""
import os
import shutil
import subprocess
import sys
import threading

DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, DIR)

import loja_flathub as fh  # noqa: E402
import loja_flatpak as fp  # noqa: E402

import gi  # noqa: E402
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gdk, GdkPixbuf, Gio, GLib, Gtk, Pango  # noqa: E402

ID_APP = "pt.ianinjapelagestao.Loja"
CSS = os.path.join(DIR, "estilo.css")

OFICIAIS = [
    ("vscode", "Visual Studio Code", "Editor de código da Microsoft",
     ["vscode", "com.visualstudio.code", "accessories-text-editor", "text-editor"]),
    ("chrome", "Google Chrome", "Navegador da Google", ["google-chrome", "web-browser", "applications-internet"]),
    ("claude", "Claude Code", "Assistente de programação da Anthropic (terminal)", ["utilities-terminal"]),
    ("codex", "Codex", "Assistente de programação da OpenAI (terminal)", ["utilities-terminal"]),
]


def em_fundo(funcao, *args, depois=None, erro=None):
    """Corre funcao(*args) numa thread; depois(resultado) / erro(excecao) no ciclo do GTK."""
    def corpo():
        try:
            r = funcao(*args)
        except Exception as e:  # noqa: BLE001 — mostra-se ao utilizador
            if erro:
                GLib.idle_add(erro, e)
            return
        if depois:
            GLib.idle_add(depois, r)
    threading.Thread(target=corpo, daemon=True).start()


def pixbuf(caminho, tamanho):
    try:
        return GdkPixbuf.Pixbuf.new_from_file_at_scale(caminho, tamanho, tamanho, True)
    except GLib.Error:
        return None


def imagem_app(url, tamanho, app_id=None):
    """Gtk.Image com o ícone (do Flathub, em cache, ou o exportado pela aplicação instalada)."""
    img = Gtk.Image.new_from_icon_name("application-x-executable", Gtk.IconSize.DIALOG)
    img.set_pixel_size(tamanho)
    local = fp.icone_instalado(app_id) if app_id else None
    if local:
        pb = pixbuf(local, tamanho)
        if pb:
            img.set_from_pixbuf(pb)
            return img
    if url:
        def pronto(f):
            pb = pixbuf(f, tamanho) if f else None
            if pb:
                img.set_from_pixbuf(pb)
        em_fundo(fh.imagem, url, depois=pronto)
    return img


def rotulo(texto, classe=None, xalign=0.0, linhas=None, selecionavel=False):
    l = Gtk.Label(label=texto, xalign=xalign)
    l.set_line_wrap(True)
    l.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR)
    if linhas:
        l.set_lines(linhas)
        l.set_ellipsize(Pango.EllipsizeMode.END)
        l.set_max_width_chars(30)      # largura natural pequena: vários cartões por linha
    if classe:
        for c in classe.split():
            l.get_style_context().add_class(c)
    l.set_selectable(selecionavel)
    return l


def classe(w, *nomes):
    for n in nomes:
        w.get_style_context().add_class(n)
    return w


class Cartao(Gtk.EventBox):
    """Cartão de uma aplicação: ícone, nome, resumo e botão Obter/Abrir."""

    def __init__(self, janela, app):
        super().__init__()
        self.janela, self.app = janela, app
        caixa = classe(Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12),
                       "loja-cartao", "loja-cartao-clicavel")
        caixa.set_size_request(320, -1)
        caixa.pack_start(imagem_app(app.get("icone"), 64, app["id"]), False, False, 0)
        texto = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        texto.pack_start(rotulo(app["nome"], "loja-cartao-nome", linhas=1), False, False, 0)
        texto.pack_start(rotulo(app.get("resumo", ""), "loja-dim loja-pequeno", linhas=2), False, False, 0)
        caixa.pack_start(texto, True, True, 0)
        instalada = app["id"] in janela.instaladas
        b = classe(Gtk.Button(label="Abrir" if instalada else "Obter"), "loja-obter")
        b.set_valign(Gtk.Align.CENTER)
        b.connect("clicked", self.botao)
        caixa.pack_end(b, False, False, 0)
        self.add(caixa)
        self.connect("button-release-event", lambda *_: janela.mostrar_app(app["id"], app))

    def botao(self, _b):
        if self.app["id"] in self.janela.instaladas:
            fp.abrir(self.app["id"])
        else:
            self.janela.mostrar_app(self.app["id"], self.app, instalar=True)


def grelha():
    g = Gtk.FlowBox()
    g.set_selection_mode(Gtk.SelectionMode.NONE)
    g.set_homogeneous(True)
    g.set_min_children_per_line(2)
    g.set_max_children_per_line(4)
    g.set_column_spacing(14)
    g.set_row_spacing(14)
    g.set_valign(Gtk.Align.START)
    return g


def pagina_rolavel():
    sw = Gtk.ScrolledWindow()
    sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
    caixa = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
    caixa.set_margin_start(32)
    caixa.set_margin_end(32)
    caixa.set_margin_top(24)
    caixa.set_margin_bottom(32)
    sw.add(caixa)
    return sw, caixa


def limpar(caixa):
    for f in caixa.get_children():
        caixa.remove(f)
        f.destroy()


class Janela(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Loja")
        self.set_default_size(1180, 760)
        self.set_icon_name("loja")
        classe(self, "loja-janela")
        self.instaladas = {}
        self.operacao = None          # uma operação do flatpak de cada vez
        self.aviso_live_dado = False
        self.pagina_anterior = "inicio"

        barra = Gtk.HeaderBar(show_close_button=True, title="Loja")
        barra.set_subtitle("Aplicações do Flathub")
        self.voltar = classe(Gtk.Button.new_from_icon_name("go-previous-symbolic", Gtk.IconSize.BUTTON),
                             "loja-voltar")
        self.voltar.set_tooltip_text("Voltar")
        self.voltar.connect("clicked", lambda *_: self.ir(self.pagina_anterior))
        barra.pack_start(self.voltar)
        self.set_titlebar(barra)

        raiz = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.add(raiz)
        raiz.pack_start(self.criar_lateral(), False, False, 0)

        direita = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        classe(direita, "loja-conteudo")
        self.aviso = self.criar_aviso_live()
        direita.pack_start(self.aviso, False, False, 0)
        self.pilha = Gtk.Stack(transition_type=Gtk.StackTransitionType.CROSSFADE, transition_duration=150)
        direita.pack_start(self.pilha, True, True, 0)
        raiz.pack_start(direita, True, True, 0)

        for nome in ("inicio", "lista", "app", "instaladas", "atualizacoes", "oficiais", "mensagem"):
            sw, caixa = pagina_rolavel()
            setattr(self, "cx_" + nome, caixa)
            self.pilha.add_named(sw, nome)

        self.show_all()
        self.aviso.set_visible(fp.sessao_live() and not fp.com_persistencia())
        self.voltar.hide()
        if not fp.disponivel():
            self.mensagem("O Flatpak não está instalado",
                          "Não encontrei o comando flatpak. A Loja precisa dele para instalar aplicações.")
        else:
            em_fundo(fp.preparar_remote, depois=self._remote_pronto)
        self.atualizar_instaladas(depois=self.pagina_inicio)

    # ---------- estrutura
    def criar_lateral(self):
        caixa = classe(Gtk.Box(orientation=Gtk.Orientation.VERTICAL), "loja-lateral")
        caixa.set_size_request(230, -1)
        self.pesquisa = Gtk.SearchEntry(placeholder_text="Pesquisar no Flathub")
        self.pesquisa.connect("activate", self.pesquisar)
        caixa.pack_start(self.pesquisa, False, False, 0)
        self.lista_lateral = Gtk.ListBox()
        self.lista_lateral.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.itens = []

        def item(texto, icone, acao):
            row = Gtk.ListBoxRow()
            b = Gtk.Box(spacing=10)
            im = Gtk.Image.new_from_gicon(Gio.ThemedIcon.new_from_names([icone, "applications-other"]),
                                          Gtk.IconSize.MENU)
            im.set_pixel_size(18)
            b.pack_start(im, False, False, 0)
            b.pack_start(Gtk.Label(label=texto, xalign=0), True, True, 0)
            row.add(b)
            row.acao = acao
            self.lista_lateral.add(row)
            self.itens.append(row)
            return row

        def seccao(texto):
            row = Gtk.ListBoxRow(selectable=False, activatable=False)
            row.add(classe(Gtk.Label(label=texto.upper(), xalign=0), "loja-lateral-seccao"))
            row.acao = None
            self.lista_lateral.add(row)

        self.item_inicio = item("Descobrir", "starred-symbolic", self.pagina_inicio)
        seccao("Categorias")
        for i, (nome, cat, sub, ic) in enumerate(fh.CATEGORIAS):
            item(nome, ic, lambda n=nome, c=cat, s=sub, k=i: self.pagina_categoria(n, c, s, k))
        seccao("As minhas aplicações")
        item("Instaladas", "emblem-ok-symbolic", self.pagina_instaladas)
        item("Atualizações", "software-update-available-symbolic", self.pagina_atualizacoes)
        item("Aplicações oficiais", "emblem-default-symbolic", self.pagina_oficiais)
        self.lista_lateral.connect("row-activated", lambda _l, r: r.acao and r.acao())
        caixa.pack_start(self.lista_lateral, True, True, 0)
        return caixa

    def criar_aviso_live(self):
        caixa = classe(Gtk.Box(spacing=12), "loja-aviso")
        caixa.set_margin_start(24)
        caixa.set_margin_end(24)
        caixa.set_margin_top(14)
        im = Gtk.Image.new_from_icon_name("dialog-warning", Gtk.IconSize.LARGE_TOOLBAR)
        caixa.pack_start(im, False, False, 0)
        caixa.pack_start(rotulo(
            "Está a usar o sistema live sem disco de dados: as aplicações instaladas ficam na memória "
            "(RAM) e perdem-se ao desligar. Para as guardar, crie um disco de dados persistente."), True, True, 0)
        b = Gtk.Button(label="Como guardar")
        b.set_valign(Gtk.Align.CENTER)
        b.connect("clicked", lambda *_: self.explicar_persistencia())
        caixa.pack_end(b, False, False, 0)
        caixa.set_no_show_all(True)
        for f in caixa.get_children():
            f.show_all()
        return caixa

    def explicar_persistencia(self):
        d = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.INFO,
                              buttons=Gtk.ButtonsType.CLOSE, text="Guardar as aplicações entre arranques")
        d.format_secondary_markup(
            "Ligue uma segunda pen USB (ou use uma partição livre) e, num terminal, veja os discos com\n"
            "<tt>lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MODEL</tt>\n\n"
            "Depois prepare a partição (ATENÇÃO: apaga o que lá estiver):\n"
            "<tt>sudo ianinja-persistencia listar</tt> e depois <tt>sudo ianinja-persistencia criar ID</tt>\n\n"
            "No arranque seguinte tudo o que instalar (incluindo as aplicações da Loja, em "
            "~/.local/share/flatpak) fica guardado nesse disco.")
        d.run()
        d.destroy()

    def ir(self, nome):
        if nome != "app":
            self.voltar.hide()
        self.pilha.set_visible_child_name(nome)

    def mensagem(self, titulo, texto, icone="dialog-information"):
        cx = self.cx_mensagem
        limpar(cx)
        im = Gtk.Image.new_from_icon_name(icone, Gtk.IconSize.DIALOG)
        im.set_pixel_size(64)
        im.set_margin_top(80)
        cx.pack_start(im, False, False, 0)
        cx.pack_start(rotulo(titulo, "loja-subtitulo", xalign=0.5), False, False, 0)
        cx.pack_start(rotulo(texto, "loja-dim", xalign=0.5), False, False, 0)
        cx.show_all()
        self.ir("mensagem")

    def a_carregar(self, caixa, titulo):
        limpar(caixa)
        caixa.pack_start(rotulo(titulo, "loja-titulo"), False, False, 0)
        sp = Gtk.Spinner(active=True)
        sp.set_size_request(32, 32)
        sp.set_margin_top(40)
        caixa.pack_start(sp, False, False, 0)
        caixa.show_all()

    def erro_rede(self, e):
        """Erro de um pedido em fundo: só os de rede dizem "sem ligação"; os outros têm mensagem própria."""
        if isinstance(e, fh.ErroRede):
            self.mensagem("Sem ligação ao Flathub",
                          f"{e}\n\nVerifique a ligação à Internet (cabo, ou: ligar-wifi) e tente de novo.",
                          "network-offline")
        elif isinstance(e, fh.ErroCertificado):
            self.mensagem("Ligação segura ao Flathub recusada", str(e), "dialog-warning")
        elif isinstance(e, fh.ErroServidor):
            self.mensagem("O Flathub devolveu um erro", f"{e}\n\nTente de novo daqui a pouco.", "dialog-warning")
        elif isinstance(e, RuntimeError):     # erros do comando flatpak (ex.: remote-ls --updates)
            self.mensagem("O flatpak devolveu um erro", str(e), "dialog-error")
        else:
            self.mensagem("Erro na Loja", f"{type(e).__name__}: {e}", "dialog-error")

    def _remote_pronto(self, r):
        ok, err = r
        if not ok:
            self.mensagem("Não foi possível configurar o Flathub", err or "flatpak remote-add falhou",
                          "dialog-error")

    def atualizar_instaladas(self, depois=None):
        def feito(r):
            self.instaladas = r
            if depois:
                depois()
        em_fundo(lambda: fp.ids_instalados() if fp.disponivel() else {}, depois=feito,
                 erro=lambda e: feito({}))

    # ---------- páginas
    def pagina_inicio(self):
        self.lista_lateral.select_row(self.item_inicio)
        cx = self.cx_inicio
        limpar(cx)
        hero = classe(Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6), "loja-hero")
        hero.pack_start(rotulo("Descobrir", "loja-hero-titulo"), False, False, 0)
        hero.pack_start(rotulo("Milhares de aplicações livres e populares do Flathub, instaladas na sua "
                               "pasta pessoal, sem palavra-passe.", "loja-hero-texto"), False, False, 0)
        cx.pack_start(hero, False, False, 0)

        cx.pack_start(rotulo("Categorias", "loja-subtitulo"), False, False, 0)
        cats = grelha()
        cats.set_max_children_per_line(6)
        cats.set_min_children_per_line(3)
        for i, (nome, cat, sub, ic) in enumerate(fh.CATEGORIAS):
            b = classe(Gtk.Button(), "loja-categoria", f"loja-cat-{i}")
            bx = Gtk.Box(spacing=10)
            im = Gtk.Image.new_from_gicon(Gio.ThemedIcon.new_from_names([ic, "applications-other"]),
                                          Gtk.IconSize.DND)
            im.set_pixel_size(28)
            bx.pack_start(im, False, False, 0)
            bx.pack_start(Gtk.Label(label=nome, xalign=0), True, True, 0)
            b.add(bx)
            b.connect("clicked", lambda _b, n=nome, c=cat, s=sub, k=i: self.pagina_categoria(n, c, s, k))
            cats.add(b)
        cx.pack_start(cats, False, False, 0)

        cx.pack_start(rotulo("Destaques", "loja-subtitulo"), False, False, 0)
        self.grelha_destaques = grelha()
        cx.pack_start(self.grelha_destaques, False, False, 0)
        cx.pack_start(rotulo("Populares no Flathub", "loja-subtitulo"), False, False, 0)
        self.grelha_populares = grelha()
        cx.pack_start(self.grelha_populares, False, False, 0)
        cx.show_all()
        self.ir("inicio")

        def destaques():
            r, erro = [], None
            for i in fh.DESTAQUES:
                try:
                    d = fh.detalhes(i)
                except fh.ErroFlathub as e:   # uma aplicação com problemas não esconde as outras
                    if isinstance(e, fh.ErroRede) and not r:
                        raise                 # sem rede logo à primeira: não vale a pena tentar as 10
                    erro = erro or e
                    continue
                if d:
                    r.append(d)
            if not r and erro:
                raise erro
            return r

        def encher(g, apps):
            for a in apps:
                g.add(Cartao(self, a))
            g.show_all()
        em_fundo(destaques, depois=lambda r: encher(self.grelha_destaques, r), erro=self.erro_rede)
        em_fundo(fh.populares, 16, depois=lambda r: encher(
            self.grelha_populares, [a for a in r if a["id"] not in fh.DESTAQUES][:12]))

    def mostrar_lista(self, titulo, funcao, *args):
        cx = self.cx_lista
        self.a_carregar(cx, titulo)
        self.ir("lista")
        self.pagina_anterior = "lista"

        def pronto(apps):
            limpar(cx)
            cx.pack_start(rotulo(titulo, "loja-titulo"), False, False, 0)
            if not apps:
                cx.pack_start(rotulo("Nenhuma aplicação encontrada.", "loja-dim"), False, False, 0)
            g = grelha()
            for a in apps:
                g.add(Cartao(self, a))
            cx.pack_start(g, False, False, 0)
            cx.show_all()
        em_fundo(funcao, *args, depois=pronto, erro=self.erro_rede)

    def pagina_categoria(self, nome, cat, sub, _k):
        self.mostrar_lista(nome, fh.categoria, cat, sub)

    def pesquisar(self, entrada):
        t = entrada.get_text().strip()
        if t:
            self.lista_lateral.unselect_all()
            self.mostrar_lista(f"Resultados para “{t}”", fh.pesquisar, t)

    # ---------- página de uma aplicação
    def mostrar_app(self, app_id, resumo=None, instalar=False):
        if self.pilha.get_visible_child_name() != "app":
            self.pagina_anterior = self.pilha.get_visible_child_name()
        cx = self.cx_app
        self.a_carregar(cx, (resumo or {}).get("nome", app_id))
        self.ir("app")
        self.voltar.show()

        def pronto(d):
            if not d:
                d = dict(resumo or {"id": app_id, "nome": app_id})
                d.setdefault("descricao", "")
            self.encher_app(d)
            if instalar and app_id not in self.instaladas:
                self.instalar(d)
        em_fundo(fh.detalhes, app_id, depois=pronto, erro=self.erro_rede)

    def encher_app(self, d):
        cx = self.cx_app
        limpar(cx)
        self.app_atual = d
        topo = Gtk.Box(spacing=22)
        topo.pack_start(imagem_app(d.get("icone"), 128, d["id"]), False, False, 0)
        info = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        info.set_valign(Gtk.Align.CENTER)
        info.pack_start(rotulo(d["nome"], "loja-titulo"), False, False, 0)
        info.pack_start(rotulo(d.get("resumo", ""), "loja-dim"), False, False, 0)
        if d.get("programador"):
            info.pack_start(rotulo(d["programador"], "loja-dim loja-pequeno"), False, False, 0)
        self.botoes = Gtk.Box(spacing=8)
        self.botoes.set_margin_top(10)
        info.pack_start(self.botoes, False, False, 0)
        self.progresso = classe(Gtk.ProgressBar(), "loja-progresso")
        self.progresso.set_size_request(320, -1)
        self.progresso.set_halign(Gtk.Align.START)
        self.progresso_texto = rotulo("", "loja-dim loja-pequeno")
        info.pack_start(self.progresso, False, False, 4)
        info.pack_start(self.progresso_texto, False, False, 0)
        topo.pack_start(info, True, True, 0)
        cx.pack_start(topo, False, False, 0)

        linha = classe(Gtk.Box(spacing=0, homogeneous=True), "loja-cartao")
        for titulo, valor in (("Versão", d.get("versao") or "—"),
                              ("Transferência", fh.tamanho_legivel(d.get("tamanho_download"))),
                              ("Instalada", fh.tamanho_legivel(d.get("tamanho_instalado"))),
                              ("Licença", (d.get("licenca") or "—").replace("LicenseRef-proprietary", "Proprietária"))):
            c = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            c.pack_start(rotulo(titulo.upper(), "loja-dim loja-pequeno", xalign=0.5), False, False, 0)
            c.pack_start(rotulo(valor, "loja-info-valor", xalign=0.5, linhas=1), False, False, 0)
            linha.pack_start(c, True, True, 0)
        cx.pack_start(linha, False, False, 0)

        if d.get("capturas"):
            sw = Gtk.ScrolledWindow()
            sw.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.NEVER)
            sw.set_min_content_height(330)
            fila = Gtk.Box(spacing=14)
            sw.add(fila)
            for url in d["capturas"]:
                im = classe(Gtk.Image(), "loja-captura")
                fila.pack_start(im, False, False, 0)

                def pronto(f, im=im):
                    if not f:
                        return
                    try:
                        pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(f, -1, 310, True)
                        im.set_from_pixbuf(pb)
                    except GLib.Error:
                        pass
                em_fundo(fh.imagem, url, depois=pronto)
            cx.pack_start(sw, False, False, 0)

        if d.get("descricao"):
            cart = classe(Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8), "loja-cartao")
            cart.pack_start(rotulo("Descrição", "loja-subtitulo"), False, False, 0)
            l = rotulo("", selecionavel=True)
            try:
                l.set_markup(d["descricao"])
            except Exception:  # noqa: BLE001
                l.set_text(d["descricao"])
            cart.pack_start(l, False, False, 0)
            cx.pack_start(cart, False, False, 0)
        if d.get("site"):
            cx.pack_start(Gtk.LinkButton(uri=d["site"], label="Página do projeto", halign=Gtk.Align.START),
                          False, False, 0)
        cx.pack_start(rotulo(f"ID no Flathub: {d['id']}", "loja-dim loja-pequeno", selecionavel=True), False, False, 0)
        cx.show_all()
        self.progresso.hide()
        self.progresso_texto.hide()
        self.encher_botoes()

    def encher_botoes(self):
        d = getattr(self, "app_atual", None)
        if not d:
            return
        limpar(self.botoes)
        inst = self.instaladas.get(d["id"])
        if self.operacao:
            b = Gtk.Button(label="Cancelar")
            b.connect("clicked", lambda *_: self.operacao and self.operacao.cancelar())
            self.botoes.pack_start(b, False, False, 0)
        elif inst:
            b = classe(Gtk.Button(label="Abrir"), "loja-principal")
            b.connect("clicked", lambda *_: fp.abrir(d["id"]))
            self.botoes.pack_start(b, False, False, 0)
            r = classe(Gtk.Button(label="Remover"), "loja-perigo")
            r.connect("clicked", lambda *_: self.remover(d, inst == "system"))
            self.botoes.pack_start(r, False, False, 0)
        else:
            b = classe(Gtk.Button(label="Instalar"), "loja-principal")
            b.connect("clicked", lambda *_: self.instalar(d))
            b.set_sensitive(fp.disponivel())
            self.botoes.pack_start(b, False, False, 0)
        self.botoes.show_all()

    # ---------- operações do flatpak
    def confirmar(self, texto, secundario, ok="Continuar"):
        d = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.WARNING,
                              buttons=Gtk.ButtonsType.NONE, text=texto)
        d.format_secondary_text(secundario)
        d.add_button("Cancelar", Gtk.ResponseType.CANCEL)
        d.add_button(ok, Gtk.ResponseType.OK)
        r = d.run()
        d.destroy()
        return r == Gtk.ResponseType.OK

    def instalar(self, d):
        if self.operacao:
            return
        if fp.sessao_live() and not fp.com_persistencia() and not self.aviso_live_dado:
            if not self.confirmar("Sessão live sem disco de dados",
                                  "A aplicação fica na memória (RAM) e perde-se ao desligar o computador. "
                                  "Para a guardar use primeiro: sudo ianinja-persistencia listar (e depois criar).",
                                  "Instalar na mesma"):
                return
            self.aviso_live_dado = True
        precisa = (d.get("tamanho_instalado") or 0) * 1.2
        livre = fp.espaco_livre()
        if precisa and livre < precisa:
            if not self.confirmar("Pouco espaço livre",
                                  f"A aplicação ocupa cerca de {fh.tamanho_legivel(d['tamanho_instalado'])} "
                                  f"(mais os componentes partilhados, se faltarem) e há "
                                  f"{fh.tamanho_legivel(livre)} livres.", "Tentar na mesma"):
                return
        self.executar(fp.op_instalar(d["id"]), d, "instalada")

    def remover(self, d, sistema):
        if sistema:
            self.mensagem_curta("Instalada no sistema",
                                f"{d['nome']} foi instalada para todos os utilizadores. Remova-a num terminal com:\n"
                                f"sudo flatpak uninstall {d['id']}")
            return
        if self.confirmar(f"Remover {d['nome']}?", "Os dados da aplicação em ~/.var/app ficam guardados.",
                          "Remover"):
            self.executar(fp.op_remover(d["id"]), d, "removida")

    def mensagem_curta(self, titulo, texto):
        m = Gtk.MessageDialog(transient_for=self, modal=True, message_type=Gtk.MessageType.INFO,
                              buttons=Gtk.ButtonsType.CLOSE, text=titulo)
        m.format_secondary_text(texto)
        m.run()
        m.destroy()

    def executar(self, op, d, acao, depois=None):
        try:
            op.iniciar()
        except OSError as e:
            self.mensagem_curta("Não foi possível correr o flatpak", str(e))
            return
        self.operacao = op
        self.encher_botoes()
        if getattr(self, "app_atual", None) is d:
            self.progresso.show()
            self.progresso_texto.show()
            self.progresso.set_fraction(0)
            self.progresso_texto.set_text(op.estado["texto"])

        def ler(fd, _cond):
            vivo = op.ler()
            if getattr(self, "app_atual", None) is d and self.progresso.get_visible():
                self.progresso.set_fraction(op.estado["fracao"])
                self.progresso_texto.set_text(op.estado["texto"])
            if vivo:
                return True
            rc = op.terminar()
            self.operacao = None

            def fim():
                if getattr(self, "app_atual", None) is d:
                    self.progresso.hide()
                    self.progresso_texto.hide()
                    self.encher_botoes()
                if rc != 0:
                    self.mensagem_curta(f"{d['nome']} não foi {acao}", op.erro())
                if depois:
                    depois()
            self.atualizar_instaladas(depois=fim)
            return False
        GLib.io_add_watch(op.fd, GLib.PRIORITY_DEFAULT, GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR, ler)

    # ---------- instaladas / atualizações / oficiais
    def pagina_instaladas(self):
        cx = self.cx_instaladas
        self.a_carregar(cx, "Instaladas")
        self.ir("instaladas")
        self.pagina_anterior = "instaladas"

        def pronto(apps):
            limpar(cx)
            cx.pack_start(rotulo("Instaladas", "loja-titulo"), False, False, 0)
            if not apps:
                cx.pack_start(rotulo("Ainda não instalou nenhuma aplicação do Flathub.", "loja-dim"),
                              False, False, 0)
            lista = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
            for a in apps:
                lista.pack_start(self.linha_app(a), False, False, 0)
            cx.pack_start(lista, False, False, 0)
            cx.show_all()
        em_fundo(fp.instaladas, depois=pronto, erro=lambda e: self.mensagem("Erro", str(e), "dialog-error"))

    def linha_app(self, a, botao=None):
        ev = Gtk.EventBox()
        b = classe(Gtk.Box(spacing=14), "loja-cartao", "loja-cartao-clicavel")
        b.pack_start(imagem_app(None, 48, a["id"]), False, False, 0)
        t = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        t.pack_start(rotulo(a["nome"], "loja-cartao-nome"), False, False, 0)
        extra = " · ".join(x for x in (a.get("versao"), a.get("tamanho"),
                                       "sistema" if a.get("instalacao") == "system" else "") if x)
        t.pack_start(rotulo(extra or a["id"], "loja-dim loja-pequeno"), False, False, 0)
        b.pack_start(t, True, True, 0)
        if botao:
            b.pack_end(botao, False, False, 0)
        else:
            ab = classe(Gtk.Button(label="Abrir"), "loja-obter")
            ab.set_valign(Gtk.Align.CENTER)
            ab.connect("clicked", lambda *_: fp.abrir(a["id"]))
            b.pack_end(ab, False, False, 0)
        ev.add(b)
        ev.connect("button-release-event", lambda *_: self.mostrar_app(a["id"], a))
        return ev

    def pagina_atualizacoes(self):
        cx = self.cx_atualizacoes
        self.a_carregar(cx, "Atualizações")
        self.ir("atualizacoes")
        self.pagina_anterior = "atualizacoes"

        def pronto(apps):
            limpar(cx)
            cab = Gtk.Box(spacing=12)
            cab.pack_start(rotulo("Atualizações", "loja-titulo"), True, True, 0)
            cx.pack_start(cab, False, False, 0)
            if not apps:
                cx.pack_start(rotulo("Está tudo atualizado.", "loja-dim"), False, False, 0)
            else:
                tudo = classe(Gtk.Button(label="Atualizar tudo"), "loja-principal")
                tudo.set_valign(Gtk.Align.CENTER)
                cab.pack_end(tudo, False, False, 0)
                prog = classe(Gtk.ProgressBar(show_text=True), "loja-progresso")

                def todas(_b):
                    if self.operacao:
                        return
                    tudo.set_sensitive(False)
                    cx.pack_start(prog, False, False, 0)
                    prog.show()
                    op = fp.op_atualizar()
                    self.executar(op, {"nome": "A atualização", "id": ""}, "concluída",
                                  depois=self.pagina_atualizacoes)

                    def tique():
                        prog.set_fraction(op.estado["fracao"])
                        prog.set_text(op.estado["texto"])
                        return self.operacao is op
                    GLib.timeout_add(300, tique)
                tudo.connect("clicked", todas)
                for a in apps:
                    cx.pack_start(self.linha_app(a), False, False, 0)
            cx.show_all()
        em_fundo(fp.atualizacoes, depois=pronto, erro=self.erro_rede)

    def pagina_oficiais(self):
        cx = self.cx_oficiais
        limpar(cx)
        cx.pack_start(rotulo("Aplicações oficiais", "loja-titulo"), False, False, 0)
        cx.pack_start(rotulo("Versões oficiais descarregadas dos sites dos fabricantes (não vêm na ISO por "
                             "causa das licenças). Instalam-se com o comando instalar-aplicacoes, numa "
                             "janela de terminal.", "loja-dim"), False, False, 0)
        g = grelha()
        g.set_max_children_per_line(2)
        self.estado_oficiais = {}
        tem = shutil.which("instalar-aplicacoes")
        for chave, nome, desc, icone in OFICIAIS:
            b = classe(Gtk.Box(spacing=12), "loja-cartao")
            im = Gtk.Image.new_from_gicon(Gio.ThemedIcon.new_from_names(icone), Gtk.IconSize.DIALOG)
            im.set_pixel_size(56)
            b.pack_start(im, False, False, 0)
            t = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            t.pack_start(rotulo(nome, "loja-cartao-nome"), False, False, 0)
            t.pack_start(rotulo(desc, "loja-dim loja-pequeno"), False, False, 0)
            est = rotulo("", "loja-dim loja-pequeno")
            self.estado_oficiais[chave] = est
            t.pack_start(est, False, False, 0)
            b.pack_start(t, True, True, 0)
            bt = classe(Gtk.Button(label="Instalar"), "loja-obter")
            bt.set_valign(Gtk.Align.CENTER)
            bt.set_sensitive(bool(tem))
            bt.set_tooltip_text(f"instalar-aplicacoes {chave}")
            bt.connect("clicked", lambda _b, c=chave, n=nome: self.instalar_oficial(c, n))
            b.pack_end(bt, False, False, 0)
            g.add(b)
        cx.pack_start(g, False, False, 0)
        if not tem:
            cx.pack_start(rotulo("O comando instalar-aplicacoes não está instalado.", "loja-dim"), False, False, 0)
        cx.show_all()
        self.ir("oficiais")
        self.pagina_anterior = "oficiais"
        if tem:
            em_fundo(self.ler_estado_oficiais, depois=self.mostrar_estado_oficiais)

    @staticmethod
    def ler_estado_oficiais():
        r = subprocess.run(["instalar-aplicacoes", "-l"], capture_output=True, text=True, timeout=60)
        estado = {}
        for l in r.stdout.splitlines():
            p = l.split()
            if p and p[0] in ("vscode", "chrome", "claude", "codex"):
                titulo = dict((c, n) for c, n, _d, _i in OFICIAIS)[p[0]]
                resto = l.split(None, 1)[1] if len(p) > 1 else ""
                # a linha é "  <chave> <título em 24 colunas> <estado>"
                estado[p[0]] = resto[24:].strip() if len(resto) > 24 else resto.replace(titulo, "").strip()
        return estado

    def mostrar_estado_oficiais(self, estado):
        for c, l in self.estado_oficiais.items():
            l.set_text(estado.get(c, ""))

    def instalar_oficial(self, chave, nome):
        term = shutil.which("xfce4-terminal")
        cmd = ["instalar-aplicacoes", "--janela", chave]
        try:
            if term:
                p = subprocess.Popen([term, f"--title=Instalar {nome}", "--geometry=100x34", "-x"] + cmd)
            else:
                p = subprocess.Popen(cmd)
        except OSError as e:
            self.mensagem_curta("Não foi possível abrir o terminal", str(e))
            return
        GLib.child_watch_add(GLib.PRIORITY_DEFAULT, p.pid,
                             lambda *_: em_fundo(self.ler_estado_oficiais, depois=self.mostrar_estado_oficiais))


class Loja(Gtk.Application):
    def __init__(self):
        super().__init__(application_id=ID_APP, flags=Gio.ApplicationFlags.FLAGS_NONE)

    def do_startup(self):
        Gtk.Application.do_startup(self)
        prov = Gtk.CssProvider()
        prov.load_from_path(CSS)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), prov,
                                                 Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def do_activate(self):
        j = self.get_active_window() or Janela(self)
        j.present()


def verificar():
    """Verificação sem ecrã (usada na construção): CSS válido, flatpak e remote do utilizador."""
    Gtk.CssProvider().load_from_path(CSS)
    print("GTK", Gtk.get_major_version(), Gtk.get_minor_version(), Gtk.get_micro_version(), "— CSS ok")
    print("flatpak:", fp.FLATPAK, "disponível" if fp.disponivel() else "EM FALTA")
    if not fp.disponivel():
        return 1
    ok, err = fp.preparar_remote()
    print("remote flathub (--user):", "ok" if ok else f"falhou: {err}")
    print("instaladas:", len(fp.instaladas()))
    print("sessão live:", fp.sessao_live(), "| persistência:", fp.com_persistencia())
    return 0 if ok else 1


if __name__ == "__main__":
    if "--verificar" in sys.argv[1:]:
        sys.exit(verificar())
    GLib.set_prgname("loja")          # WM_CLASS "loja" = loja.desktop (a dock junta a janela ao lançador)
    GLib.set_application_name("Loja")
    sys.exit(Loja().run([sys.argv[0]]))
