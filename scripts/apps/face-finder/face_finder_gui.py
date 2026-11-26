#!/usr/bin/env python3
"""Face Finder — interface gráfica (GTK 3 via PyGObject).

Escolha uma imagem ou uma pasta; cada imagem aparece na lista à esquerda com o número de rostos
encontrados e, à direita, com as caixas e os pontos desenhados. A deteção é a mesma da linha de
comandos (face_finder.py): YuNet do OpenCV, sem rede, sem identificar ninguém.
"""
import os
import sys

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk  # noqa: E402

import cv2  # noqa: E402

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import face_finder as ff  # noqa: E402


def pixbuf_de(img_bgr):
    rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    h, w = rgb.shape[:2]
    return GdkPixbuf.Pixbuf.new_from_bytes(GLib.Bytes.new(rgb.tobytes()), GdkPixbuf.Colorspace.RGB,
                                           False, 8, w, h, w * 3)


def pasta_inicial():
    for p in (os.path.join(GLib.get_home_dir(), "Projetos", "face-finder", "fotos"),
              os.path.join(os.path.dirname(os.path.abspath(__file__)), "fotos"),
              "/usr/share/face-finder/fotos"):
        if os.path.isdir(p):
            return p
    return GLib.get_home_dir()


class Janela(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Face Finder")
        self.set_default_size(1100, 720)
        self.set_icon_name("face-finder")
        self.limiar = 0.8
        self.detetor = None
        self.itens = []          # [(caminho, img_marcada_ou_None, rostos)]
        self.pixbuf = None
        self.fila = []

        barra = Gtk.HeaderBar(show_close_button=True, title="Face Finder",
                              subtitle="deteção de rostos (não identifica pessoas)")
        self.set_titlebar(barra)
        b_img = Gtk.Button.new_with_label("Abrir imagem…")
        b_img.connect("clicked", self.escolher, Gtk.FileChooserAction.OPEN)
        b_pasta = Gtk.Button.new_with_label("Abrir pasta…")
        b_pasta.connect("clicked", self.escolher, Gtk.FileChooserAction.SELECT_FOLDER)
        barra.pack_start(b_img)
        barra.pack_start(b_pasta)
        self.b_gravar = Gtk.Button.new_with_label("Gravar imagem…")
        self.b_gravar.set_sensitive(False)
        self.b_gravar.connect("clicked", self.gravar)
        barra.pack_end(self.b_gravar)
        caixa_limiar = Gtk.Box(spacing=6)
        caixa_limiar.pack_start(Gtk.Label(label="Limiar"), False, False, 0)
        self.spin = Gtk.SpinButton.new_with_range(0.30, 0.99, 0.05)
        self.spin.set_digits(2)
        self.spin.set_value(self.limiar)
        self.spin.set_tooltip_text("Confiança mínima: mais baixo encontra mais rostos (e mais enganos)")
        self.spin.connect("value-changed", self.mudou_limiar)
        caixa_limiar.pack_start(self.spin, False, False, 0)
        barra.pack_end(caixa_limiar)

        painel = Gtk.Paned()
        self.lista = Gtk.ListBox()
        self.lista.connect("row-selected", self.selecionou)
        rolar = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.NEVER)
        rolar.set_size_request(260, -1)
        rolar.add(self.lista)
        painel.pack1(rolar, False, False)
        self.area = Gtk.DrawingArea()
        self.area.connect("draw", self.desenhar)
        painel.pack2(self.area, True, False)

        self.estado = Gtk.Label(xalign=0, margin=6)
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        vbox.pack_start(painel, True, True, 0)
        vbox.pack_start(self.estado, False, False, 0)
        self.add(vbox)

        try:
            self.detetor = ff.carregar_detetor(None, self.limiar)
        except (FileNotFoundError, cv2.error) as erro:
            self.estado.set_text(f"Erro: {erro}")
            return
        GLib.idle_add(self.carregar, pasta_inicial())

    # --- escolha de ficheiros
    def escolher(self, _botao, acao):
        d = Gtk.FileChooserDialog(title="Escolher imagem" if acao == Gtk.FileChooserAction.OPEN else "Escolher pasta",
                                  parent=self, action=acao)
        d.add_buttons("_Cancelar", Gtk.ResponseType.CANCEL, "_Abrir", Gtk.ResponseType.ACCEPT)
        d.set_current_folder(pasta_inicial())
        if acao == Gtk.FileChooserAction.OPEN:
            f = Gtk.FileFilter()
            f.set_name("Imagens")
            for ext in ff.EXTENSOES:
                f.add_pattern("*" + ext)
                f.add_pattern("*" + ext.upper())
            d.add_filter(f)
        if d.run() == Gtk.ResponseType.ACCEPT:
            caminho = d.get_filename()
            d.destroy()
            self.carregar(caminho)
        else:
            d.destroy()

    def carregar(self, entrada):
        try:
            self.fila = ff.listar_imagens(entrada)
        except FileNotFoundError as erro:
            self.estado.set_text(str(erro))
            return False
        self.entrada = entrada
        self.itens = []
        for linha in self.lista.get_children():
            self.lista.remove(linha)
        self.pixbuf = None
        self.area.queue_draw()
        if not self.fila:
            self.estado.set_text(f"Nenhuma imagem em {entrada}")
            return False
        self.estado.set_text(f"A analisar {len(self.fila)} imagem(ns)…")
        GLib.idle_add(self.proxima)   # uma imagem de cada vez: a janela continua a responder
        return False

    def proxima(self):
        if not self.fila:
            total = sum(len(r) for _, _, r in self.itens)
            self.estado.set_text(f"{total} rosto(s) em {len(self.itens)} imagem(ns) · {self.entrada} · limiar {self.limiar:.2f}")
            return False
        caminho = self.fila.pop(0)
        img = ff.ler_imagem(caminho)
        rostos = ff.detetar(img, self.detetor) if img is not None else []
        marcada = ff.desenhar(img, rostos) if img is not None else None
        self.itens.append((caminho, marcada, rostos))
        n = len(rostos)
        texto = f"<b>{GLib.markup_escape_text(os.path.basename(caminho))}</b>\n" + \
                (f"{n} rosto{'s' if n != 1 else ''}" if img is not None else "ilegível")
        rotulo = Gtk.Label(xalign=0, margin=6)
        rotulo.set_markup(texto)
        self.lista.add(rotulo)
        self.lista.show_all()
        if len(self.itens) == 1:
            self.lista.select_row(self.lista.get_row_at_index(0))
        return True

    def mudou_limiar(self, spin):
        self.limiar = round(spin.get_value(), 2)
        if self.detetor is None:
            return
        self.detetor.setScoreThreshold(self.limiar)
        if self.itens or self.fila:
            self.carregar(self.entrada)

    # --- visualização
    def selecionou(self, _lista, linha):
        if linha is None:
            return
        caminho, marcada, rostos = self.itens[linha.get_index()]
        self.atual = (caminho, marcada)
        self.pixbuf = pixbuf_de(marcada) if marcada is not None else None
        self.b_gravar.set_sensitive(marcada is not None)
        conf = ", ".join(f"{r['confianca']:.2f}" for r in rostos[:10])
        self.estado.set_text(f"{os.path.basename(caminho)}: {len(rostos)} rosto(s)" + (f" — confiança {conf}" if rostos else ""))
        self.area.queue_draw()

    def desenhar(self, area, cr):
        if self.pixbuf is None:
            return False
        aw, ah = area.get_allocated_width(), area.get_allocated_height()
        w, h = self.pixbuf.get_width(), self.pixbuf.get_height()
        e = min(aw / w, ah / h)
        cr.translate((aw - w * e) / 2, (ah - h * e) / 2)
        cr.scale(e, e)
        Gdk.cairo_set_source_pixbuf(cr, self.pixbuf, 0, 0)
        cr.paint()
        return False

    def gravar(self, _botao):
        caminho, marcada = self.atual
        d = Gtk.FileChooserDialog(title="Gravar imagem marcada", parent=self, action=Gtk.FileChooserAction.SAVE)
        d.add_buttons("_Cancelar", Gtk.ResponseType.CANCEL, "_Gravar", Gtk.ResponseType.ACCEPT)
        d.set_do_overwrite_confirmation(True)
        d.set_current_name(os.path.splitext(os.path.basename(caminho))[0] + "_rostos.jpg")
        if d.run() == Gtk.ResponseType.ACCEPT:
            destino = d.get_filename()
            try:
                ff.gravar_imagem(destino, marcada)
                self.estado.set_text(f"Gravada: {destino}")
            except (OSError, cv2.error) as erro:
                self.estado.set_text(f"Erro ao gravar: {erro}")
        d.destroy()


class App(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="org.ianinja.FaceFinder")

    def do_activate(self):
        (self.get_active_window() or Janela(self)).show_all()
        self.get_active_window().present()


if __name__ == "__main__":
    sys.exit(App().run([sys.argv[0]]))
