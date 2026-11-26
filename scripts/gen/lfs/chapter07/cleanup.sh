# Gerado de LFS 12.4 chapter07/cleanup.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
rm -rf /usr/share/{info,man,doc}/*

# --- bloco 2 (userinput)
echo '>>> bloco 2'
find /usr/{lib,libexec} -name \*.la -delete

# --- bloco 3 (userinput)
echo '>>> bloco 3'
rm -rf /tools

# --- bloco 4 (userinput)
echo '>>> bloco 4'
exit

# --- bloco 5 (userinput)
echo '>>> bloco 5'
mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
umount $LFS/dev/pts
umount $LFS/{sys,proc,run,dev}

# --- bloco 6 (userinput)
echo '>>> bloco 6'
cd $LFS
tar -cJpf $HOME/lfs-temp-tools-12.4.tar.xz .

