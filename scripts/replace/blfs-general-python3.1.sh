# Python 3.13.7 recompilado só para ganhar o módulo _sqlite3: o do LFS (Cap. 8) foi compilado
# antes do SQLite (F8d) e ficou sem ele ("_sqlite3... disabled"). Mesmas opções do LFS, mas sem
# --enable-optimizations (o PGO só serve ao interpretador, que não é substituído; poupa ~10 min).
./configure --prefix=/usr          \
            --enable-shared        \
            --with-system-expat    \
            --without-static-libpython &&
grep -q "^MODULE__SQLITE3_STATE=yes" Makefile &&
make
