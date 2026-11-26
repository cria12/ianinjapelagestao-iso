# Gerado de BLFS 12.4 general/git.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 (userinput)
echo '>>> bloco 1'
./configure --prefix=/usr \
            --with-gitconfig=/etc/gitconfig \
            --with-python=python3 &&
make

# --- bloco 2 [omitido: gerar/instalar man e html precisa de asciidoc/xmlto (não instalados)]
#   make html

# --- bloco 3 [omitido: gerar/instalar man e html precisa de asciidoc/xmlto (não instalados)]
#   make man

# --- bloco 4 (root)
echo '>>> bloco 4'
make perllibdir=/usr/lib/perl5/5.42/site_perl install

# --- bloco 5 [omitido: gerar/instalar man e html precisa de asciidoc/xmlto (não instalados)]
#   make install-man

# --- bloco 6 [omitido: gerar/instalar man e html precisa de asciidoc/xmlto (não instalados)]
#   make htmldir=/usr/share/doc/git-2.50.1 install-html

# --- bloco 7 [omitido: documentação pré-gerada (git-manpages/htmldocs) sem MD5 no livro; omitida para poupar espaço na ISO]
#   tar -xf ../git-manpages-2.50.1.tar.xz \
#       -C /usr/share/man --no-same-owner --no-overwrite-dir

# --- bloco 8 [omitido: documentação pré-gerada (git-manpages/htmldocs) sem MD5 no livro; omitida para poupar espaço na ISO]
#   mkdir -vp   /usr/share/doc/git-2.50.1 &&
#   tar   -xf   ../git-htmldocs-2.50.1.tar.xz \
#         -C    /usr/share/doc/git-2.50.1 --no-same-owner --no-overwrite-dir &&
#   
#   find        /usr/share/doc/git-2.50.1 -type d -exec chmod 755 {} \; &&
#   find        /usr/share/doc/git-2.50.1 -type f -exec chmod 644 {} \;

# --- bloco 9 [omitido: documentação pré-gerada (git-manpages/htmldocs) sem MD5 no livro; omitida para poupar espaço na ISO]
#   mkdir -vp /usr/share/doc/git-2.50.1/man-pages/{html,text}         &&
#   mv        /usr/share/doc/git-2.50.1/{git*.adoc,man-pages/text}     &&
#   mv        /usr/share/doc/git-2.50.1/{git*.,index.,man-pages/}html &&
#   
#   mkdir -vp /usr/share/doc/git-2.50.1/technical/{html,text}         &&
#   mv        /usr/share/doc/git-2.50.1/technical/{*.adoc,text}        &&
#   mv        /usr/share/doc/git-2.50.1/technical/{*.,}html           &&
#   
#   mkdir -vp /usr/share/doc/git-2.50.1/howto/{html,text}             &&
#   mv        /usr/share/doc/git-2.50.1/howto/{*.adoc,text}            &&
#   mv        /usr/share/doc/git-2.50.1/howto/{*.,}html               &&
#   
#   sed -i '/^<a href=/s|howto/|&html/|' /usr/share/doc/git-2.50.1/howto-index.html &&
#   sed -i '/^\* link:/s|howto/|&html/|' /usr/share/doc/git-2.50.1/howto-index.adoc

