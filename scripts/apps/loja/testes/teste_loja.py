"""Testes da Loja sem GTK. Uso: python3 -m unittest discover -s testes   (a partir de loja/)
Os testes da API do Flathub só correm com LOJA_TESTE_REDE=1 (precisam de Internet)."""
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault("XDG_CACHE_HOME", tempfile.mkdtemp(prefix="loja-cache-"))

import loja_flathub as fh  # noqa: E402
import loja_flatpak as fp  # noqa: E402

# Saída real do flatpak 1.14 num pseudo-terminal (instalação do org.gtk.Gtk3theme.Adwaita-dark)
AMOSTRA = (b"Looking for matches\xe2\x80\xa6\r\n\r\n\x1b[1m        ID      Branch Op Remote  Download\x1b[22m\r\n"
           b"\x1b[?25l\x1b[6n\rInstalling\xe2\x80\xa6 \x1b[2m \x1b[22m                      0%  0 bytes/s\x1b[6n"
           b"\rInstalling\xe2\x80\xa6 \x1b[2m\xe2\x96\x88\xe2\x96\x88\x1b[22m 100%\x1b[6n\x1b[?25h\r\n").decode()


class Progresso(unittest.TestCase):
    def test_amostra_real(self):
        e = {"fracao": 0.0, "texto": ""}
        self.assertTrue(fp.interpretar(AMOSTRA, e))
        self.assertEqual(e["fracao"], 1.0)
        self.assertEqual(e["texto"], "A instalar… 100%")

    def test_varios_passos(self):
        e = {"fracao": 0.0, "texto": ""}
        fp.interpretar("\rInstalling 2/4… ████   50%  3.1 MB/s  00:10", e)
        self.assertAlmostEqual(e["fracao"], 1.5 / 4)
        self.assertEqual(e["texto"], "A instalar 2 de 4… 50%")
        fp.interpretar("\rUpdating 1/1… █ 7%", e)
        self.assertEqual(e["texto"], "A atualizar… 7%")

    def test_erro(self):
        e = {"fracao": 0.0, "texto": ""}
        fp.interpretar("error: No remote refs found for ‘org.x.Y’\r\n", e)
        self.assertIn("No remote refs", e["erro"])


class Descricao(unittest.TestCase):
    def test_html(self):
        t = fh._texto_descricao("<p>Um &amp; dois</p><ul><li>A <em>b</em></li><li>c</li></ul><p>x < y</p>")
        self.assertIn("Um &amp; dois", t)
        self.assertIn("•  A <i>b</i>", t)
        self.assertIn("x &lt; y", t)

    def test_tamanho(self):
        self.assertEqual(fh.tamanho_legivel(57883271), "57,9 MB")
        self.assertEqual(fh.tamanho_legivel(0), "—")


class _CacheNova:
    """Cada teste começa com uma cache que ainda não existe (como numa sessão live acabada de arrancar)."""
    def setUp(self):
        self._base = tempfile.mkdtemp(prefix="loja-home-")
        self._antes = (fh.CACHE, fh._pedido, fh.API)
        fh.CACHE = os.path.join(self._base, ".cache", "loja")      # nem ~/.cache existe

    def tearDown(self):
        fh.CACHE, fh._pedido, fh.API = self._antes
        import shutil
        shutil.rmtree(self._base, ignore_errors=True)


class CacheSemRede(_CacheNova, unittest.TestCase):
    """Sem Internet: o erro mostrado tem de ser o do pedido, nunca o da cache que falta (bug do PC real:
    "[Errno 2] ... ~/.cache/loja/api/<sha1>.json")."""
    def _falha(self, exc):
        def pedido(url, dados=None):
            raise exc
        fh._pedido = pedido

    def test_sem_rede_sem_cache_da_erro_de_rede(self):
        self._falha(fh.ErroRede("sem ligação ao Flathub: Network is unreachable"))
        with self.assertRaises(fh.ErroRede) as c:
            fh.populares(5)
        self.assertNotIsInstance(c.exception, FileNotFoundError)
        self.assertIn("sem ligação", str(c.exception))

    def test_erro_servidor_nao_e_rede(self):
        self._falha(fh.ErroServidor("o Flathub respondeu com o erro HTTP 503"))
        with self.assertRaises(fh.ErroServidor):
            fh.pesquisar("vlc")
        self.assertFalse(issubclass(fh.ErroServidor, fh.ErroRede))

    def test_json_invalido(self):
        fh._pedido = lambda url, dados=None: b"<html>manutencao</html>"
        with self.assertRaises(fh.ErroServidor):
            fh.populares(5)

    def test_grava_cache_e_usa_a_antiga_sem_rede(self):
        fh._pedido = lambda url, dados=None: b'{"hits": [{"app_id": "a.b.C", "name": "C"}]}'
        self.assertEqual(fh.populares(5)[0]["id"], "a.b.C")
        api = os.path.join(fh.CACHE, "api")
        self.assertEqual([f for f in os.listdir(api) if not f.endswith(".json")], [])   # sem .tmp
        self._falha(fh.ErroRede("sem ligação"))
        for f in os.listdir(api):                                      # cache "expirada"
            os.utime(os.path.join(api, f), (0, 0))
        self.assertEqual(fh.populares(5)[0]["id"], "a.b.C")

    def test_cache_sem_escrita_nao_impede_os_dados(self):
        bloqueio = os.path.join(self._base, "ficheiro")
        open(bloqueio, "w").close()
        fh.CACHE = os.path.join(bloqueio, "loja")                     # makedirs falha (NotADirectory)
        fh._pedido = lambda url, dados=None: b'{"hits": [{"app_id": "a.b.C", "name": "C"}]}'
        self.assertEqual(fh.populares(5)[0]["id"], "a.b.C")
        fh._pedido = lambda url, dados=None: b"\x89PNG\r\n\x1a\nfalso"
        f = fh.imagem("https://dl.flathub.org/x/icone.png")
        self.assertTrue(f and os.path.isfile(f))                       # vai para /tmp
        os.unlink(f)

    def test_dns_inexistente(self):
        fh.API = "https://flathub.invalid/api/v2"                      # .invalid nunca resolve (RFC 6761)
        with self.assertRaises(fh.ErroRede) as c:
            fh.populares(5)
        self.assertIn("sem ligação", str(c.exception))


