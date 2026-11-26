"""contas — lógica do Assistente de configuração do ianinjapelagestao (sem interface).

Validação (nome completo, nome de utilizador, senha e força da senha), estado do assistente
(ativo, configurado ou desligado) e aplicação da configuração como root: cria o utilizador a partir
do /etc/skel, define a senha, dá sudo (com senha, grupo wheel), autologin opcional no LightDM,
esconde e bloqueia o utilizador live (ninja), fuso horário, teclado e o marcador
/var/lib/ianinjapelagestao/configurado.

Tudo aceita uma raiz alternativa (raiz="/caminho") para testes fora do sistema: useradd/usermod/
userdel --root e chpasswd --root, ficheiros escritos debaixo dessa raiz. Nunca escreve a senha em
registos nem na linha de comandos (vai pelo stdin do chpasswd).

Uso pela linha de comandos (como root):
  python3 contas.py estado [--raiz DIR]         ativo | configurado ... | desligado ...
  python3 contas.py criar [--raiz DIR]          lê um JSON no stdin (ver aplicar())
  python3 contas.py experimentar                modo live neste arranque (sem criar conta)
  python3 contas.py repor [--raiz DIR]          volta a pedir a configuração (recuperação)
  python3 contas.py persistencia-estado | persistencia-listar | persistencia-criar (JSON no stdin)
                                                repasse ao backend /usr/sbin/ianinja-persistencia
                                                (scripts/apps/persistencia/CONTRATO.md)
"""
import datetime
import glob
import json
import os
import re
import subprocess
import sys
import unicodedata

MARCADOR = "var/lib/ianinjapelagestao/configurado"
RUN = "/run/ianinja-assistente"
EXPERIMENTAR = RUN + "/experimentar"
REGISTO = "var/log/ianinja-assistente.log"
AUTOLOGIN = "etc/lightdm/lightdm.conf.d/70-ianinja-autologin.conf"
USERS_CONF = "etc/lightdm/users.conf"
TECLADO_X = "etc/X11/xorg.conf.d/00-keyboard.conf"
CONSOLA = "etc/sysconfig/console"
UTILIZADOR_LIVE = "ninja"
SESSAO = "xfce"
SENHA_MINIMA = 8
PARAMETRO = "ianinja.assistente"
PERSISTENCIA = "/usr/sbin/ianinja-persistencia"

# nomes que não podem ser usados (contas de sistema, nomes confusos ou do live), além de qualquer
# utilizador ou grupo que já exista
RESERVADOS = {
    "root", "ninja", "lightdm", "daemon", "bin", "sys", "sync", "games", "man", "mail", "news",
    "uucp", "proxy", "nobody", "nogroup", "messagebus", "sshd", "polkitd", "uuidd", "flatpak",
    "lp", "lpadmin", "plugdev", "wheel", "users", "audio", "video", "input", "kvm", "render",
    "adm", "admin", "administrador", "sudo", "tty", "disk", "kmem", "floppy", "tape", "cdrom",
    "dialout", "utmp", "dbus", "systemd", "avahi", "colord", "pulse", "rtkit", "geoclue", "cups",
    "bluetooth", "netdev", "scanner", "storage", "optical", "operator", "staff", "guest",
    "convidado", "utilizador", "usuario", "user", "test", "teste", "x", "ia", "ianinja",
    "ianinjapelagestao", "live", "home", "www-data", "ftp", "postgres", "mysql",
}

# grupos suplementares do novo utilizador: os do ninja (menos o grupo próprio) + estes, se existirem.
# wheel dá o sudo COM senha (%wheel ALL=(ALL) ALL em /etc/sudoers.d/00-sudo).
GRUPOS_EXTRA = ["wheel", "audio", "video", "input", "plugdev", "lpadmin", "netdev", "users",
                "render", "kvm", "cdrom", "optical", "storage", "scanner", "bluetooth"]

# id -> (nome a mostrar, XkbLayout, KEYMAP da consola)
TECLADOS = {
    "pt": ("Português (Portugal)", "pt", "pt-latin1"),
    "br": ("Português (Brasil) — ABNT2", "br", "br-abnt2"),
    "us": ("Inglês (EUA)", "us", "us"),
}
TECLADO_OMISSAO = "pt"

