# Gerado de BLFS 12.4 general/valgrind.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i 's|/doc/valgrind||' docs/Makefile.in &&

./configure --prefix=/usr \
            --datadir=/usr/share/doc/valgrind-3.25.1 &&
make

# --- bloco 2 [omitido: só prepara a suite de testes (make regtest), que não corre]
#   sed -e 's@prereq:.*@prereq: false@' \
#       -i {helgrind,drd}/tests/pth_cond_destroy_busy.vgtest

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

