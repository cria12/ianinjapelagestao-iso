# scripts/apps/funcoes-02.sh — funções próprias do bloco 2 da F8e: projeto face-finder (deteção de
# rostos com OpenCV/YuNet) e fotografias de licença livre. Carregado por scripts/f08e-apps.sh.
# As funções correm sob corre_passo (sem errexit): cada comando termina em "|| return 1".
# Downloads no host para $LFS/sources, verificados por SHA-256 (função baixar da etapa).

FF_SRC=$P/scripts/apps/face-finder              # projeto (vai para ~/Projetos/face-finder)
FF_SIS=$P/scripts/apps/face-finder-sistema      # comando, atalho e ícone
FF_FOTOS_LISTA=$P/scripts/apps/fotos-02.txt     # ficheiro|URL|SHA-256 de cada fotografia

# Modelo YuNet (opencv_zoo, licença MIT: models/face_detection_yunet/LICENSE). URL fixada no commit
# que acrescentou a versão 2023mar (o ficheiro está em Git LFS; o GitHub redireciona para
# media.githubusercontent.com). SHA-256 calculado com sha256sum no ficheiro descarregado.
FF_MODELO=face_detection_yunet_2023mar.onnx
FF_MODELO_COMMIT=f12e12798e8314f7c074a6656816c048dcc95b7a
FF_MODELO_URL=https://github.com/opencv/opencv_zoo/raw/$FF_MODELO_COMMIT/models/face_detection_yunet/$FF_MODELO
FF_MODELO_SHA256=8f2383e4dd3cfbb4553ea8718107fc0423210dc964f9f4280604804ed2552fa4

# O Wikimedia responde 429 (Too Many Requests) a clientes com o User-Agent genérico do wget
# (política de User-Agent da Wikimedia); um nome descritivo resolve. Dá-se ao wget do baixar
# um wgetrc só com o user_agent e repete-se algumas vezes com pausas, por causa do limite de pedidos.
FF_WGETRC=$P/scripts/apps/face-finder-wgetrc.tmp

ff_baixar_fotos() {
  local f url sha n i
  printf 'user_agent = ianinjapelagestao-build/1.0 (https://www.linuxfromscratch.org/blfs/; projeto face-finder) Wget\n' > $FF_WGETRC || return 1
  mkdir -p $LFS/sources/face-finder-fotos || return 1
  n=0
  while IFS='|' read -r f url sha; do
    case $f in ''|'#'*) continue ;; esac
    n=$((n+1))
    for i in 1 2 3 4 5; do
      WGETRC=$FF_WGETRC baixar "$url" face-finder-fotos/$f $sha && break
      [ $i = 5 ] && { rm -f $FF_WGETRC; echo "não foi possível descarregar $f"; return 1; }
      echo "nova tentativa de $f daqui a $((15*i)) s"; sleep $((15*i))
    done
    sleep 1
  done < $FF_FOTOS_LISTA
  rm -f $FF_WGETRC
  [ $n -ge 8 ] || { echo "só $n fotografias em $FF_FOTOS_LISTA"; return 1; }
  echo "$n fotografias verificadas"
}

# facefinder_downloads — modelo YuNet + fotografias (no host, verificados por SHA-256)
facefinder_downloads() {
  baixar $FF_MODELO_URL $FF_MODELO $FF_MODELO_SHA256 || return 1
  ff_baixar_fotos || return 1
}

