# Gerado de LFS 12.4 chapter08/setuptools.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# --- bloco 2 (userinput)
echo '>>> bloco 2'
pip3 install --no-index --find-links dist setuptools

