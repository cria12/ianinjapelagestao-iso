# Guardar dados automaticamente — contrato entre o backend e o assistente

Pedido do utilizador (12/11/2026): "na primeira sessão ele pergunta onde, você escolhe, e depois fica
sempre tudo salvo: senha do Wi-Fi, apps, vídeos, fotos, tudo". Hoje só há persistência se existir um
ext4 com o rótulo IANINJA-DADOS, criado à mão com `sudo ia-criar-persistencia` — ninguém o faz, por isso
nada fica guardado.

## O que fica guardado
Tudo: a camada de escrita inteira do OverlayFS (upper) passa a viver no armazenamento escolhido.
Isso cobre /home (fotos, vídeos, documentos), /etc/NetworkManager/system-connections (senhas Wi-Fi),
/etc/passwd+shadow (a conta criada), flatpak em ~/.local e /var/lib/flatpak, /opt, modelos de IA, etc.

## Três tipos de destino (o backend decide quais estão disponíveis)
| tipo       | o que faz                                                                 | apaga dados? |
|------------|---------------------------------------------------------------------------|--------------|
| `pen`      | nova partição ext4 IANINJA-DADOS no espaço livre da própria pen, depois da imagem ISO | não (só espaço livre) |
| `ficheiro` | ficheiro `/ianinja/ianinja-dados.img` (ext4 lá dentro, rótulo IANINJA-DADOS) numa partição existente com espaço livre (NTFS, exFAT, ext4; vfat só até 4 GiB) — ex.: o disco do Windows | não |
| `particao` | formata uma partição inteira (ou disco vazio/outra pen) como ext4 IANINJA-DADOS | SIM — pede confirmação explícita |

## Comando do backend: `/usr/sbin/ianinja-persistencia` (root)
- `ianinja-persistencia estado --json` →
  `{"ativo": bool, "tipo": "pen|ficheiro|particao|null", "dispositivo": "...", "livre_mb": N, "total_mb": N}`
  (ativo = a raiz em execução já usa um destino persistente)
- `ianinja-persistencia listar --json` → lista de opções, ordenadas pela recomendada primeiro:
  `[{"id": "pen:/dev/sdb", "tipo": "pen", "titulo": "Esta pen USB (SanDisk 32 GB)", "detalhe": "27,8 GB livres", "max_mb": N, "sugerido_mb": N, "apaga": false, "recomendado": true}, ...]`
  Nunca lista o dispositivo da ISO em si, partições montadas em uso pela live, nem swap/zram.
- `ianinja-persistencia criar <id> [--tamanho-mb N]` → cria o destino e copia para lá a camada de
  escrita atual (o que já foi feito nesta sessão — incluindo a conta acabada de criar — não se perde).
  Escreve progresso em stdout, uma linha por evento: `PROGRESSO <0-100> <texto em pt-PT>`; no fim
  `OK <id>` (rc 0) ou `ERRO <texto>` (rc≠0). Para `particao` exige `--confirmo-apagar`.
  A partir do arranque seguinte o initramfs usa-o sozinho.
- O greeter (utilizador lightdm) chama-o via `sudo -n /usr/libexec/ianinja-assistente/aplicar persistencia-estado|persistencia-listar|persistencia-criar` (JSON no stdin para criar: `{"id": "...", "tamanho_mb": N, "confirmo_apagar": bool}`), acrescentados a `permitidos` e ao sudoers; o aplicar repassa o stdout linha a linha.

## Arranque (live-init.sh)
Procura, por esta ordem: ext4 rótulo IANINJA-DADOS (partição — como hoje); depois, em cada partição
NTFS/exFAT/vfat/ext4 legível, o ficheiro `/ianinja/ianinja-dados.img` (monta a partição, losetup do
ficheiro, monta o ext4 interior). `persistencia=nao`/`semdados` continua a desligar tudo.

## Assistente (1.º arranque)
Nova página "Onde guardar os seus dados?" logo a seguir à página de início e antes da conta, só se
`estado.ativo` for falso. Mostra as opções de `listar` (a recomendada pré-selecionada), um seletor de
tamanho quando aplicável, e "Não guardar (tudo se perde ao desligar)". `particao` mostra aviso
vermelho e caixa "Compreendo que tudo nesse disco é apagado". A criação real corre depois de criar a
conta (página "A preparar…" com barra de progresso das linhas PROGRESSO) e no fim pede para reiniciar
("Reiniciar agora" — os dados passam a ser guardados a partir daí). Se `estado.ativo` já for verdadeiro,
a página não aparece. Remove o aviso amarelo atual do `sudo ia-criar-persistencia` (fica obsoleto).
