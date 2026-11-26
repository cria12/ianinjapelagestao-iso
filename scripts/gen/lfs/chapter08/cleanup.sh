# Gerado de LFS 12.4 chapter08/cleanup.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [teste]
echo '>>> bloco 1 (teste)'
if ! (
rm -rf /tmp/{*,.*}
); then echo '[AVISO-TESTE] bloco 1 terminou com falhas'; fi

# --- bloco 2 (userinput)
echo '>>> bloco 2'
find /usr/lib /usr/libexec -name \*.la -delete

# --- bloco 3 (userinput)
echo '>>> bloco 3'
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf

# --- bloco 4 (userinput)
echo '>>> bloco 4'
userdel -r tester

