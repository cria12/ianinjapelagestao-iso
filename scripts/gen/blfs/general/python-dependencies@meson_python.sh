# Gerado de BLFS 12.4 general/python-dependencies@meson_python.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- bloco 2 (root)
echo '>>> bloco 2'
pip3 install --no-index --find-links dist --no-user meson_python

# --- bloco 3 [omitido: testes: criam um venv e descarregam meson_python[test] com pip (o chroot não tem rede)]
#   python3 -m venv --system-site-packages testenv &&
#   testenv/bin/pip3 install 'meson_python[test]'  &&
#   HOME= testenv/bin/python -m pytest

