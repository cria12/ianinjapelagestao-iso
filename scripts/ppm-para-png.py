#!/usr/bin/env python3
# Converte uma captura PPM (P6, como a do "screendump" do monitor do QEMU) em PNG,
# só com a biblioteca padrão do Python (o host não tem ImageMagick, netpbm nem PIL).
# Uso: ppm-para-png.py <entrada.ppm> <saida.png>
import struct
import sys
import zlib


def ler_ppm(caminho):
    with open(caminho, "rb") as f:
        dados = f.read()
    campos, pos = [], 0
    while len(campos) < 4:
        while pos < len(dados) and dados[pos:pos + 1].isspace():
            pos += 1
        if dados[pos:pos + 1] == b"#":           # comentário até ao fim da linha
            while pos < len(dados) and dados[pos:pos + 1] not in (b"\n", b"\r"):
                pos += 1
            continue
        ini = pos
        while pos < len(dados) and not dados[pos:pos + 1].isspace():
            pos += 1
        campos.append(dados[ini:pos])
    pos += 1                                       # um só espaço depois do maxval
    if campos[0] != b"P6":
        raise ValueError("não é um PPM binário (P6)")
    larg, alt, maxval = int(campos[1]), int(campos[2]), int(campos[3])
    if maxval != 255:
        raise ValueError("maxval %d não suportado (só 255)" % maxval)
    pix = dados[pos:pos + larg * alt * 3]
    if len(pix) != larg * alt * 3:
        raise ValueError("PPM truncado")
    return larg, alt, pix


def escrever_png(caminho, larg, alt, pix):
    def bloco(tipo, conteudo):
        return (struct.pack(">I", len(conteudo)) + tipo + conteudo
                + struct.pack(">I", zlib.crc32(tipo + conteudo) & 0xFFFFFFFF))
    linha = larg * 3
    cru = b"".join(b"\x00" + pix[y * linha:(y + 1) * linha] for y in range(alt))
    with open(caminho, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(bloco(b"IHDR", struct.pack(">IIBBBBB", larg, alt, 8, 2, 0, 0, 0)))
        f.write(bloco(b"IDAT", zlib.compress(cru, 9)))
        f.write(bloco(b"IEND", b""))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("uso: ppm-para-png.py <entrada.ppm> <saida.png>")
    l, a, p = ler_ppm(sys.argv[1])
    escrever_png(sys.argv[2], l, a, p)
    print("%s: %dx%d" % (sys.argv[2], l, a))
