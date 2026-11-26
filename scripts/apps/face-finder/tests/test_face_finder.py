"""Testes do Face Finder (unittest; também correm com pytest, se estiver instalado).

    python3 -m unittest discover -s tests -v      (a partir da pasta do projeto)
"""
import json
import os
import sys
import tempfile
import unittest

PROJETO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJETO)
import face_finder as ff  # noqa: E402

FOTOS = os.path.join(PROJETO, "fotos")


class TestFaceFinder(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.detetor = ff.carregar_detetor(None, 0.8)
        cls.fotos = ff.listar_imagens(FOTOS)

    def test_ha_fotos(self):
        self.assertGreaterEqual(len(self.fotos), 8, "a pasta fotos/ devia ter pelo menos 8 fotografias")

    def test_cada_foto_tem_rosto(self):
        for caminho in self.fotos:
            with self.subTest(foto=os.path.basename(caminho)):
                img = ff.ler_imagem(caminho)
                self.assertIsNotNone(img, "imagem ilegível")
                rostos = ff.detetar(img, self.detetor)
                self.assertGreaterEqual(len(rostos), 1, "nenhum rosto encontrado")
                for r in rostos:
                    x, y, w, h = r["caixa"]
                    self.assertTrue(0 <= x < img.shape[1] and 0 <= y < img.shape[0] and w > 0 and h > 0)
                    self.assertGreaterEqual(r["confianca"], 0.8)
                    self.assertEqual(set(r["pontos"]), set(ff.PONTOS))

    def test_fotos_de_grupo(self):
        for caminho in self.fotos:
            if os.path.basename(caminho).startswith("grupo-"):
                with self.subTest(foto=os.path.basename(caminho)):
                    self.assertGreaterEqual(len(ff.detetar(ff.ler_imagem(caminho), self.detetor)), 5)

    def test_imagem_sem_rostos(self):
        import numpy as np
        cinzento = np.full((480, 640, 3), 128, dtype=np.uint8)
        self.assertEqual(ff.detetar(cinzento, self.detetor), [])

    def test_resultados_e_relatorio(self):
        with tempfile.TemporaryDirectory() as saida:
            dados = ff.processar(FOTOS, saida, self.detetor, 0.8, mensagens=lambda *_: None)
            self.assertEqual(dados["total_imagens"], len(self.fotos))
            with open(os.path.join(saida, "resultados.json"), encoding="utf-8") as f:
                self.assertEqual(json.load(f)["total_rostos"], dados["total_rostos"])
            with open(os.path.join(saida, "relatorio.html"), encoding="utf-8") as f:
                self.assertIn("Face Finder", f.read())
            for r in dados["imagens"]:
                self.assertTrue(os.path.isfile(os.path.join(saida, r["saida"])))

    def test_cli(self):
        with tempfile.TemporaryDirectory() as saida:
            self.assertEqual(ff.main([self.fotos[0], "-o", saida]), 0)
            self.assertEqual(ff.main([os.path.join(saida, "nao-existe.jpg"), "-o", saida]), 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
