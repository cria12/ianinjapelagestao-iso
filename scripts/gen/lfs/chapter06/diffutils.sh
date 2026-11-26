# Gerado de LFS 12.4 chapter06/diffutils.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            gl_cv_func_strcasecmp_works=y \
            --build=$(./build-aux/config.guess)

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make DESTDIR=$LFS install

