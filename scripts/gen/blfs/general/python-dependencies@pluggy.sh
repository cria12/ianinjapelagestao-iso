# Gerado de BLFS 12.4 general/python-dependencies@pluggy.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- bloco 2 (root)
echo '>>> bloco 2'
pip3 install --no-index --find-links dist --no-user pluggy

