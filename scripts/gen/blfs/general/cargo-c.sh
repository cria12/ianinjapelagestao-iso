# Gerado de BLFS 12.4 general/cargo-c.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: Cargo.lock descarregado no chroot (com rede) e verificado com o MD5 indicado no texto do livro]
curl -fLO --retry 5 --retry-delay 10 --retry-all-errors https://github.com/lu-zero/cargo-c/releases/download/v0.10.15/Cargo.lock &&
echo "57fab87782a5f9ef46fcbddc44d425b1  Cargo.lock" | md5sum -c

# --- bloco 2 (userinput)
echo '>>> bloco 2'
[ ! -e /usr/include/libssh2.h ] || export LIBSSH2_SYS_USE_PKG_CONFIG=1    &&
[ ! -e /usr/include/sqlite3.h ] || export LIBSQLITE3_SYS_USE_PKG_CONFIG=1 &&

cargo build --release

# --- bloco 3 (root)
echo '>>> bloco 3'
install -vm755 target/release/cargo-{capi,cbuild,cinstall,ctest} /usr/bin/

# --- bloco 4 (userinput)
echo '>>> bloco 4'
unset LIB{SSH2,SQLITE3}_SYS_USE_PKG_CONFIG