FUSOS = [
    ("Europe/Lisbon", "Portugal — Lisboa (continente)"),
    ("Atlantic/Madeira", "Portugal — Madeira"),
    ("Atlantic/Azores", "Portugal — Açores"),
    ("America/Sao_Paulo", "Brasil — Brasília / São Paulo"),
    ("America/Fortaleza", "Brasil — Fortaleza / Nordeste"),
    ("America/Manaus", "Brasil — Manaus / Amazonas"),
    ("Africa/Luanda", "Angola — Luanda"),
    ("Africa/Maputo", "Moçambique — Maputo"),
    ("Atlantic/Cape_Verde", "Cabo Verde — Praia"),
    ("Europe/London", "Reino Unido — Londres"),
    ("Europe/Paris", "Europa Central — Paris / Madrid"),
    ("America/New_York", "EUA — Nova Iorque"),
    ("UTC", "UTC (tempo universal)"),
]
FUSO_OMISSAO = "Europe/Lisbon"

PADRAO_UTILIZADOR = re.compile(r"^[a-z_][a-z0-9_-]*$")

# palavras que tornam uma senha fraca mesmo sendo longa
COMUNS = ("123456", "password", "senha", "qwerty", "abc123", "111111", "000000", "ninja",
          "ianinja", "admin", "letmein", "iloveyou", "benfica", "sporting", "porto", "brasil",
          "portugal", "12345678", "987654")


class ErroAssistente(Exception):
    pass


# ------------------------------------------------------------------ leitura do sistema

def _caminho(raiz, rel):
    return os.path.join(raiz, rel.lstrip("/"))


def utilizadores(raiz="/"):
    """{nome: (uid, gid, gecos, home, shell)} de /etc/passwd."""
    r = {}
    try:
        with open(_caminho(raiz, "etc/passwd"), encoding="utf-8") as f:
            for linha in f:
                c = linha.rstrip("\n").split(":")
                if len(c) >= 7:
                    r[c[0]] = (int(c[2]) if c[2].isdigit() else -1, c[3], c[4], c[5], c[6])
    except OSError:
        pass
    return r


def grupos(raiz="/"):
    """{nome: [membros]} de /etc/group."""
    r = {}
    try:
        with open(_caminho(raiz, "etc/group"), encoding="utf-8") as f:
            for linha in f:
                c = linha.rstrip("\n").split(":")
                if len(c) >= 4:
                    r[c[0]] = [m for m in c[3].split(",") if m]
    except OSError:
        pass
    return r


def grupos_para_novo(raiz="/"):
    """Grupos suplementares: os do utilizador live (ninja) e os de GRUPOS_EXTRA que existam."""
    g = grupos(raiz)
    lista = [n for n, membros in g.items() if UTILIZADOR_LIVE in membros and n != UTILIZADOR_LIVE]
    for n in GRUPOS_EXTRA:
        if n in g and n not in lista:
            lista.append(n)
    return [n for n in lista if n not in ("root", "lightdm", "sudo-nopasswd")]


# ------------------------------------------------------------------ validação

def sem_acentos(s):
    return "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c))


def sugerir_utilizador(nome_completo):
    """'José da Silva' -> 'jose'. Vazio se não houver nada utilizável."""
    s = sem_acentos(nome_completo or "").lower().strip()
    s = re.sub(r"[^a-z0-9_ -]", "", s)
    partes = [p for p in s.split() if p]
    if not partes:
        return ""
    u = re.sub(r"[^a-z0-9_-]", "", partes[0])
    if u and not re.match(r"[a-z_]", u[0]):
        u = "u" + u
    return u[:32]


def validar_nome_completo(nome):
    nome = (nome or "").strip()
    if not nome:
        return "Escreva o seu nome."
    if len(nome) > 64:
        return "O nome é demasiado longo (máximo 64 caracteres)."
    if any(c in nome for c in ":,=\\\n\r\t") or any(ord(c) < 32 for c in nome):
        return "O nome não pode ter os caracteres  :  ,  =  \\"
    return None


