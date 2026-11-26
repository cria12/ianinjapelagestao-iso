# Gerado de LFS 12.4 chapter08/lz4.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
make BUILD_STATIC=no PREFIX=/usr

# --- bloco 2 [teste]
echo '>>> bloco 2 (teste)'
if ! (
make -j1 check
); then echo '[AVISO-TESTE] bloco 2 terminou com falhas'; fi

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make BUILD_STATIC=no PREFIX=/usr install

