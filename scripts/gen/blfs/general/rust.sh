# Gerado de BLFS 12.4 general/rust.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (root)
echo '>>> bloco 1'
mkdir -pv /opt/rustc-1.89.0      &&
ln -svfn rustc-1.89.0 /opt/rustc

# --- bloco 2 (userinput)
echo '>>> bloco 2'
cat << EOF > bootstrap.toml
# See bootstrap.toml.example for more possible options,
# and see src/bootstrap/defaults/bootstrap.dist.toml for a few options
# automatically set when building from a release tarball
# (unfortunately, we have to override many of them).

# Tell x.py the editors have reviewed the content of this file
# and updated it to follow the major changes of the building system,
# so x.py will not warn us to do such a review.
change-id = 142379

[llvm]
# When using system llvm prefer shared libraries
link-shared = true

# If building the shipped LLVM source, only enable the x86 target
# instead of all the targets supported by LLVM.
targets = "X86"

[build]
description = "for BLFS 12.4"

# Omit docs to save time and space (default is to build them).
docs = false

# Do not query new versions of dependencies online.
locked-deps = true

# Specify which extended tools (those from the default install).
tools = ["cargo", "clippy", "rustdoc", "rustfmt"]

[install]
prefix = "/opt/rustc-1.89.0"
docdir = "share/doc/rustc-1.89.0"

[rust]
channel = "stable"

# Enable the same optimizations as the official upstream build.
lto = "thin"
codegen-units = 1

# Don't build lld which does not belong to this package and seems not
# so useful for BLFS.  Even if it turns out to be really useful we'd build
# it as a part of the LLVM package instead.
lld = false

# Don't build llvm-bitcode-linker which is only useful for the NVPTX
# backend that we don't enable.
llvm-bitcode-linker = false

[target.x86_64-unknown-linux-gnu]
llvm-config = "/usr/bin/llvm-config"

[target.i686-unknown-linux-gnu]
llvm-config = "/usr/bin/llvm-config"
EOF

# --- bloco 3 (userinput)
echo '>>> bloco 3'
[ ! -e /usr/include/libssh2.h ] || export LIBSSH2_SYS_USE_PKG_CONFIG=1
[ ! -e /usr/include/sqlite3.h ] || export LIBSQLITE3_SYS_USE_PKG_CONFIG=1
./x.py build

# --- bloco 4 [omitido: test suite muito longa (+15 SBU, +7,4 GB) e com falhas conhecidas; precisa de git do repositório Rust para parte dos testes]
#   ./x.py test --verbose --no-fail-fast | tee rustc-testlog

# --- bloco 5 [omitido: test suite muito longa (+15 SBU, +7,4 GB) e com falhas conhecidas; precisa de git do repositório Rust para parte dos testes]
#   grep '^test result:' rustc-testlog |
#    awk '{sum1 += $4; sum2 += $6} END { print sum1 " passed; " sum2 " failed" }'

# --- bloco 6 (root)
echo '>>> bloco 6'
./x.py install

# --- bloco 7 (root)
echo '>>> bloco 7'
rm -fv /opt/rustc-1.89.0/share/doc/rustc-1.89.0/*.old   &&
install -vm644 README.md                                \
               /opt/rustc-1.89.0/share/doc/rustc-1.89.0 &&

install -vdm755 /usr/share/zsh/site-functions      &&
ln -sfv /opt/rustc/share/zsh/site-functions/_cargo \
        /usr/share/zsh/site-functions

mv -v /etc/bash_completion.d/cargo /usr/share/bash-completion/completions

# --- bloco 8 (userinput)
echo '>>> bloco 8'
unset LIB{SSH2,SQLITE3}_SYS_USE_PKG_CONFIG

# --- bloco 9 (root)
echo '>>> bloco 9'
cat > /etc/profile.d/rustc.sh << "EOF"
# Begin /etc/profile.d/rustc.sh

pathprepend /opt/rustc/bin           PATH

# End /etc/profile.d/rustc.sh
EOF

# --- bloco 10 (userinput)
echo '>>> bloco 10'
source /etc/profile.d/rustc.sh

