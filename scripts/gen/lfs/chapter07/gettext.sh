# Gerado de LFS 12.4 chapter07/gettext.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --disable-shared

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make

# --- bloco 3 (userinput)
echo '>>> bloco 3'
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