def validar_utilizador(u, raiz="/"):
    """None se o nome de utilizador for válido e livre; senão a mensagem de erro (pt-PT)."""
    if not u:
        return "Escolha um nome de utilizador."
    if len(u) > 32:
        return "No máximo 32 caracteres."
    if u != u.lower():
        return "Use só letras minúsculas."
    if not PADRAO_UTILIZADOR.match(u):
        if not re.match(r"[a-z_]", u[0]):
            return "Tem de começar por uma letra minúscula (a-z) ou _."
        return "Só letras minúsculas sem acentos (a-z), algarismos, _ e -."
    if u in RESERVADOS:
        return f"«{u}» é um nome reservado do sistema; escolha outro."
    if u in utilizadores(raiz) or u in grupos(raiz):
        return f"Já existe «{u}» neste sistema; escolha outro."
    return None


def forca_senha(senha, utilizador=""):
    """(0..4, rótulo). 0 = muito fraca ... 4 = forte."""
    if not senha:
        return 0, ""
    classes = sum(bool(re.search(p, senha)) for p in (r"[a-z]", r"[A-Z]", r"[0-9]", r"[^A-Za-z0-9]"))
    n = len(senha)
    pontos = 0
    if n >= SENHA_MINIMA:
        pontos += 1
    if n >= 12:
        pontos += 1
    if n >= 16:
        pontos += 1
    pontos += max(0, classes - 1)
    baixa = senha.lower()
    if (utilizador and utilizador in baixa) or any(c in baixa for c in COMUNS):
        pontos -= 2
    if len(set(senha)) <= 3:
        pontos -= 2
    if n < SENHA_MINIMA:
        pontos = min(pontos, 0)
    nivel = max(0, min(4, pontos))
    return nivel, ("Muito fraca", "Fraca", "Razoável", "Boa", "Forte")[nivel]


def validar_senha(senha, confirmacao, utilizador=""):
    if not senha:
        return "Escolha uma senha."
    if len(senha) < SENHA_MINIMA:
        return f"A senha precisa de pelo menos {SENHA_MINIMA} caracteres."
    if len(senha) > 256:
        return "A senha é demasiado longa."
    if any(c in senha for c in "\n\r\0"):
        return "A senha não pode ter mudanças de linha."
    if utilizador and senha.lower() == utilizador.lower():
        return "A senha não pode ser igual ao nome de utilizador."
    if forca_senha(senha, utilizador)[0] == 0:
        return "Senha demasiado fácil de adivinhar; junte letras, algarismos ou símbolos."
    if senha != confirmacao:
        return "As duas senhas não coincidem."
    return None


def validar_dados(d, raiz="/"):
    """Valida o dicionário completo do assistente. Devolve a lista de erros (vazia = válido)."""
    erros = []
    for e in (validar_nome_completo(d.get("nome_completo")),
              validar_utilizador(d.get("utilizador", ""), raiz),
              validar_senha(d.get("senha", ""), d.get("senha", ""), d.get("utilizador", ""))):
        if e:
            erros.append(e)
    if d.get("teclado", TECLADO_OMISSAO) not in TECLADOS:
        erros.append("Teclado desconhecido.")
    if d.get("fuso", FUSO_OMISSAO) not in dict(FUSOS):
        erros.append("Fuso horário desconhecido.")
    return erros


# ------------------------------------------------------------------ estado

def _cmdline():
    try:
        with open("/proc/cmdline") as f:
            return f.read().split()
    except OSError:
        return []


def _smbios_desliga():
    """Cadeias OEM do SMBIOS (tipo 11) com ianinja.assistente=0 — o QEMU dá-as com
    -smbios type=11,value=ianinja.assistente=0 (testes automáticos, sem mexer no GRUB).
    /sys/firmware/dmi/entries/11-*/raw só se lê como root."""
    for f in glob.glob("/sys/firmware/dmi/entries/11-*/raw"):
        try:
            with open(f, "rb") as fh:
                if (PARAMETRO + "=0").encode() in fh.read():
                    return True
        except OSError:
            pass
    return False


def configurado(raiz="/"):
    return os.path.exists(_caminho(raiz, MARCADOR))


