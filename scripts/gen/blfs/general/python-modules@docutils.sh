# Gerado de BLFS 12.4 general/python-modules@docutils.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (root)
echo '>>> bloco 1'
for f in /usr/bin/rst*.py; do
  rm -fv /usr/bin/$(basename $f .py)
done

# --- bloco 2 (userinput)
echo '>>> bloco 2'
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- bloco 3 (root)
echo '>>> bloco 3'
pip3 install --no-index --find-links dist --no-user docutils

