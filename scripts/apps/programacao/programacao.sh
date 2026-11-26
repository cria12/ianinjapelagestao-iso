# Begin /etc/profile.d/programacao.sh
# ianinjapelagestao (F8e): ambiente de programação para os utilizadores normais.
#  - npm: "npm install -g" sem sudo — os pacotes globais vão para ~/.npm-global
#    (o root continua a usar /usr: sudo npm install -g instala para todos);
#  - ~/.local/bin (pip install --user, pipx, Claude Code), ~/.npm-global/bin, ~/.cargo/bin
#    (Rust do instalar-ferramentas) e ~/go/bin (go install) no PATH, mesmo que ainda não existam,
#    para funcionarem logo depois de instalar sem voltar a iniciar a sessão;
#  - JAVA_HOME, se o Java do instalar-ferramentas estiver instalado.
# Lido pelo /etc/profile (shells de login: consolas e a sessão gráfica, cujo lightdm-session
# corre bash --login; os terminais abertos nela herdam estas variáveis).

if [ $EUID -ne 0 ] && [ -n "$HOME" ] ; then
        export NPM_CONFIG_PREFIX=$HOME/.npm-global
        pathprepend $HOME/go/bin
        pathprepend $HOME/.cargo/bin
        pathprepend $HOME/.npm-global/bin
        pathprepend $HOME/.local/bin
fi

if [ -x /opt/jdk/bin/java ] ; then
        export JAVA_HOME=/opt/jdk
fi

# End /etc/profile.d/programacao.sh