def estado(raiz="/"):
    """(estado, motivo): 'ativo', 'configurado' ou 'desligado'."""
    if configurado(raiz):
        return "configurado", _caminho(raiz, MARCADOR)
    if raiz == "/":
        cmd = _cmdline()
        if PARAMETRO + "=0" in cmd:
            return "desligado", PARAMETRO + "=0 na linha do kernel"
        if _smbios_desliga():
            return "desligado", PARAMETRO + "=0 nas cadeias OEM do SMBIOS"
        if os.path.exists(EXPERIMENTAR):
            return "desligado", "a experimentar o sistema live neste arranque"
    if UTILIZADOR_LIVE not in utilizadores(raiz):
        return "desligado", f"sem o utilizador {UTILIZADOR_LIVE}"
    return "ativo", ""


def com_persistencia():
    return os.path.ismount("/mnt/dados") or os.path.ismount("/run/live/dados")


def sessao_live():
    return os.path.ismount("/run/live/iso")


# ------------------------------------------------------------------ aplicação (root)

def registar(raiz, msg):
    try:
        f = _caminho(raiz, REGISTO)
        os.makedirs(os.path.dirname(f), exist_ok=True)
        with open(f, "a", encoding="utf-8") as fh:
            fh.write(f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} {msg}\n")
    except OSError:
        pass


def _correr(args, raiz, entrada=None):
    r = subprocess.run(args, input=entrada, capture_output=True, text=True, timeout=120)
    if r.returncode != 0:
        msg = (r.stderr or r.stdout).strip().splitlines()
        registar(raiz, f"ERRO: {args[0]} saiu com {r.returncode}: {' / '.join(msg[-3:])}")
        raise ErroAssistente(f"{os.path.basename(args[0])} falhou: {msg[-1] if msg else r.returncode}")
    return r


def _ferramenta(nome):
    for d in ("/usr/sbin", "/usr/bin", "/sbin", "/bin"):
        p = os.path.join(d, nome)
        if os.access(p, os.X_OK):
            return p
    return nome


def _opc_raiz(raiz):
    return [] if raiz == "/" else ["--root", os.path.abspath(raiz)]


def definir_senha(utilizador, senha, raiz="/"):
    args = [_ferramenta("chpasswd")] + _opc_raiz(raiz)
    if raiz != "/":
        # fora do sistema (testes): sem PAM dentro da raiz; hash SHA-512 feito pelo próprio chpasswd
        args += ["-c", "SHA512"]
    _correr(args, raiz, entrada=f"{utilizador}:{senha}\n")


def _escrever(raiz, rel, texto, modo=0o644):
    f = _caminho(raiz, rel)
    os.makedirs(os.path.dirname(f), exist_ok=True)
    tmp = f + ".novo"
    with open(tmp, "w", encoding="utf-8") as fh:
        fh.write(texto)
    os.chmod(tmp, modo)
    os.replace(tmp, f)


def _esconder_no_greeter(raiz, nome, esconder=True):
    """Acrescenta (ou tira) o nome em hidden-users= do /etc/lightdm/users.conf."""
    f = _caminho(raiz, USERS_CONF)
    try:
        with open(f, encoding="utf-8") as fh:
            linhas = fh.read().splitlines()
    except OSError:
        linhas = ["[UserList]", "minimum-uid=500", "hidden-users=nobody nobody4 noaccess",
                  "hidden-shells=/bin/false /usr/sbin/nologin /sbin/nologin"]
    feito = False
    for i, l in enumerate(linhas):
        if re.match(r"^\s*hidden-users\s*=", l):
            lista = l.split("=", 1)[1].split()
            if esconder and nome not in lista:
                lista.append(nome)
            if not esconder:
                lista = [x for x in lista if x != nome]
            linhas[i] = "hidden-users=" + " ".join(lista)
            feito = True
    if not feito and esconder:
        try:
            i = linhas.index("[UserList]") + 1
        except ValueError:
            linhas.append("[UserList]")
            i = len(linhas)
        linhas.insert(i, "hidden-users=nobody nobody4 noaccess " + nome)
    _escrever(raiz, USERS_CONF, "\n".join(linhas) + "\n")


