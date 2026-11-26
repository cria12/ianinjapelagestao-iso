# Gerado de BLFS 12.4 general/yasm.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -e 's/def __cplusplus/ defined(__cplusplus) || __STDC_VERSION__ >= 202311L/' \
    -i libyasm/bitvect.h

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sed -i 's#) ytasm.*#)#' Makefile.in &&

./configure --prefix=/usr &&
make

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

