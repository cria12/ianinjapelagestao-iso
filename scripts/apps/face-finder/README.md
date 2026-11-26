# Face Finder

Projeto de exemplo da distribuição ianinjapelagestao: um programa em Python que **encontra e marca
rostos** em fotografias com o OpenCV. Vem pronto a correr, com 12 fotografias de pessoas com licença
livre (ver [CREDITOS.md](CREDITOS.md)), testes e configuração para o VS Code.

> **Deteção ≠ reconhecimento.** O Face Finder diz *onde* há rostos numa imagem. Não diz *quem* são,
> não compara rostos entre fotografias e não guarda nenhuma "assinatura" facial.

## Como correr

Na linha de comandos (o comando `face-finder` está instalado no sistema):

```sh
cd ~/Projetos/face-finder
face-finder fotos -o saida            # analisa a pasta fotos/ e grava em saida/
face-finder fotos/idosa-china.jpg     # uma só imagem
face-finder fotos --limiar 0.6        # mais sensível (encontra mais rostos e mais enganos)
face-finder fotos -o saida --abrir    # no fim abre as imagens marcadas no Ristretto
python3 face_finder.py --help         # o mesmo, diretamente a partir do código do projeto
```

Em `saida/` ficam:

- `<nome>_rostos.jpg` — a imagem com uma caixa por rosto, os 5 pontos de referência
  (olho direito a azul, olho esquerdo a vermelho, nariz a verde, cantos da boca a magenta e amarelo)
  e a confiança (verde ≥ 0,90; amarelo ≥ 0,80; laranja abaixo). Rostos muito pequenos ficam sem
  etiqueta, para não taparem os vizinhos;
- `resultados.json` — tudo em formato de dados: caixas `[x, y, largura, altura]`, pontos e confiança;
- `relatorio.html` — miniaturas e contagens (abre-se com qualquer navegador).

Interface gráfica: menu **Face Finder** (ou `face-finder-gui`, ou `python3 face_finder_gui.py`).
Abre a pasta `fotos/`, mostra a lista de imagens com o número de rostos e a imagem marcada; permite
escolher outra imagem/pasta, mudar o limiar e gravar a imagem marcada.

Testes (verificam que em cada fotografia se encontra pelo menos um rosto, que as fotografias de grupo
têm vários, que uma imagem lisa não tem nenhum e que o JSON e o HTML são gerados):

```sh
python3 -m unittest discover -s tests -v
```

## No VS Code

Instale o VS Code com `instalar-aplicacoes` e, dentro dele, a extensão **Python** (Microsoft).
Abra a pasta `~/Projetos/face-finder` (Ficheiro → Abrir pasta). Em *Executar e depurar* (Ctrl+Shift+D)
há três configurações: analisar as fotos, abrir a interface gráfica e correr o ficheiro aberto.
Os testes aparecem no painel *Testes* (unittest).

## Como funciona

1. **Modelo**: YuNet (`modelos/face_detection_yunet_2023mar.onnx`, 230 KB, do
   [opencv_zoo](https://github.com/opencv/opencv_zoo/tree/main/models/face_detection_yunet),
   licença MIT, de Shiqi Yu e colaboradores). É uma rede neuronal convolucional pequena, treinada
   para devolver, para cada rosto, uma caixa, 5 pontos e uma pontuação. Uma cópia está também em
   `/usr/share/face-finder/`. Tudo funciona sem rede.
2. **OpenCV** (`cv2.FaceDetectorYN`, módulo `objdetect` sobre o módulo `dnn`) carrega o modelo e
   corre-o no processador. Imagens com mais de 1920 px são reduzidas para a deteção; as coordenadas
   voltam depois à escala original.
3. As deteções com pontuação abaixo do **limiar** (0,8 por omissão) são descartadas e caixas
   sobrepostas do mesmo rosto são fundidas (*non-maximum suppression*, `--nms`).
4. O programa desenha o resultado e escreve o JSON e o HTML.

O código está todo em `face_finder.py` (funções `carregar_detetor`, `detetar`, `desenhar`,
`processar`), fácil de reutilizar noutros programas:

```python
import face_finder as ff
detetor = ff.carregar_detetor(limiar=0.8)
rostos = ff.detetar(ff.ler_imagem("fotos/mulher-india.jpg"), detetor)
print(len(rostos), rostos[0]["caixa"], rostos[0]["confianca"])
```

## Limitações

- Rostos muito pequenos (menos de ~10 px), muito de lado, de costas, tapados (máscara, mão, cabelo)
  ou cortados pela margem da fotografia podem não ser encontrados. Um grande plano em que o rosto
  não cabe inteiro na imagem normalmente falha.
- Pode haver falsos positivos (padrões que parecem rostos: desenhos, estátuas, cartazes), sobretudo
  com limiares baixos.
- A qualidade varia com a iluminação, o tamanho e o tipo de fotografia; modelos deste tipo podem
  funcionar pior para alguns grupos de pessoas, conforme os dados com que foram treinados.
  Confirme sempre os resultados antes de tirar conclusões.

## Ética

- Use apenas imagens que tem o direito de usar e de pessoas que concordam com isso.
- Deteção de rostos serve, por exemplo, para contar pessoas, desfocar rostos antes de publicar
  uma foto, ou recortar retratos. Não a use para vigiar ou seguir pessoas.
- Reconhecimento facial (identificar pessoas) é um tratamento de dados biométricos, com regras
  muito apertadas no RGPD e no Regulamento Europeu da IA. Este projeto não o faz, de propósito.
- As fotografias incluídas têm licença livre e créditos em [CREDITOS.md](CREDITOS.md); as que
  são CC BY-SA obrigam a partilhar as imagens marcadas com a mesma licença e com atribuição.

## Ficheiros

```
face_finder.py        programa de linha de comandos (e biblioteca)
face_finder_gui.py    interface gráfica GTK 3
modelos/              modelo YuNet + LICENSE (MIT)
fotos/                12 fotografias de exemplo
tests/                testes (unittest)
.vscode/              configuração para correr/depurar no VS Code
CREDITOS.md           autor, licença e origem de cada fotografia
```