# facefinder_instalar — /usr/share/face-finder (programa, modelo, fotos), /usr/bin/face-finder e
# face-finder-gui, atalho .desktop e ícone; o projeto em /home/ninja/Projetos/face-finder (dono
# ninja) e em /etc/skel/Projetos/face-finder (para utilizadores novos).
facefinder_instalar() {
  local st=$LFS/sources/face-finder-projeto f d
  [ -d $LFS/home/ninja ] || { echo "falta /home/ninja"; return 1; }
  [ -s $LFS/sources/$FF_MODELO ] || { echo "falta o modelo (passo facefinder-downloads)"; return 1; }
  # projeto montado num diretório temporário: código + modelo + fotografias
  rm -rf $st
  cp -r $FF_SRC $st || return 1
  find $st -name __pycache__ -prune -exec rm -rf {} + || return 1
  install -v -m644 $LFS/sources/$FF_MODELO $st/modelos/$FF_MODELO || return 1
  install -v -d -m755 $st/fotos || return 1
  while IFS='|' read -r f _; do
    case $f in ''|'#'*) continue ;; esac
    install -m644 $LFS/sources/face-finder-fotos/$f $st/fotos/$f || return 1
  done < $FF_FOTOS_LISTA
  find $st -type d -exec chmod 755 {} + || return 1
  find $st -type f -exec chmod 644 {} + || return 1
  chmod 755 $st/face_finder.py $st/face_finder_gui.py || return 1

  # sistema: /usr/share/face-finder (o comando usa esta cópia; o projeto do utilizador é para estudar/alterar)
  rm -rf $LFS/usr/share/face-finder
  install -v -d -m755 $LFS/usr/share/face-finder || return 1
  cp -r $st/face_finder.py $st/face_finder_gui.py $st/fotos $st/CREDITOS.md $st/README.md \
    $LFS/usr/share/face-finder/ || return 1
  install -v -m644 $st/modelos/$FF_MODELO $LFS/usr/share/face-finder/$FF_MODELO || return 1
  install -v -m644 $st/modelos/LICENSE $LFS/usr/share/face-finder/LICENSE-modelo-YuNet || return 1
  install -v -m755 $FF_SIS/face-finder $FF_SIS/face-finder-gui $LFS/usr/bin/ || return 1
  install -v -D -m644 $FF_SIS/face-finder.desktop $LFS/usr/share/applications/face-finder.desktop || return 1
  install -v -D -m644 $FF_SIS/face-finder.svg $LFS/usr/share/icons/hicolor/scalable/apps/face-finder.svg || return 1

  # projeto para o ninja e para utilizadores novos
  for d in $LFS/home/ninja/Projetos $LFS/etc/skel/Projetos; do
    install -v -d -m755 $d || return 1
    rm -rf $d/face-finder
    cp -r $st $d/face-finder || return 1
  done
  rm -rf $st
  chown -R root:root $LFS/usr/share/face-finder $LFS/etc/skel/Projetos || return 1
  in_chroot "set -e
    chown -R ninja: /home/ninja/Projetos
    desktop-file-validate /usr/share/applications/face-finder.desktop
    update-desktop-database -q /usr/share/applications
    gtk-update-icon-cache -qtf /usr/share/icons/hicolor
    ls -l /usr/bin/face-finder /usr/bin/face-finder-gui /usr/share/face-finder
    ls -la /home/ninja/Projetos/face-finder /home/ninja/Projetos/face-finder/fotos" || return 1
}

# facefinder_verificar — OpenCV com Python 3, dnn e FaceDetectorYN; PyGObject/GTK para a interface;
# o face-finder corre numa fotografia e os testes do projeto passam (cada foto com ≥1 rosto).
facefinder_verificar() {
  in_chroot "set -e
    export PYTHONDONTWRITEBYTECODE=1
    python3 -c 'import cv2, numpy; print(\"OpenCV\", cv2.__version__, \"NumPy\", numpy.__version__); assert hasattr(cv2, \"FaceDetectorYN\") and hasattr(cv2, \"dnn\")'
    python3 -c 'import gi; gi.require_version(\"Gtk\", \"3.0\"); gi.require_version(\"GdkPixbuf\", \"2.0\"); from gi.repository import Gtk, GdkPixbuf; import cairo; print(\"PyGObject\", gi.__version__)'
    python3 -m py_compile /usr/share/face-finder/face_finder_gui.py
    rm -rf /usr/share/face-finder/__pycache__
    test -x /usr/bin/ristretto
    rm -rf /tmp/face-finder-teste
    face-finder /usr/share/face-finder/fotos/idosa-china.jpg -o /tmp/face-finder-teste
    python3 -c 'import json; d = json.load(open(\"/tmp/face-finder-teste/resultados.json\")); assert d[\"total_rostos\"] >= 1, d'
    test -s /tmp/face-finder-teste/relatorio.html
    test -s /tmp/face-finder-teste/idosa-china_rostos.jpg
    rm -rf /tmp/face-finder-teste
    cd /home/ninja/Projetos/face-finder
    python3 -m unittest discover -s tests -v
    face-finder --versao" || return 1
}
