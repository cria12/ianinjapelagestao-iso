# Gerado de BLFS 12.4 x/xorg7.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: <PREFIX> -> /usr (prefixo recomendado pelo livro; evita os blocos 6-11)]
export XORG_PREFIX="/usr"

# --- bloco 2 (userinput)
echo '>>> bloco 2'
export XORG_CONFIG="--prefix=$XORG_PREFIX --sysconfdir=/etc \
    --localstatedir=/var --disable-static"

# --- bloco 3 [omitido: só para a shell zsh]
#   set -o shwordsplit

# --- bloco 4 (root)
echo '>>> bloco 4'
cat > /etc/profile.d/xorg.sh << EOF
XORG_PREFIX="$XORG_PREFIX"
XORG_CONFIG="--prefix=\$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"
export XORG_PREFIX XORG_CONFIG
EOF
chmod 644 /etc/profile.d/xorg.sh

# --- bloco 5 [omitido: sudoers env_keep: compila-se como root no chroot (sem sudo)]
#   cat > /etc/sudoers.d/xorg << EOF
#   Defaults env_keep += XORG_PREFIX
#   Defaults env_keep += XORG_CONFIG
#   EOF

# --- bloco 6 [omitido: só se XORG_PREFIX não for /usr]
#   cat >> /etc/profile.d/xorg.sh << "EOF"
#   
#   pathappend $XORG_PREFIX/bin             PATH
#   pathappend $XORG_PREFIX/lib/pkgconfig   PKG_CONFIG_PATH
#   pathappend $XORG_PREFIX/share/pkgconfig PKG_CONFIG_PATH
#   
#   pathappend $XORG_PREFIX/lib             LIBRARY_PATH
#   pathappend $XORG_PREFIX/include         C_INCLUDE_PATH
#   pathappend $XORG_PREFIX/include         CPLUS_INCLUDE_PATH
#   
#   ACLOCAL="aclocal -I $XORG_PREFIX/share/aclocal"
#   
#   export PATH PKG_CONFIG_PATH ACLOCAL LIBRARY_PATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
#   EOF

# --- bloco 7 (userinput)
echo '>>> bloco 7'
source /etc/profile.d/xorg.sh

# --- bloco 8 [omitido: só se XORG_PREFIX não for /usr]
#   echo "$XORG_PREFIX/lib" >> /etc/ld.so.conf

# --- bloco 9 [omitido: só se XORG_PREFIX não for /usr]
#   sed -e "s@X11R6/man@X11R6/share/man@g" \
#       -e "s@/usr/X11R6@$XORG_PREFIX@g"   \
#       -i /etc/man_db.conf

# --- bloco 10 [omitido: só se XORG_PREFIX não for /usr]
#   ln -svf $XORG_PREFIX/share/X11 /usr/share/X11

# --- bloco 11 [omitido: só se XORG_PREFIX não for /usr]
#   ln -svf $XORG_PREFIX /usr/X11R6

