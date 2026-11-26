# Gerado de LFS 12.4 chapter05/linux-headers.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
make mrproper

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

