# opencv 4.12.0, bloco 2 (texto do livro) com estas diferenças — ver scripts/apps/decisoes-02.txt:
#  - sem xine-lib/FFmpeg/GStreamer (não instalados; o face-finder só lê ficheiros de imagem);
#  - WITH_IPP=OFF e sem o módulo G-API: o cmake descarregaria o ippicv e o ADE e o chroot não tem rede;
#  - bindings Python 3 obrigatórios (NumPy instalado antes) e documentação/exemplos/Java desligados;
#  - módulos dnn e objdetect (cv2.FaceDetectorYN) obrigatórios; sem opencv_contrib, CUDA ou Qt.
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr        \
      -D CMAKE_BUILD_TYPE=Release         \
      -D ENABLE_CXX11=ON                  \
      -D BUILD_PERF_TESTS=OFF             \
      -D WITH_XINE=OFF                    \
      -D WITH_FFMPEG=OFF                  \
      -D WITH_GSTREAMER=OFF               \
      -D WITH_IPP=OFF                     \
      -D BUILD_opencv_gapi=OFF            \
      -D WITH_ADE=OFF                     \
      -D WITH_CUDA=OFF                    \
      -D WITH_QT=OFF                      \
      -D WITH_GTK=ON                      \
      -D BUILD_opencv_python3=ON          \
      -D PYTHON3_EXECUTABLE=/usr/bin/python3 \
      -D BUILD_opencv_java=OFF            \
      -D BUILD_DOCS=OFF                   \
      -D BUILD_EXAMPLES=OFF               \
      -D BUILD_TESTS=OFF                  \
      -D ENABLE_PRECOMPILED_HEADERS=OFF   \
      -D CMAKE_SKIP_INSTALL_RPATH=ON      \
      -D BUILD_WITH_DEBUG_INFO=OFF        \
      -D OPENCV_GENERATE_PKGCONFIG=ON     \
      -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -W no-dev  ..                       &&
# o resumo do cmake tem de mostrar o Python 3 e os módulos dnn/objdetect; sem isto o face-finder não funciona
grep -Eq '^OPENCV_MODULES_BUILD:INTERNAL=.*opencv_python3' CMakeCache.txt &&
grep -Eq '^OPENCV_MODULES_BUILD:INTERNAL=.*opencv_dnn' CMakeCache.txt &&
grep -Eq '^OPENCV_MODULES_BUILD:INTERNAL=.*opencv_objdetect' CMakeCache.txt &&
make
