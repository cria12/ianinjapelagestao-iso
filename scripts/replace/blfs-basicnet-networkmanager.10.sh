# ianinjapelagestao: <username> = ninja. À regra do livro (grupo netdev) junta-se a sessão local
# ativa (elogind): quem está sentado ao computador gere as redes sem senha, como nas distribuições
# generalistas — também utilizadores criados depois (ex.: assistente do 1.º arranque).
groupadd -fg 86 netdev &&
/usr/sbin/usermod -a -G netdev ninja
cat > /usr/share/polkit-1/rules.d/org.freedesktop.NetworkManager.rules << "EOF2"
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0 &&
        (subject.isInGroup("netdev") || (subject.local && subject.active))) {
        return polkit.Result.YES;
    }
});
EOF2
