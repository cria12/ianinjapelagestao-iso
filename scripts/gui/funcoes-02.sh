# F8d — funções do bloco 2 (GTK3 e dependências). Lido por scripts/f08d-gui.sh.
# Correm sob corre_passo (sem errexit): cada comando termina com || return 1.

# gdk_pixbuf_loaders — o gdk-pixbuf é instalado antes do librsvg (ciclo do livro), por isso a
# cache /usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache foi gerada sem o loader SVG. O livro não a
# regenera depois do librsvg; sem isto os ícones simbólicos (SVG) do GTK3 não carregam.
gdk_pixbuf_loaders() {
  in_chroot "gdk-pixbuf-query-loaders --update-cache" || return 1
  in_chroot "grep -q 'image/svg' /usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
    || { echo "loader SVG do librsvg não registado em loaders.cache"; return 1; }
}
