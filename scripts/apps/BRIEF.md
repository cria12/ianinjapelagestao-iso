# F8e — Aplicações e projeto face-finder — instruções para agentes

Leia primeiro `scripts/gui/BRIEF.md` (contexto, como uma página do livro vira um passo, overrides,
replace, comandos `pacote`/`pacote_rede`/`pagina_config`/`pagina_rede`/`bootscripts`/`baixar`,
regras de NÃO compilar e de só ler /mnt/lfs). Tudo o que lá está vale aqui, com estas diferenças:

- Etapa nova **F8e** (script `scripts/f08e-apps.sh.pendente`, cópia da F8d; ainda não ativa). Corre
  depois da F8d, com TUDO da F8d instalado: Xorg, Mesa, GTK3, Xfce 4.20, LightDM, librsvg, Rust,
  LLVM/Clang, GLib+GObject Introspection, D-Bus, elogind, polkit, libxml2/libxslt (SEM DocBook —
  use man=false/sem documentação), ICU, SQLite, libjpeg/libpng/libtiff, alsa-lib. Lista do que já
  existe: `scripts/apps/feitas.txt` (use-a com `scripts/blfs-deps.py --feitas`).
- Ficheiros por agente (NN atribuído): `scripts/apps/passos-NN.txt`, `scripts/apps/funcoes-NN.sh`,
  `scripts/apps/decisoes-NN.txt`, `scripts/book-overrides.d/apps-NN-<nome>.txt`, `scripts/replace/*`.
  Verificação a seco: copie `scripts/gui/verificar-passos.sh` para `scripts/apps/verificar-passos.sh`
  trocando `gui/passos` por `apps/passos`, `gui/funcoes` por `apps/funcoes` e `f08d-gui.sh*` por
  `f08e-apps.sh*` (só um agente o faz — o NN=01; o outro espera que exista) e corra-o.
- Utilizador do sistema: **ninja** (/home/ninja, UID 1000?, confirme em /mnt/lfs/etc/passwd), sudo sem
  senha. Ficheiros para ele vão para /home/ninja e para /etc/skel (novos utilizadores), com dono certo
  (`chown -R ninja:ninja` no chroot).
- Atalhos no ambiente gráfico: ficheiros `.desktop` em /usr/share/applications (aparecem no menu
  e no xfce4-appfinder/Super+Espaço). A dock é o xfce4-docklike-plugin com os lançadores fixados em
  `/etc/xdg/xfce4/panel/docklike.rc` (veja `scripts/gui/tema/raiz/etc/xdg/xfce4/panel/docklike.rc`);
  pode acrescentar lá entradas, editando esse ficheiro de origem.
- A ISO é live e pública: binários com licença que proíbe redistribuição (VS Code da Microsoft,
  Google Chrome, Claude Code, Codex) NÃO vão dentro da ISO; instalam-se no 1.º uso, a pedido.
