#!/bin/bash
# verificar-programacao.sh — corre DENTRO do chroot (passo prog-verificar da F8e), como root.
# Confirma que o Python (pip, venv, sqlite3, ssl), o Node.js/npm, o GDB e o Valgrind funcionam,
# e que um utilizador normal (UID 1000, ninja) instala pacotes npm globais sem sudo em
# ~/.npm-global e cria ambientes virtuais Python. Tudo sem rede (npm --offline, ensurepip).
set -euo pipefail
export LC_ALL=C.UTF-8

echo "== Python"
python3 -I - << 'EOF'
import sqlite3, ssl, venv, ensurepip, ctypes, bz2, lzma, readline, curses, uuid, zlib, hashlib
import requests, urllib3, idna, charset_normalizer, pytest, six
c = sqlite3.connect(":memory:")
c.execute("create table t (x)"); c.execute("insert into t values (42)")
assert c.execute("select x from t").fetchone() == (42,)
p = ssl.get_default_verify_paths()
import os
assert (p.cafile and os.path.exists(p.cafile)) or (p.capath and os.listdir(p.capath)), p
print("sqlite3", sqlite3.sqlite_version, "| openssl", ssl.OPENSSL_VERSION, "| CA:", p.cafile or p.capath)
print("requests", requests.__version__, "| pytest", pytest.__version__, "| ensurepip pip", ensurepip.version())
EOF
pip3 --version
python3 -m pip check || echo "AVISO: pip check encontrou dependências por resolver (ver acima)"
[ ! -e /usr/lib/python3.13/EXTERNALLY-MANAGED ] || echo "AVISO: o Python está marcado EXTERNALLY-MANAGED (pip install --user recusado)"

echo "== Node.js / npm"
node -e 'const v = process.versions;
  console.log("node", v.node, "| npm (ver abaixo) | openssl", v.openssl, "| icu", v.icu, "| uv", v.uv);
  if (new Intl.DateTimeFormat("pt-PT", {month: "long"}).format(new Date(2026, 0, 5)) !== "janeiro")
    throw new Error("ICU sem dados pt-PT");
  require("crypto").createHash("sha256").update("x").digest("hex");
  require("zlib").brotliCompressSync("x");'
npm --version
[ "$(npm config get prefix)" = /usr ] || { echo "o prefixo global do npm para o root devia ser /usr"; exit 1; }

echo "== GDB / Valgrind"
gdb --version | head -1
gdb -batch -ex 'python import sys; print("python do gdb:", sys.version.split()[0])'
valgrind --version
valgrind -q --error-exitcode=1 /usr/bin/true

echo "== utilizador normal (UID 1000): npm -g sem sudo, venv, pip"
d=$(mktemp -d /tmp/prog-teste.XXXXXX)
trap 'rm -rf "$d"' EXIT
mkdir -p "$d/casa" "$d/ola"
cat > "$d/ola/package.json" << 'EOF'
{ "name": "ola-ianinja", "version": "1.0.0", "bin": { "ola-ianinja": "ola.js" } }
EOF
printf '#!/usr/bin/env node\nconsole.log("ola do npm global");\n' > "$d/ola/ola.js"
chmod 755 "$d" "$d/ola/ola.js"
chown -R 1000:1000 "$d"
cat > "$d/teste.sh" << 'EOF'
. /etc/profile
set -euo pipefail
echo "PATH=$PATH"
[ "$NPM_CONFIG_PREFIX" = "$HOME/.npm-global" ]
[ "$(npm config get prefix)" = "$HOME/.npm-global" ]
case ":$PATH:" in *":$HOME/.npm-global/bin:"*) ;; *) echo "falta ~/.npm-global/bin no PATH"; exit 1 ;; esac
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "falta ~/.local/bin no PATH"; exit 1 ;; esac
npm install -g --offline --no-audit --no-fund "$1"
[ "$(ola-ianinja)" = "ola do npm global" ]
python3 -m venv "$HOME/venv"
"$HOME/venv/bin/pip" --version
"$HOME/venv/bin/python" -c 'import sqlite3, ssl; print("venv OK, sqlite3", sqlite3.sqlite_version)'
instalar-ferramentas -h > /dev/null
instalar-ferramentas -l
EOF
chroot --userspec=1000:1000 / /usr/bin/env -i HOME="$d/casa" USER=ninja LOGNAME=ninja TERM=dumb \
  PATH=/usr/bin:/usr/sbin /bin/bash --noprofile --norc "$d/teste.sh" "$d/ola"
echo "ambiente de programação: OK"
