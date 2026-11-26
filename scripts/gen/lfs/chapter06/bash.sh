# Gerado de LFS 12.4 chapter06/bash.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make DESTDIR=$LFS install

# --- bloco 4 (userinput)
echo '>>> bloco 4'
ln -sv bash $LFS/bin/sh

