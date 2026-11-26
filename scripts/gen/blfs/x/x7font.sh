# Gerado de BLFS 12.4 x/x7font.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
cat > font-7.md5 << "EOF"
a6541d12ceba004c0c1e3df900324642  font-util-1.4.1.tar.xz
a56b1a7f2c14173f71f010225fa131f1  encodings-1.1.0.tar.xz
79f4c023e27d1db1dfd90d041ce89835  font-alias-1.0.5.tar.xz
546d17feab30d4e3abcf332b454f58ed  font-adobe-utopia-type1-1.0.5.tar.xz
063bfa1456c8a68208bf96a33f472bb1  font-bh-ttf-1.0.4.tar.xz
51a17c981275439b85e15430a3d711ee  font-bh-type1-1.0.4.tar.xz
00f64a84b6c9886040241e081347a853  font-ibm-type1-1.0.4.tar.xz
fe972eaf13176fa9aa7e74a12ecc801a  font-misc-ethiopic-1.0.5.tar.xz
3b47fed2c032af3a32aad9acc1d25150  font-xfree86-type1-1.0.5.tar.xz
EOF

# --- bloco 2 [substituído: mkdir -p font (o passo pode ser repetido)]
mkdir -p font &&
cd font &&
grep -v '^#' ../font-7.md5 | awk '{print $2}' | wget -i- -c \
    -B https://www.x.org/pub/individual/font/ &&
md5sum -c ../font-7.md5

# --- bloco 3 [omitido: definição de as_root com sudo/su (compila-se como root; as_root vem de blfs-env.sh)]
#   as_root()
#   {
#     if   [ $EUID = 0 ];        then $*
#     elif [ -x /usr/bin/sudo ]; then sudo $*
#     else                            su -c \\"$*\\"
#     fi
#   }
#   
#   export -f as_root

# --- bloco 4 [omitido: "bash -e" / "exit": subshell interativo do livro]
#   bash -e

# --- bloco 5 (userinput)
echo '>>> bloco 5'
for package in $(grep -v '^#' ../font-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.?z*}
  tar -xf $package
  pushd $packagedir
    ./configure $XORG_CONFIG
    make
    as_root make install
  popd
  as_root rm -rf $packagedir
done

# --- bloco 6 [omitido: "bash -e" / "exit": subshell interativo do livro]
#   exit

# --- bloco 7 (root)
echo '>>> bloco 7'
install -v -d -m755 /usr/share/fonts                               &&
ln -svfn $XORG_PREFIX/share/fonts/X11/OTF /usr/share/fonts/X11-OTF &&
ln -svfn $XORG_PREFIX/share/fonts/X11/TTF /usr/share/fonts/X11-TTF

