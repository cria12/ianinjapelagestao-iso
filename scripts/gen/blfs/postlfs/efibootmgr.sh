# Gerado de BLFS 12.4 postlfs/efibootmgr.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
make EFIDIR=LFS EFI_LOADER=grubx64.efi

# --- bloco 2 (root)
echo '>>> bloco 2'
make install EFIDIR=LFS