def _teclado(raiz, tid):
    nome, xkb, keymap = TECLADOS[tid]
    _escrever(raiz, TECLADO_X,
              f"# ianinjapelagestao: teclado escolhido no Assistente de configuração ({nome})\n"
              "Section \"InputClass\"\n"
              "        Identifier \"system-keyboard\"\n"
              "        MatchIsKeyboard \"on\"\n"
              f"        Option \"XkbLayout\" \"{xkb}\"\n"
              "EndSection\n")
    f = _caminho(raiz, CONSOLA)
    if os.path.exists(f):
        with open(f, encoding="utf-8") as fh:
            t = fh.read()
        if re.search(r'(?m)^KEYMAP=', t):
            t = re.sub(r'(?m)^KEYMAP=.*$', f'KEYMAP="{keymap}"', t)
        else:
            t += f'KEYMAP="{keymap}"\n'
        _escrever(raiz, CONSOLA, t)


def _fuso(raiz, fuso):
    zona = "/usr/share/zoneinfo/" + fuso
    if os.path.isdir(_caminho(raiz, "usr/share/zoneinfo")) and not os.path.exists(_caminho(raiz, zona)):
        raise ErroAssistente(f"fuso horário {fuso} não existe em /usr/share/zoneinfo")
    lt = _caminho(raiz, "etc/localtime")
    tmp = lt + ".novo"
    if os.path.lexists(tmp):
        os.remove(tmp)
    os.symlink(zona, tmp)
    os.replace(tmp, lt)


def aplicar(d, raiz="/"):
    """Cria a conta e aplica a configuração. d = {nome_completo, utilizador, senha, autologin (bool),
    senha_root (bool: a mesma senha passa a ser a do root), teclado, fuso}.
    Devolve um resumo (str). Levanta ErroAssistente em caso de erro (sem deixar a conta a meio)."""
    if os.geteuid() != 0:
        raise ErroAssistente("é preciso ser root")
    if configurado(raiz):
        raise ErroAssistente("o sistema já está configurado (ianinja-assistente --repor para voltar a pedir)")
    d = dict(d)
    d["nome_completo"] = (d.get("nome_completo") or "").strip()
    d["utilizador"] = (d.get("utilizador") or "").strip()
    d.setdefault("teclado", TECLADO_OMISSAO)
    d.setdefault("fuso", FUSO_OMISSAO)
    erros = validar_dados(d, raiz)
    if erros:
        raise ErroAssistente(" ".join(erros))
    u = d["utilizador"]
    lista_grupos = grupos_para_novo(raiz)
    registar(raiz, f"a criar o utilizador {u} (grupos: {','.join(lista_grupos)}; "
                   f"autologin={'sim' if d.get('autologin') else 'não'}; "
                   f"senha do root={'mudada' if d.get('senha_root') else 'mantida'}; "
                   f"teclado={d['teclado']}; fuso={d['fuso']})")
    args = [_ferramenta("useradd")] + _opc_raiz(raiz) + [
        "-m", "-k", "/etc/skel", "-s", "/bin/bash", "-c", d["nome_completo"], "-U"]
    if lista_grupos:
        args += ["-G", ",".join(lista_grupos)]
    _correr(args + [u], raiz)
    try:
        definir_senha(u, d["senha"], raiz)
    except ErroAssistente:
        subprocess.run([_ferramenta("userdel")] + _opc_raiz(raiz) + ["-r", u], capture_output=True)
        registar(raiz, f"utilizador {u} apagado (a senha não foi definida)")
        raise
    # a partir daqui a conta existe e entra; o resto não a desfaz
    avisos = []
    if d.get("senha_root"):
        try:
            definir_senha("root", d["senha"], raiz)
        except ErroAssistente as e:
            avisos.append(f"senha do root não mudou ({e})")
    try:
        _teclado(raiz, d["teclado"])
    except (OSError, ErroAssistente) as e:
        avisos.append(f"teclado: {e}")
    try:
        _fuso(raiz, d["fuso"])
    except (OSError, ErroAssistente) as e:
        avisos.append(f"fuso horário: {e}")
    if d.get("autologin"):
        _escrever(raiz, AUTOLOGIN,
                  "# ianinjapelagestao: início de sessão automático escolhido no Assistente de configuração.\n"
                  "# Para o desligar apague este ficheiro (ou: sudo ianinja-assistente --sem-autologin).\n"
                  f"[Seat:*]\nautologin-user={u}\nautologin-user-timeout=0\nautologin-session={SESSAO}\n")
    elif os.path.exists(_caminho(raiz, AUTOLOGIN)):
        os.remove(_caminho(raiz, AUTOLOGIN))
    # o utilizador live deixa de aparecer no ecrã de entrada e deixa de aceitar a senha do live
    # (a conta e a pasta ficam; ianinja-assistente --repor desfaz)
    try:
        _esconder_no_greeter(raiz, UTILIZADOR_LIVE)
        if UTILIZADOR_LIVE in utilizadores(raiz):
            _correr([_ferramenta("usermod")] + _opc_raiz(raiz) + ["-L", UTILIZADOR_LIVE], raiz)
    except (OSError, ErroAssistente) as e:
        avisos.append(f"utilizador {UTILIZADOR_LIVE}: {e}")
    _escrever(raiz, MARCADOR,
              f"# ianinjapelagestao: sistema configurado pelo Assistente de configuração.\n"
              f"# Apagar (ou: sudo ianinja-assistente --repor) volta a mostrar o assistente.\n"
              f"utilizador={u}\ndata={datetime.datetime.now():%Y-%m-%d %H:%M:%S}\n"
              f"autologin={'sim' if d.get('autologin') else 'nao'}\n")
    for a in avisos:
        registar(raiz, "AVISO: " + a)
    registar(raiz, f"utilizador {u} criado; sistema marcado como configurado")
    return "OK" + ("" if not avisos else " (avisos: " + "; ".join(avisos) + ")")


