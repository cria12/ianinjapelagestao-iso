# ianinjapelagestao: ">" em vez de ">>" (o passo pode ser repetido sem duplicar a secção [main])
install -v -d -m755 /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/NetworkManager.conf << "EOF2"
[main]
plugins=keyfile
EOF2
