# Gerado de LFS 12.4 chapter08/intltool.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i 's:\\\${:\\\$\\{:' intltool-update.in

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make

# --- bloco 4 [teste]
echo '>>> bloco 4 (teste)'
if ! (
make check
); then echo '[AVISO-TESTE] bloco 4 terminou com falhas'; fi

# --- bloco 5 (userinput)
echo '>>> bloco 5'
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

