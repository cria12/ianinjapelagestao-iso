# Instala SÓ o módulo _sqlite3 (o interpretador, a biblioteca padrão e o pip do LFS ficam como
# estão). Mesma versão e mesmas opções: o sufixo ABI (EXT_SUFFIX) é o do python3 instalado.
suf=$(python3 -c "import sysconfig; print(sysconfig.get_config_var(\"EXT_SUFFIX\"))") &&
test -f Modules/_sqlite3$suf &&
install -v -m755 Modules/_sqlite3$suf /usr/lib/python3.13/lib-dynload/ &&
python3 -c "import sqlite3; print(\"sqlite3\", sqlite3.sqlite_version, \"OK\")"
