# Gerado de LFS 12.4 chapter08/shadow.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

# --- bloco 2 (userinput)
echo '>>> bloco 2'
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs

# --- bloco 3 (userinput)
echo '>>> bloco 3'
touch /usr/bin/passwd
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32

# --- bloco 4 (userinput)
echo '>>> bloco 4'
make

# --- bloco 5 (userinput)
echo '>>> bloco 5'
make exec_prefix=/usr install
make -C man install-man

# --- bloco 6 (userinput)
echo '>>> bloco 6'
pwconv

# --- bloco 7 (userinput)
echo '>>> bloco 7'
grpconv

# --- bloco 8 (userinput)
echo '>>> bloco 8'
mkdir -p /etc/default
useradd -D --gid 999

# --- bloco 9 (userinput)
echo '>>> bloco 9'
sed -i '/MAIL/s/yes/no/' /etc/default/useradd

# --- bloco 10 [substituído: passwd root é interativo -> chpasswd com a senha definida na Secção 3]
# senha definida em scripts/senhas.local (fora do Git), copiada por preparar_runner
. /sources/ianinja/senhas.local
printf 'root:%s\n' "$SENHA_ROOT" | chpasswd

