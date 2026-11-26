# Gerado de LFS 12.4 chapter08/libcap.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i '/install -m.*STA/d' libcap/Makefile

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make prefix=/usr lib=lib

# --- bloco 3 [teste]
echo '>>> bloco 3 (teste)'
if ! (
make test
); then echo '[AVISO-TESTE] bloco 3 terminou com falhas'; fi

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make prefix=/usr lib=lib install

