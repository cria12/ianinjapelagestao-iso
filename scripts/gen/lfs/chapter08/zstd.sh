# Gerado de LFS 12.4 chapter08/zstd.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
make prefix=/usr

# --- bloco 2 [teste]
echo '>>> bloco 2 (teste)'
if ! (
make check
); then echo '[AVISO-TESTE] bloco 2 terminou com falhas'; fi

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make prefix=/usr install

# --- bloco 4 (userinput)
echo '>>> bloco 4'
rm -v /usr/lib/libzstd.a

