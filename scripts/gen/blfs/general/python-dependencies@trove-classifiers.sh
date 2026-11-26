# Gerado de BLFS 12.4 general/python-dependencies@trove-classifiers.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i '/calver/s/^/#/;$iversion="2025.8.6.13"' setup.py

# --- bloco 2 (userinput)
echo '>>> bloco 2'
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- bloco 3 (root)
echo '>>> bloco 3'
pip3 install --no-index --find-links dist --no-user trove-classifiers

