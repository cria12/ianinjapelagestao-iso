# Gerado de LFS 12.4 chapter07/kernfs.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
mkdir -pv $LFS/{dev,proc,sys,run}

# --- bloco 2 (userinput)
echo '>>> bloco 2'
mount -v --bind /dev $LFS/dev

# --- bloco 3 (userinput)
echo '>>> bloco 3'
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

# --- bloco 4 (userinput)
echo '>>> bloco 4'
if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

