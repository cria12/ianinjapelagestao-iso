# Gerado de LFS 12.4 chapter08/meson.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# --- bloco 2 (userinput)
echo '>>> bloco 2'
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

