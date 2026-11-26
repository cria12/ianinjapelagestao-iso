# Gerado de BLFS 12.4 basicnet/networkmanager.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
grep -rl '^#!.*python$' | xargs sed -i '1s/python/&3/'

# --- bloco 2 [substituído: + -D vapi=false (sem Vala) e -D tests=no (testes precisam de sessão D-Bus/gráfica; não se compilam)]
mkdir build &&
cd    build &&
meson setup ..                    \
      --prefix=/usr               \
      --buildtype=release         \
      -D libaudit=no              \
      -D nmtui=true               \
      -D ovs=false                \
      -D ppp=false                \
      -D nbft=false               \
      -D selinux=false            \
      -D session_tracking=elogind \
      -D modem_manager=false      \
      -D systemdsystemunitdir=no  \
      -D systemd_journal=false    \
      -D nm_cloud_setup=false     \
      -D qt=false                 \
      -D vapi=false               \
      -D tests=no                 &&
ninja

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install &&
mv -v /usr/share/doc/NetworkManager{,-1.54.0}

# --- bloco 4 (root)
echo '>>> bloco 4'
for file in $(echo ../man/*.[1578]); do
    section=${file##*.} &&
    install -vdm 755 /usr/share/man/man$section
    install -vm 644 $file /usr/share/man/man$section/
done

# --- bloco 5 [omitido: documentação HTML da API (libnm) — poupa espaço na ISO; ficam as páginas man]
#   cp -Rv ../docs/{api,libnm} /usr/share/doc/NetworkManager-1.54.0

# --- bloco 6 [substituído: NetworkManager.conf com ">" (o ">>" do livro duplicaria [main] se o passo fosse repetido)]
# ianinjapelagestao: ">" em vez de ">>" (o passo pode ser repetido sem duplicar a secção [main])
install -v -d -m755 /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/NetworkManager.conf << "EOF2"
[main]
plugins=keyfile
EOF2

# --- bloco 7 (root)
echo '>>> bloco 7'
cat > /etc/NetworkManager/conf.d/polkit.conf << "EOF"
[main]
auth-polkit=true
EOF

# --- bloco 8 [omitido: dhcp=dhcpcd: usa-se o cliente DHCP interno do NetworkManager (por omissão; ver decisoes-08.txt)]
#   cat > /etc/NetworkManager/conf.d/dhcp.conf << "EOF"
#   [main]
#   dhcp=dhcpcd
#   EOF

# --- bloco 9 [omitido: dns=none: o NetworkManager passa a escrever o /etc/resolv.conf (antes era o dhcpcd)]
#   cat > /etc/NetworkManager/conf.d/no-dns-update.conf << "EOF"
#   [main]
#   dns=none
#   EOF

# --- bloco 10 [substituído: <username> = ninja; regra polkit: grupo netdev OU sessão local ativa]
# ianinjapelagestao: <username> = ninja. À regra do livro (grupo netdev) junta-se a sessão local
# ativa (elogind): quem está sentado ao computador gere as redes sem senha, como nas distribuições
# generalistas — também utilizadores criados depois (ex.: assistente do 1.º arranque).
groupadd -fg 86 netdev &&
/usr/sbin/usermod -a -G netdev ninja
cat > /usr/share/polkit-1/rules.d/org.freedesktop.NetworkManager.rules << "EOF2"
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0 &&
        (subject.isInGroup("netdev") || (subject.local && subject.active))) {
        return polkit.Result.YES;
    }
});
EOF2

# --- bloco 11 [omitido: make install-networkmanager corre no passo nm-bootscript (função bootscripts)]
#   make install-networkmanager

