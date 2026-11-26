# Gerado de BLFS 12.4 general/python-modules@requests.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
patch -Np1 -i ../requests-use_system_certs-1.patch

# --- bloco 2 (userinput)
echo '>>> bloco 2'
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD

# --- bloco 3 (root)
echo '>>> bloco 3'
pip3 install --no-index --find-links dist --no-user requests

# --- bloco 4 [omitido: testes: pip install (sphinx, flask, pytest-httpbin...) precisa de rede]
#   python3 -m venv --system-site-packages testenv &&
#   source testenv/bin/activate                    &&
#   pip3 install --force-reinstall sphinx\<5       &&
#   pip3 install pytest-mock    \
#                werkzeug\<2    \
#                flask\<2       \
#                pytest-httpbin \
#                pysocks        \
#                trustme                           &&
#   pip3 install --force-reinstall Markupsafe\<2.1 &&
#   python3 /usr/bin/pytest tests
#   deactivate

