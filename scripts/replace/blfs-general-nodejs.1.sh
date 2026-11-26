# Só OpenSSL, zlib e ICU do sistema; Brotli, c-ares, libuv e nghttp2 são as cópias internas do
# Node.js (as mesmas versões que ele testa), em vez de 4 páginas do BLFS só para ele.
# make -j8 em vez de -j12: alguns ficheiros do V8 precisam de >1 GB de RAM cada (11 GB no WSL).
./configure --prefix=/usr          \
            --shared-openssl       \
            --shared-zlib          \
            --with-intl=system-icu &&
make -j8
