# Gerado de BLFS 12.4 postlfs/efivar.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
make ENABLE_DOCS=0

# --- bloco 2 (root)
echo '>>> bloco 2'
make install ENABLE_DOCS=0 LIBDIR=/usr/lib

# --- bloco 3 (root)
echo '>>> bloco 3'
install -vm644 docs/efivar.1 /usr/share/man/man1 &&
install -vm644 docs/*.3      /usr/share/man/man3

