# F8e — funções do bloco 11: guardar os dados automaticamente (persistência escolhida no assistente).
# Lido por scripts/f08e-apps.sh. Correm sob corre_passo (sem errexit): cada comando termina com
# || return 1. Ver decisoes-11.txt e scripts/apps/persistencia/CONTRATO.md. Nada é compilado.
# O lado do arranque (initramfs: scripts/live-init.sh, módulos ntfs3/exfat) é da F9.
PERSIST_SRC=$P/scripts/apps/persistencia
ASSIST_SRC=$P/scripts/apps/assistente

# persistencia_instalar — /usr/sbin/ianinja-persistencia (backend: estado/listar/criar) e a versão
# do assistente que o chama (assistente.py, contas.py com as ações persistencia-*, aplicar, CSS,
# sudoers): o bloco 09 já instalou estes ficheiros, mas voltam a instalar-se aqui para a imagem
# levar a versão com a página "Onde guardar os seus dados?" sem repetir o bloco 09.
persistencia_instalar() {
  local f
  install -v -m755 $PERSIST_SRC/ianinja-persistencia $LFS/usr/sbin/ianinja-persistencia || return 1
  for f in assistente.py contas.py estilo.css; do
    install -v -m644 $ASSIST_SRC/$f $LFS/usr/share/ianinja-assistente/$f || return 1
  done
  install -v -m755 $ASSIST_SRC/aplicar $LFS/usr/libexec/ianinja-assistente/aplicar || return 1
  install -v -m440 $ASSIST_SRC/sudoers $LFS/etc/sudoers.d/ianinja-assistente || return 1
  rm -rf $LFS/usr/share/ianinja-assistente/__pycache__
  in_chroot "set -e
    chown -R root:root /usr/share/ianinja-assistente /usr/libexec/ianinja-assistente /usr/sbin/ianinja-persistencia
    visudo -cf /etc/sudoers.d/ianinja-assistente
    python3 -c 'import ast, sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]' \
      /usr/sbin/ianinja-persistencia /usr/share/ianinja-assistente/assistente.py \
      /usr/share/ianinja-assistente/contas.py /usr/libexec/ianinja-assistente/aplicar
    # ferramentas que o backend usa em execução (util-linux, e2fsprogs, coreutils, kmod, udev)
    for c in lsblk sfdisk partx losetup fallocate wipefs isosize findmnt mkfs.ext4 cp du sync udevadm modprobe mount umount; do
      type -P \$c > /dev/null || { echo \"falta \$c\"; exit 1; }
    done
    # o cp do LFS preserva xattrs e ACLs (a cópia da camada de escrita precisa dos trusted.overlay.*)
    rm -rf /tmp/xa; mkdir /tmp/xa; touch /tmp/xa/a; setfattr -n trusted.overlay.opaque -v y /tmp/xa/a
    cp -a /tmp/xa/a /tmp/xa/b; [ \"\$(getfattr --only-values -n trusted.overlay.opaque /tmp/xa/b)\" = y ] \
      || { echo 'cp -a não preserva xattrs trusted.*'; exit 1; }
    rm -rf /tmp/xa
    # os módulos que o initramfs leva para os discos NTFS/exFAT (ou embutidos)
    KV=\$(ls /lib/modules | head -1)
    for m in ntfs3 exfat; do
      ls /lib/modules/\$KV/kernel/fs/\$m/\$m.ko* > /dev/null 2>&1 || grep -q \"CONFIG_\${m^^}_FS=y\" /boot/config-\$KV \
        || { echo \"sem módulo \$m\"; exit 1; }
    done
    ianinja-persistencia --ajuda > /dev/null" || return 1
}

# persistencia_verificar — fora do sistema live (chroot): estado diz inativo em JSON válido, listar
# dá uma lista vazia, criar recusa; o lightdm consegue chamar as ações novas pelo sudo (e só essas);
# o greeter continua a só ter sudo para o aplicar.
persistencia_verificar() {
  in_chroot "set -e
    e=\$(ianinja-persistencia estado --json)
    echo \"estado: \$e\"
    python3 -c 'import json, sys; d = json.loads(sys.argv[1]); assert d[\"ativo\"] is False and d[\"tipo\"] is None' \"\$e\"
    l=\$(ianinja-persistencia listar --json)
    echo \"listar: \$l\"
    [ \"\$l\" = '[]' ]
    if ianinja-persistencia criar pen:/dev/sdz > /tmp/p.out; then echo 'ERRO: criar fora do live devia falhar'; exit 1; fi
    grep -q '^ERRO' /tmp/p.out; rm -f /tmp/p.out
    e=\$(su -s /bin/sh lightdm -c '/usr/bin/sudo -n /usr/libexec/ianinja-assistente/aplicar persistencia-estado')
    echo \"estado pelo lightdm: \$e\"
    python3 -c 'import json, sys; json.loads(sys.argv[1])' \"\$e\"
    l=\$(su -s /bin/sh lightdm -c '/usr/bin/sudo -n /usr/libexec/ianinja-assistente/aplicar persistencia-listar')
    [ \"\$l\" = '[]' ]
    if echo '{\"id\": \"pen:/dev/sdz\"}' | su -s /bin/sh lightdm -c '/usr/bin/sudo -n /usr/libexec/ianinja-assistente/aplicar persistencia-criar' > /tmp/p.out; then
      echo 'ERRO: persistencia-criar fora do live devia falhar'; exit 1
    fi
    grep -q '^ERRO' /tmp/p.out; rm -f /tmp/p.out
    if su -s /bin/sh lightdm -c '/usr/bin/sudo -n /usr/libexec/ianinja-assistente/aplicar repor' 2>/dev/null; then
      echo 'ERRO: o lightdm conseguiu repor'; exit 1
    fi
    if su -s /bin/sh lightdm -c '/usr/bin/sudo -n /usr/sbin/ianinja-persistencia estado' 2>/dev/null; then
      echo 'ERRO: o lightdm chama o backend diretamente'; exit 1
    fi
    ia-criar-persistencia --ajuda > /dev/null 2>&1 || true
    echo 'persistência: verificação OK'" || return 1
}