def experimentar():
    """Modo live neste arranque: o greeter normal passa a aparecer (o /run apaga-se ao desligar)."""
    os.makedirs(RUN, exist_ok=True)
    with open(EXPERIMENTAR, "w") as f:
        f.write("1\n")
    registar("/", "a experimentar o sistema live (sem criar conta) neste arranque")


def repor(raiz="/"):
    """Recuperação: volta a mostrar o assistente e o utilizador live. Não apaga contas criadas."""
    for rel in (MARCADOR, AUTOLOGIN):
        f = _caminho(raiz, rel)
        if os.path.exists(f):
            os.remove(f)
    if raiz == "/" and os.path.exists(EXPERIMENTAR):
        os.remove(EXPERIMENTAR)
    _esconder_no_greeter(raiz, UTILIZADOR_LIVE, esconder=False)
    if UTILIZADOR_LIVE in utilizadores(raiz):
        _correr([_ferramenta("usermod")] + _opc_raiz(raiz) + ["-U", UTILIZADOR_LIVE], raiz)
    registar(raiz, "repor: marcador e autologin apagados, utilizador live desbloqueado")


def sem_autologin(raiz="/"):
    f = _caminho(raiz, AUTOLOGIN)
    if os.path.exists(f):
        os.remove(f)
    registar(raiz, "autologin desligado")


# ------------------------------------------------------------------ guardar os dados (backend à parte)

PADRAO_DESTINO = re.compile(r"^(pen|ficheiro|particao):/dev/[A-Za-z0-9/_+.-]+$")


