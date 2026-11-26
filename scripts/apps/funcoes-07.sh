# F8e — funções do bloco 7: ícones do diálogo "Terminar sessão" do xfce4-session no WhiteSur.
# Lido por scripts/f08e-apps.sh. Correm sob corre_passo (sem errexit): cada comando termina com
# || return 1. Ver decisoes-07.txt.

# nomes que o xfce4-session 4.20.3 pede no diálogo (xfsm-logout-dialog.c: nome, recurso 1, recurso 2)
# e os do plugin Ações do painel; system-users fica de fora (é só o 2.º recurso do xfsm-switch-user)
ICONES_SESSAO="xfsm-logout xfsm-reboot xfsm-shutdown xfsm-suspend xfsm-hibernate xfsm-switch-user xfsm-lock"
ICONES_SESSAO+=" system-log-out system-reboot system-shutdown system-suspend system-hibernate"
ICONES_SESSAO+=" system-suspend-hibernate system-switch-user system-lock-screen"

# icones_sessao — corre scripts/apps/icones-sessao.sh no chroot (PNG 256x256 desenhados pelo
# rsvg-convert em WhiteSur/apps/scalable, Inherits=Adwaita,hicolor, caches refeitas), instala o
# verificador como /usr/bin/ianinja-verificar-icones e confirma, em WhiteSur-light e WhiteSur, que
# cada nome existe no próprio tema em 16-96 px, se desenha, e que a 48/96 px (o diálogo, escala 1 e
# 2) o GTK escolhe o PNG. Grava a prova visual em /tmp/icones-sessao/ do alvo (fora da ISO).
icones_sessao() {
  local d=$P/scripts/apps t
  install -v -m755 $d/verificar-icones.py $LFS/usr/bin/ianinja-verificar-icones || return 1
  in_chroot "bash -s" < $d/icones-sessao.sh || return 1
  for t in WhiteSur-light WhiteSur; do
    in_chroot "ianinja-verificar-icones --tema $t --exigir-png --png /tmp/icones-sessao --estrito $ICONES_SESSAO" \
      || return 1
  done
  # relatório informativo: Icon= dos .desktop e nomes dos binários do Xfce que faltam no tema
  in_chroot "ianinja-verificar-icones --tema WhiteSur-light" || true
}
