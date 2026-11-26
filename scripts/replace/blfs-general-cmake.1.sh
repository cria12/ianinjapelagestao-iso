echo '>>> bloco 1 (substituído: bibliotecas internas em vez das recomendadas não instaladas)'
# ianinjapelagestao: o livro usa --system-libs e recomenda cURL, libarchive, libuv e nghttp2.
# cURL (F8), zlib, bzip2, xz, zstd e expat existem no sistema; libarchive, libuv e nghttp2 não
# estão instalados, por isso usam-se as cópias incluídas no CMake (como o livro já faz para
# jsoncpp, cppdap e librhash). --parallel acelera só o bootstrap; o make usa MAKEFLAGS.
sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake &&

./bootstrap --prefix=/usr        \
            --system-libs        \
            --mandir=/share/man  \
            --no-system-jsoncpp  \
            --no-system-cppdap   \
            --no-system-librhash \
            --no-system-libarchive \
            --no-system-libuv    \
            --no-system-nghttp2  \
            --parallel=$(nproc)  \
            --docdir=/share/doc/cmake-4.1.0 &&
make
