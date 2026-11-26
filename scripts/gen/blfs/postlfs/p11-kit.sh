# Gerado de BLFS 12.4 postlfs/p11-kit.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
sed '20,$ d' -i trust/trust-extract-compat &&

cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF

# --- bloco 2 (userinput)
echo '>>> bloco 2'
mkdir p11-build &&
cd    p11-build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D trust_paths=/etc/pki/anchors &&
ninja

# --- bloco 3 (root)
echo '>>> bloco 3'
ninja install &&
ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
        /usr/bin/update-ca-certificates

# --- bloco 4 (root)
echo '>>> bloco 4'
ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so

