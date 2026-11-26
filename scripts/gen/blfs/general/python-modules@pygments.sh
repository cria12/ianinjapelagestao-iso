# Gerado de BLFS 12.4 general/python-modules@pygments.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- bloco 2 (root)
echo '>>> bloco 2'
pip3 install --no-index --find-links dist --no-user Pygments

# --- bloco 3 [omitido: testes: pip install wcag-contrast-ratio precisa de rede (e o pytest só vem depois)]
#   python3 -m venv --system-site-packages testenv &&
#   testenv/bin/pip3 install wcag-contrast-ratio   &&
#   testenv/bin/python -m pytest

