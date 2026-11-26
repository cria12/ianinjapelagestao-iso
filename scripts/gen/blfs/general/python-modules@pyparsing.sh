# Gerado de BLFS 12.4 general/python-modules@pyparsing.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- bloco 2 (root)
echo '>>> bloco 2'
pip3 install --no-index --find-links dist --no-user pyparsing

# --- bloco 3 [omitido: testes: venv + pip install railroad-diagrams matplotlib (precisa de rede)]
#   python3 -m venv --system-site-packages testenv &&
#   source testenv/bin/activate                    &&
#   pip3 install railroad-diagrams matplotlib      &&
#   python3 /usr/bin/pytest
#   deactivate

