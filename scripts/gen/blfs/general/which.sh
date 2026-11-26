# Gerado de BLFS 12.4 general/which.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr &&
make

# --- bloco 2 (root)
echo '>>> bloco 2'
make install

# --- bloco 3 [omitido: alternativa ao programa which (script com type -pa) — instala-se o programa]
#   cat > /usr/bin/which << "EOF"
#   #!/bin/bash
#   type -pa "$@" | head -n 1 ; exit ${PIPESTATUS[0]}
#   EOF
#   chmod -v 755 /usr/bin/which
#   chown -v root:root /usr/bin/which