def persistencia(acao, dados=None):
    """Repassa ao backend ianinja-persistencia (CONTRATO.md). estado/listar: imprime o JSON do
    backend; criar: o stdout do backend (PROGRESSO n texto / OK id / ERRO texto) sai linha a linha
    por este processo, para o greeter mostrar a barra de progresso. Devolve o código de saída.
    Só o root pode (é chamado pelo aplicar, via sudo)."""
    if os.geteuid() != 0:
        print("ERRO: é preciso ser root")
        return 1
    if not os.access(PERSISTENCIA, os.X_OK):
        print("ERRO: o programa ianinja-persistencia não está instalado")
        return 1
    if acao in ("estado", "listar"):
        r = subprocess.run([PERSISTENCIA, acao, "--json"], capture_output=True, text=True, timeout=300)
        out = (r.stdout or "").strip()
        if r.returncode != 0 or not out:
            m = out[4:].strip() if out.startswith("ERRO") else (out or (r.stderr or "").strip().splitlines()[-1:] or [""])[-1]
            print(f"ERRO: {m or 'o ianinja-persistencia não respondeu'}")
            return 1
        print(out.splitlines()[-1])
        return 0
    if acao == "criar":
        d = dados if isinstance(dados, dict) else {}
        oid = str(d.get("id") or "")
        if not PADRAO_DESTINO.match(oid):
            print("ERRO: destino inválido")
            return 1
        cmd = [PERSISTENCIA, "criar", oid]
        try:
            tam = int(d.get("tamanho_mb") or 0)
        except (TypeError, ValueError):
            print("ERRO: tamanho inválido")
            return 1
        if tam > 0:
            cmd += ["--tamanho-mb", str(tam)]
        if d.get("confirmo_apagar") is True:
            cmd.append("--confirmo-apagar")
        registar("/", f"guardar os dados: a criar {oid}" + (f" ({tam} MiB)" if tam else ""))
        sys.stdout.flush()
        r = subprocess.run(cmd, stdin=subprocess.DEVNULL)   # stdout e stderr herdados: linha a linha
        registar("/", f"guardar os dados: {oid} {'criado' if r.returncode == 0 else 'falhou (rc=%d)' % r.returncode}")
        if r.returncode == 0:
            try:
                os.makedirs(os.path.dirname(CRIADO), exist_ok=True)
                with open(CRIADO, "w") as f:
                    f.write(oid + "\n")
            except OSError:
                pass
        return r.returncode
    print(f"ERRO: ação desconhecida: persistencia-{acao}")
    return 2


CRIADO = "/run/ianinja-persistencia/criado"   # escrito quando persistencia-criar termina com OK


def reiniciar():
    """Reinicia o computador (botão "Reiniciar agora" do assistente) — só depois de, neste arranque,
    persistencia-criar ter terminado com OK (marcador em /run, que não sobrevive ao reinício).
    Existe porque sem logind/ConsoleKit o LightDM.restart() do greeter não tem quem o faça."""
    if os.geteuid() != 0:
        print("ERRO: é preciso ser root")
        return 1
    if not os.path.exists(CRIADO):
        print("ERRO: reiniciar só é permitido depois de os dados terem ficado guardados nesta sessão")
        return 1
    registar("/", "a reiniciar o computador a pedido do assistente (dados guardados)")
    print("OK", flush=True)
    subprocess.Popen([_ferramenta("shutdown"), "-r", "now"], stdin=subprocess.DEVNULL,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    return 0


# ------------------------------------------------------------------ linha de comandos

def main(argv=None, permitir_raiz=True, permitidos=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    raiz = "/"
    if "--raiz" in argv:
        i = argv.index("--raiz")
        if not permitir_raiz or i + 1 >= len(argv):
            print("ERRO: --raiz não permitido", file=sys.stderr)
            return 2
        raiz = argv[i + 1]
        del argv[i:i + 2]
    acao = argv[0] if argv else "estado"
    if permitidos is not None and acao not in permitidos:
        print(f"ERRO: ação não permitida: {acao}", file=sys.stderr)
        return 2
    try:
        if acao == "estado":
            e, motivo = estado(raiz)
            print(e + (f" ({motivo})" if motivo else ""))
            return 0
        if acao == "criar":
            dados = json.loads(sys.stdin.read() or "{}")
            print(aplicar(dados, raiz))
            return 0
        if acao == "experimentar":
            experimentar()
            print("OK")
            return 0
        if acao == "repor":
            repor(raiz)
            print("OK")
            return 0
        if acao == "sem-autologin":
            sem_autologin(raiz)
            print("OK")
            return 0
        if acao in ("persistencia-estado", "persistencia-listar"):
            return persistencia(acao.split("-", 1)[1])
        if acao == "persistencia-criar":
            return persistencia("criar", json.loads(sys.stdin.read() or "{}"))
        if acao == "reiniciar":
            return reiniciar()
    except (ErroAssistente, ValueError, OSError, subprocess.SubprocessError) as e:
        print(f"ERRO: {e}")
        return 1
    print(f"ERRO: ação desconhecida: {acao}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
