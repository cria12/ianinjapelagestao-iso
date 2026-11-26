# Gerado de BLFS 12.4 general/gdb.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir build &&
cd    build &&

../configure --prefix=/usr          \
             --with-system-readline \
             --with-system-zlib     \
             --with-python=/usr/bin/python3 &&
make

# --- bloco 2 [omitido: documentação da API precisa do Doxygen (não instalado)]
#   make -C gdb/doc doxy

# --- bloco 3 [omitido: testes: o livro não os recomenda (3 a 15 SBU, dezenas de falhas esperadas)]
#   pushd gdb/testsuite &&
#   make  site.exp      &&
#   echo  "set gdb_test_timeout 30" >> site.exp &&
#   make check 2>1 | tee gdb-check.log
#   popd

# --- bloco 4 (root)
echo '>>> bloco 4'
make -C gdb install &&
make -C gdbserver install

# --- bloco 5 [omitido: cópia da documentação Doxygen (bloco 2 omitido)]
#   install -d /usr/share/doc/gdb-16.3 &&
#   rm -rf gdb/doc/doxy/xml &&
#   cp -Rv gdb/doc/doxy /usr/share/doc/gdb-16.3

