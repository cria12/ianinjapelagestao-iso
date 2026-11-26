# Gerado de BLFS 12.4 general/appstream.html — NÃO EDITAR (ver book-overrides.txt)
# --- bloco 1 [substituído: sem subdir docs/: as páginas de manual exigem docbook-xsl (não instalado) e o meson pararia]
sed -i "/^subdir(.docs\/.)/d" meson.build &&
mkdir build &&
cd    build &&
meson setup --prefix=/usr       \
            --buildtype=release \
            -D apidocs=false    \
            -D docs=false       \
            -D install-docs=false \
            -D stemming=false   .. &&
ninja

# --- bloco 2 [substituído: ninja install sem o mv de /usr/share/doc/appstream (sem documentação não existe)]
ninja install

# --- bloco 3 (root)
echo '>>> bloco 3'
install -vdm755 /usr/share/metainfo &&
cat > /usr/share/metainfo/org.linuxfromscratch.lfs.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="operating-system">
  <id>org.linuxfromscratch.lfs</id>
  <name>Linux From Scratch</name>
  <summary>A customized Linux system built entirely from source</summary>
  <description>
    <p>
      Linux From Scratch (LFS) is a project that provides you with
      step-by-step instructions for building your own customized Linux
      system entirely from source.
    </p>
  </description>
  <url type="homepage">https://www.linuxfromscratch.org/lfs/</url>
  <metadata_license>MIT</metadata_license>
  <developer id='linuxfromscratch.org'>
    <name>The Linux From Scratch Editors</name>
  </developer>

  <releases>
    <release version="12.4" type="release" date="2025-09-01">
      <description>
        <p>Now contains Binutils 2.45, GCC-15.2.0, Glibc-2.42,
        Linux kernel 6.16, and twelve security updates.</p>
      </description>
    </release>

    <release version="12.3" type="stable" date="2025-03-05">
      <description>
        <p>Now contains Binutils 2.44, GCC-14.2.0, Glibc-2.41, and
        Linux Kernel 6.13, and three security updates.</p>
      </description>
    </release>
  </releases>
</component>
EOF

