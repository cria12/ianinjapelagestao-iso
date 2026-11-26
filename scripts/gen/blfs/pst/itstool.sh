# Gerado de BLFS 12.4 pst/itstool.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i 's/re.sub(/re.sub(r/'         itstool.in &&
sed -i 's/re.compile(/re.compile(r/' itstool.in

# --- bloco 2 (userinput)
echo '>>> bloco 2'
PYTHON=/usr/bin/python3 ./configure --prefix=/usr &&
make

# --- bloco 3 (root)
echo '>>> bloco 3'
make install

