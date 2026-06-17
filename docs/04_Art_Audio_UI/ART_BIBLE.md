# Art Bible - Kenosis

## 1. Direcao Visual

Estetica inicial: pixel art 2D rustica, mistica e melancolica, com leitura
clara de gameplay. O projeto pode explorar profundidade e luz dramatica
futuramente, mas a Sprint 0.1 deve usar placeholders simples quando assets
finais ainda nao existirem.

## 2. Objetivo da Sprint 0.1

- Criar visual placeholder funcional.
- Garantir contraste entre personagem, chao, objetos interativos e perigo.
- Nao travar o prototipo em arte final.

## 3. Referencias Visuais

- Pixel art atmosferica.
- Ruinas antigas.
- Tecnologia mistica.
- Contraste entre energia pura luminosa e energia corrompida escura/estagnada.

## 4. Paleta Inicial

### Energia pura

- Tons sugeridos: azul claro, ciano suave, branco quente.
- Sensacao: fluxo, vida, memoria.

### Energia corrompida

- Tons sugeridos: roxo escuro, vermelho profundo, cinza frio.
- Sensacao: estagnacao, ameaca, ruptura.

### Sala neutra de teste

- Tons sugeridos: cinza pedra, verde musgo discreto, dourado gasto.
- Sensacao: laboratorio/ruina sem compromisso narrativo final.

## 5. Personagens

### Escriba do Fluxo

Estado atual:

- Sprite sheet principal importado em `game/assets/sprites/player/source/player_sheet.png`.
- Estados separados gerados em `game/assets/sprites/player/states/`.
- Estados disponiveis: idle, walk/run, jump, fall, land, interact, resonance,
  damage/hit, death, respawn, crouch/stealth e silhouette/shadow.
- A cena tecnica usa `AnimatedSprite2D` com estados visuais conectados ao
  movimento, pulo, queda, Ressonancia, falha e respawn.
- As animacoes ainda sao single-frame por estado; animacao quadro-a-quadro real
  fica para quando houver sprites sequenciais.

### Interactables da Sala Tecnica

Estado atual:

- Fonte de Exorigem, receptor de Ressonancia, gate, hazard e saida usam sprites
  placeholder proprios em `game/assets/sprites/interactables/`.
- Esses sprites sao gerados por `tools/generate_gameplay_placeholders.ps1`.
- O atlas inicial de cenario foi copiado para
  `game/assets/sprites/tilesets/source/scenario_atlas.png`.
- Os primeiros recortes de chao, parede, plataforma, ponte, props e blocos
  energeticos/corrompidos foram gerados por `tools/slice_scenario_assets.ps1`.
- A sala tecnica ja usa recortes do atlas para chao, paredes, plataforma, prop
  de fundo e ponte de Ressonancia.

## 6. Cenarios

| Local | Fase | Elementos visuais | Emocao |
|---|---|---|---|
| Sala neutra de teste | Sprint 0.1 | blocos, fonte, receptor, saida | validacao tecnica |
| Metropole ancestral | Futuro Ato I | torres, canais de energia, vitrais | grandeza/arrogancia |
| Pantano ritualistico | Futuro Ato II | lama, maquinas, residuos | colapso |
| Profundezas silenciosas | Futuro Ato III | cristais, vazio, ruina sagrada | kenosis/renascimento |

## 7. VFX

Prioridade inicial:

- Pulso de Ressonancia.
- Estado de cooldown.
- Ativacao de receptor.
- Feedback de falha.

## 8. Regras de Assets

- Registrar fonte/licenca de todo asset externo.
- Preferir placeholders proprios durante a Sprint 0.1.
- Nada de asset sem origem clara.

## 9. Padrao Canonico de Producao Visual

Atualizado para a sala de expansao:

- A direcao oficial continua sendo pixel art com leitura clara e canvas estavel.
- Atlas brutos ficam somente em pastas `source/`.
- Cenas devem carregar PNGs processados de `game/assets/`.
- O manifesto oficial de caminhos e pipeline e `game/assets/ASSET_MANIFEST.md`.
- Todo recorte de personagem deve manter alinhamento pela base entre quadros.
- Backgrounds devem ser compostos em cinco planos: sky, arquitetura distante,
  midground, foreground e atmosfera.
- Textura de gameplay nao pode conter rotulo, margem, fundo do atlas ou parte
  de um quadro vizinho.

### Inimigos de Expansao

- Abominacao Ancestral: massa, impacto e corrupcao organica.
- Energia Instavel: emissao, orbita e explosao.
- Sentinela Mistica: leitura arcana, busca e disparo.
- Sombra da Queda: silhueta, pressao e perda de memoria.

Cada inimigo possui sete estados animados e dois VFX conectados em runtime.

### Shaders Preferenciais

- Glow: energia pura.
- Distortion: corrupcao.
- Dissolve: morte e regressao.
- Outline: alvo interativo.
- Fog: atmosfera.
- Parallax material: profundidade.
- Pixel snap: estabilidade da pixel art.

Os shaders oficiais ficam em `game/shaders/` e seus materiais base em
`game/materials/`.
