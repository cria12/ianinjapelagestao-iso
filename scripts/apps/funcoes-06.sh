# F8e — funções do bloco 6 (correções no fim da etapa): VTE recompilada com GnuTLS.
# Lido por scripts/f08e-apps.sh. Correm sob corre_passo (sem errexit): cada comando termina com
# || return 1. Ver decisoes-06.txt.

# apps_vte_gnutls — reinstala a VTE 0.80.3 da F8d com -D gnutls=true. A F8d compilou-a com
# gnutls=false (o GnuTLS só chega na F8e, passos-01) e assim a VTE escreve a vermelho em cada
# terminal novo "AVISO: GnuTLS não está ativo; os dados serão escritos no disco desencriptados!"
# (#if !WITH_GNUTLS em src/vte.cc). Os overrides são por página (gnome/vte já tem o replace da
# F8d), por isso gera-se uma cópia do script da página (gnome/vte-gnutls.sh) com só essa opção
# trocada e corre-se com o run-blfs.sh e o mesmo tarball (verificado pelo MD5 do livro).
apps_vte_gnutls() {
  local tb g=$LFS/sources/ianinja/gen/blfs/gnome/vte-gnutls.sh
  $FETCH fetch $BLFS $LFS/sources gnome/vte || return 1
  tb=$($FETCH tarball $BLFS gnome/vte) || return 1
  python3 $S/gen-scripts.py blfs $BLFS gnome/vte > /dev/null || return 1
  mkdir -p $(dirname $g) || return 1
  sed 's|-D gnutls=false|-D gnutls=true |' $S/gen/blfs/gnome/vte.sh > $g || return 1
  grep -q -- '-D gnutls=true' $g || { echo "opção gnutls não encontrada em gen/blfs/gnome/vte.sh"; return 1; }
  ! grep -q -- 'gnutls=false' $g || { echo "gnutls=false ainda presente em $g"; return 1; }
  in_chroot "test -f /usr/lib/pkgconfig/gnutls.pc && bash /sources/ianinja/run-blfs.sh gnome/vte-gnutls $tb" || return 1
  in_chroot "set -e
    ldconfig
    ldd /usr/lib/libvte-2.91.so | grep libgnutls
    ! grep -q 'GnuTLS not enabled' /usr/lib/libvte-2.91.so
    ! ls /etc/profile.d/vte.* 2> /dev/null" || return 1
}
