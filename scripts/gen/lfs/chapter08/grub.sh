# Gerado de LFS 12.4 chapter08/grub.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
unset {C,CPP,CXX,LD}FLAGS

# --- bloco 2 (userinput)
echo '>>> bloco 2'
echo depends bli part_gpt > grub-core/extra_deps.lst

# --- bloco 3 (userinput)
echo '>>> bloco 3'
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-efiemu  \
            --disable-werror

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make

# --- bloco 5 (userinput)
echo '>>> bloco 5'
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

