# Gerado de LFS 12.4 chapter08/texinfo.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed 's/! $output_file eq/$output_file ne/' -i tp/Texinfo/Convert/*.pm

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr

# --- bloco 3 (userinput)
echo '>>> bloco 3'
make

# --- bloco 4 [teste]
echo '>>> bloco 4 (teste)'
if ! (
make check
); then echo '[AVISO-TESTE] bloco 4 terminou com falhas'; fi

# --- bloco 5 (userinput)
echo '>>> bloco 5'
make install

# --- bloco 6 (userinput)
echo '>>> bloco 6'
make TEXMF=/usr/share/texmf install-tex

# --- bloco 7 (userinput)
echo '>>> bloco 7'
pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
popd

