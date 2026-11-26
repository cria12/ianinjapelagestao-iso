# Gerado de BLFS 12.4 general/graphite2.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i '/cmptest/d' tests/CMakeLists.txt

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sed -i '/cmake_policy(SET CMP0012 NEW)/d' CMakeLists.txt &&
sed -i 's/PythonInterp/Python3/' CMakeLists.txt          &&
find . -name CMakeLists.txt | xargs sed -i 's/VERSION 2.8.0 FATAL_ERROR/VERSION 4.0.0/'

# --- bloco 3 (userinput)
echo '>>> bloco 3'
sed -i '/Font.h/i #include <cstdint>' tests/featuremap/featuremaptest.cpp

# --- bloco 4 (userinput)
echo '>>> bloco 4'
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr .. &&
make

# --- bloco 5 [omitido: make docs precisa de asciidoc/Doxygen/dblatex (não instalados); o bloco 7 copia esses ficheiros]
#   make docs

# --- bloco 6 (root)
echo '>>> bloco 6'
make install

# --- bloco 7 [omitido: make docs precisa de asciidoc/Doxygen/dblatex (não instalados); o bloco 7 copia esses ficheiros]
#   install -v -d -m755 /usr/share/doc/graphite2-1.3.14 &&
#   
#   cp      -v -f    doc/{GTF,manual}.html \
#                       /usr/share/doc/graphite2-1.3.14 &&
#   cp      -v -f    doc/{GTF,manual}.pdf \
#                       /usr/share/doc/graphite2-1.3.14

