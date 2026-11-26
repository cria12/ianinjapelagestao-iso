# Gerado de LFS 12.4 chapter08/vim.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make

# --- bloco 4 (userinput)
echo '>>> bloco 4'
chown -R tester .
sed '/test_plugin_glvs/d' -i src/testdir/Make_all.mak

# --- bloco 5 [teste]
echo '>>> bloco 5 (teste)'
if ! (
su tester -c "TERM=xterm-256color LANG=en_US.UTF-8 make -j1 test" \
   &> vim-test.log
); then echo '[AVISO-TESTE] bloco 5 terminou com falhas'; fi

# --- bloco 6 (userinput)
echo '>>> bloco 6'
make install

# --- bloco 7 (userinput)
echo '>>> bloco 7'
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done

# --- bloco 8 (userinput)
echo '>>> bloco 8'
ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.1629

# --- bloco 9 (userinput)
echo '>>> bloco 9'
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

# --- bloco 10 [omitido: vim -c ':options' abre o editor (apenas documentação)]
#   vim -c ':options'

