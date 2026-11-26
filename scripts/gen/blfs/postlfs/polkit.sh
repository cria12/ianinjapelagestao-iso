# Gerado de BLFS 12.4 postlfs/polkit.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: utilizador/grupo polkitd criados só se não existirem (permite repetir o passo)]
{ getent group polkitd > /dev/null || groupadd -fg 27 polkitd; } &&
{ getent passwd polkitd > /dev/null ||
  useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 \
          -g polkitd -s /bin/false polkitd; }

# --- bloco 2 [substituído: -D man=false (DocBook não instalado, como o livro indica) e -D tests=false (testes precisam de dbusmock e D-Bus a correr)]
mkdir build &&
cd    build &&

meson setup ..                     \
      --prefix=/usr                \
      --buildtype=release          \
      -D man=false                 \
      -D session_tracking=elogind  \
      -D systemdsystemunitdir=/tmp \
      -D tests=false

# --- bloco 3 (userinput)
echo '>>> bloco 3'
ninja

# --- bloco 4 (root)
echo '>>> bloco 4'
ninja install

# --- bloco 5 (root)
echo '>>> bloco 5'
rm -v /tmp/*.service                 &&
rm -rf /usr/lib/{sysusers,tmpfiles}.d 

