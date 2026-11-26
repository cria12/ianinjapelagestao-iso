# Gerado de BLFS 12.4 general/python-dependencies@urllib3.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- bloco 2 (root)
echo '>>> bloco 2'
pip3 install --no-index --find-links dist --no-user urllib3

# --- bloco 3 [omitido: testes: pip install de 11 módulos precisa de rede]
#   python3 -m venv --system-site-packages testenv &&
#   source testenv/bin/activate                    &&
#   pip3 install trustme         \
#                tornado         \
#                python-dateutil \
#                mock            \
#                pysocks         \
#                pytest-timeout  \
#                trio            \
#                hypercorn       \
#                quart           \
#                quart_trio      \
#                httpx           &&
#   python3 /usr/bin/pytest
#   deactivate

