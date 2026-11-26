# Gerado de BLFS 12.4 general/lua.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
cat > lua.pc << "EOF"
V=5.4
R=5.4.8

prefix=/usr
INSTALL_BIN=${prefix}/bin
INSTALL_INC=${prefix}/include
INSTALL_LIB=${prefix}/lib
INSTALL_MAN=${prefix}/share/man/man1
INSTALL_LMOD=${prefix}/share/lua/${V}
INSTALL_CMOD=${prefix}/lib/lua/${V}
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include

Name: Lua
Description: An Extensible Extension Language
Version: ${R}
Requires:
Libs: -L${libdir} -llua -lm -ldl
Cflags: -I${includedir}
EOF

# --- bloco 2 (userinput)
echo '>>> bloco 2'
patch -Np1 -i ../lua-5.4.8-shared_library-1.patch &&
make linux

# --- bloco 3 (root)
echo '>>> bloco 3'
make INSTALL_TOP=/usr                \
     INSTALL_DATA="cp -d"            \
     INSTALL_MAN=/usr/share/man/man1 \
     TO_LIB="liblua.so liblua.so.5.4 liblua.so.5.4.8" \
     install &&

mkdir -pv                      /usr/share/doc/lua-5.4.8 &&
cp -v doc/*.{html,css,gif,png} /usr/share/doc/lua-5.4.8 &&

install -v -m644 -D lua.pc /usr/lib/pkgconfig/lua.pc

