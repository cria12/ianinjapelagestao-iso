# Gerado de BLFS 12.4 general/python-modules@numpy.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir -C setup-args=-Dallow-noblas=true $PWD

# --- bloco 2 (root)
echo '>>> bloco 2'
pip3 install --no-index --find-links dist --no-user numpy

# --- bloco 3 [omitido: testes: venv + pip install hypothesis (precisa de rede)]
#   mkdir -p test                                  &&
#   cd       test                                  &&
#   python3 -m venv --system-site-packages testenv &&
#   source testenv/bin/activate                    &&
#   pip3 install hypothesis                        &&
#   python3 -c "import numpy, sys; sys.exit(numpy.test() is False)"
#   deactivate

