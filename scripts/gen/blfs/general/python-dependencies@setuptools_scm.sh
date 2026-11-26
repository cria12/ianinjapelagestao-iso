# Gerado de BLFS 12.4 general/python-dependencies@setuptools_scm.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- bloco 2 (root)
echo '>>> bloco 2'
pip3 install --no-index --find-links dist --no-user setuptools_scm

# --- bloco 3 [omitido: testes: precisam do pytest (instalado depois) e de git/mercurial com rede]
#   TZ=UTC HOME= pytest

