# Gerado de BLFS 12.4 server/sqlite.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [omitido: documentação opcional (sqlite-doc-*.zip) não descarregada; também precisa de unzip (ausente)]
#   unzip -q ../sqlite-doc-3500400.zip

# --- bloco 2 (userinput)
echo '>>> bloco 2'
./configure --prefix=/usr     \
            --disable-static  \
            --enable-fts{4,5} \
            CPPFLAGS="-D SQLITE_ENABLE_COLUMN_METADATA=1 \
                      -D SQLITE_ENABLE_UNLOCK_NOTIFY=1   \
                      -D SQLITE_ENABLE_DBSTAT_VTAB=1     \
                      -D SQLITE_SECURE_DELETE=1"         &&
make

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

# --- bloco 4 [omitido: documentação opcional (sqlite-doc-*.zip) não descarregada; também precisa de unzip (ausente)]
#   install -v -m755 -d /usr/share/doc/sqlite-3.50.4 &&
#   cp -v -R sqlite-doc-3500400/* /usr/share/doc/sqlite-3.50.4

