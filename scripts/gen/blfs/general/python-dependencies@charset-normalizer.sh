# Gerado de BLFS 12.4 general/python-dependencies@charset-normalizer.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- bloco 2 (root)
echo '>>> bloco 2'
pip3 install --no-index --find-links dist --no-user charset-normalizer

# --- bloco 3 [omitido: testes: pip install pytest-cov precisa de rede]
#   python3 -m venv --system-site-packages testenv &&
#   source testenv/bin/activate                    &&
#   pip3 install pytest-cov                        &&
#   python3 /usr/bin/pytest
#   deactivate

