# Gerado de BLFS 12.4 general/python3.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: opções do LFS sem --enable-optimizations; confirma que o configure encontrou o SQLite]
# Python 3.13.7 recompilado só para ganhar o módulo _sqlite3: o do LFS (Cap. 8) foi compilado
# antes do SQLite (F8d) e ficou sem ele ("_sqlite3... disabled"). Mesmas opções do LFS, mas sem
# --enable-optimizations (o PGO só serve ao interpretador, que não é substituído; poupa ~10 min).
./configure --prefix=/usr          \
            --enable-shared        \
            --with-system-expat    \
            --without-static-libpython &&
grep -q "^MODULE__SQLITE3_STATE=yes" Makefile &&
make

# --- bloco 2 [omitido: suite de testes (+2,8 SBU): o interpretador não é substituído]
#   make test TESTOPTS="--timeout 120"

# --- bloco 3 [substituído: instala só o módulo _sqlite3 em lib-dynload (o resto do Python do LFS fica)]
# Instala SÓ o módulo _sqlite3 (o interpretador, a biblioteca padrão e o pip do LFS ficam como
# estão). Mesma versão e mesmas opções: o sufixo ABI (EXT_SUFFIX) é o do python3 instalado.
suf=$(python3 -c "import sysconfig; print(sysconfig.get_config_var(\"EXT_SUFFIX\"))") &&
test -f Modules/_sqlite3$suf &&
install -v -m755 Modules/_sqlite3$suf /usr/lib/python3.13/lib-dynload/ &&
python3 -c "import sqlite3; print(\"sqlite3\", sqlite3.sqlite_version, \"OK\")"

# --- bloco 4 [omitido: documentação HTML (download adicional não descarregado) e PYTHONDOCS]
#   install -v -dm755 /usr/share/doc/python-3.13.7/html
#   
#   tar --strip-components=1  \
#       --no-same-owner       \
#       --no-same-permissions \
#       -C /usr/share/doc/python-3.13.7/html \
#       -xvf ../python-3.13.7-docs-html.tar.bz2

# --- bloco 5 [omitido: documentação HTML (download adicional não descarregado) e PYTHONDOCS]
#   ln -svfn python-3.13.7 /usr/share/doc/python-3

# --- bloco 6 [omitido: documentação HTML (download adicional não descarregado) e PYTHONDOCS]
#   export PYTHONDOCS=/usr/share/doc/python-3/html

