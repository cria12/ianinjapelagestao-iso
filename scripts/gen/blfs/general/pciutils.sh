# Gerado de BLFS 12.4 general/pciutils.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -r '/INSTALL/{/PCI_IDS|update-pciids /d; s/update-pciids.8//}' \
    -i Makefile

# --- bloco 2 (userinput)
echo '>>> bloco 2'
make PREFIX=/usr                \
     SHAREDIR=/usr/share/hwdata \
     SHARED=yes

# --- bloco 3 (root)
echo '>>> bloco 3'
make PREFIX=/usr                \
     SHAREDIR=/usr/share/hwdata \
     SHARED=yes                 \
     install install-lib        &&

chmod -v 755 /usr/lib/libpci.so