@unittest.skipUnless(os.environ.get("LOJA_TESTE_REDE") == "1", "sem LOJA_TESTE_REDE=1")
class ApiCacheVazia(_CacheNova, unittest.TestCase):
    """Com rede real e HOME/XDG_CACHE_HOME vazio (sem pastas): tudo tem de funcionar e criar a cache."""
    def test_tudo_a_partir_do_zero(self):
        self.assertFalse(os.path.exists(fh.CACHE))
        self.assertTrue(fh.populares(10))
        r = fh.pesquisar("gimp")
        self.assertTrue(any(a["id"] == "org.gimp.GIMP" for a in r))
        d = fh.detalhes("org.gimp.GIMP")
        f = fh.imagem(d["icone"])
        self.assertTrue(f.startswith(fh.CACHE) and os.path.getsize(f) > 500)
        c = fh.imagem(d["capturas"][0])
        self.assertTrue(c.startswith(fh.CACHE) and os.path.getsize(c) > 5000)
        self.assertTrue(os.listdir(os.path.join(fh.CACHE, "api")))
        restos = [n for p, _, fs in os.walk(fh.CACHE) for n in fs if n.startswith(".tmp-")]
        self.assertEqual(restos, [])

    def test_home_vazio_noutro_processo(self):
        """Como no PC real: HOME novo e vazio, sem XDG_CACHE_HOME — a cache vai para ~/.cache/loja."""
        import subprocess
        env = {k: v for k, v in os.environ.items() if k != "XDG_CACHE_HOME"}
        env["HOME"] = self._base
        dir_loja = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        r = subprocess.run([sys.executable, "-c", "import loja_flathub as fh; print(fh.CACHE); "
                            "print(fh.populares(5)[0]['id']); print(fh.detalhes('org.videolan.VLC')['nome'])"],
                           cwd=dir_loja, env=env, capture_output=True, text=True, timeout=120)
        self.assertEqual(r.returncode, 0, r.stderr)
        cache, _, nome = r.stdout.split("\n")[:3]
        self.assertEqual(cache, os.path.join(self._base, ".cache", "loja"))
        self.assertEqual(nome, "VLC")
        self.assertTrue(os.listdir(os.path.join(cache, "api")))


@unittest.skipUnless(os.environ.get("LOJA_TESTE_REDE") == "1", "sem LOJA_TESTE_REDE=1")
class ApiFlathub(unittest.TestCase):
    def test_pesquisa(self):
        r = fh.pesquisar("vlc")
        self.assertTrue(any(a["id"] == "org.videolan.VLC" for a in r), [a["id"] for a in r][:10])
        self.assertTrue(all(a["nome"] and a["id"] for a in r))

    def test_detalhes(self):
        d = fh.detalhes("org.videolan.VLC")
        self.assertEqual(d["nome"], "VLC")
        self.assertTrue(d["descricao"])
        self.assertTrue(d["icone"].startswith("https://"))
        self.assertTrue(d["capturas"])
        self.assertGreater(d["tamanho_instalado"], 10_000_000)

    def test_inexistente(self):
        self.assertIsNone(fh.detalhes("org.nao.Existe" + "Zz9"))

    def test_destaques(self):
        for i in fh.DESTAQUES:
            d = fh.detalhes(i)
            self.assertIsNotNone(d, i)
            self.assertTrue(d["nome"], i)

    def test_categorias(self):
        for nome, cat, sub, _ in fh.CATEGORIAS:
            r = fh.categoria(cat, sub, 6)
            self.assertGreaterEqual(len(r), 3, nome)

    def test_populares(self):
        self.assertGreaterEqual(len(fh.populares(10)), 5)

    def test_icone_em_cache(self):
        d = fh.detalhes("org.gimp.GIMP")
        f = fh.imagem(d["icone"])
        self.assertTrue(f and os.path.getsize(f) > 500)
        self.assertTrue(f.startswith(fh.CACHE))
        with open(f, "rb") as h:
            self.assertEqual(h.read(4), b"\x89PNG")


if __name__ == "__main__":
    unittest.main()
