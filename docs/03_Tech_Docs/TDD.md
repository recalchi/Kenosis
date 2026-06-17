# TDD - Technical Design Document - Kenosis

## 1. Stack Técnica

- Engine: Godot 4.6
- Linguagem principal: GDScript
- IDE recomendada: VS Code
- Versionamento: Git/GitHub
- Plataforma da Sprint 0.1: PC-first
- Infraestrutura: offline

## 2. Estrutura Recomendada

```txt
Kenosis/
  game/
    project.godot
    scenes/
      characters/
      levels/
      ui/
      systems/
    scripts/
      characters/
      systems/
      ui/
      autoload/
    assets/
      art/
      audio/
      fonts/
      shaders/
    data/
      dialogue/
      items/
      levels/
    tests/
  docs/
  tools/
  builds/
  marketing/
```

## 3. Padrões Godot

- Usar cenas pequenas e modulares.
- Evitar scripts grandes e acoplados.
- Separar sistemas globais em Autoloads apenas quando necessário.
- Nomear nodes de forma clara.
- Manter recursos reutilizáveis em pastas específicas.
- Começar com protótipo simples antes de criar arquitetura definitiva.

## 4. Sistemas da Sprint 0.1

### Player Controller

Responsabilidades:

- Movimento horizontal.
- Pulo, se aprovado durante implementação.
- Gravidade.
- Colisão.
- Estado de morte/falha.

### Camera

Responsabilidades:

- Seguir o player.
- Evitar tremor.
- Manter enquadramento jogável em sala de teste.
- Usar viewport base de `1280x720` com stretch `canvas_items`.
- Aplicar limites da sala e zoom amplo para leitura antecipada de obstaculos.

### Parallax

Responsabilidades:

- Compor sky, mountains, architecture e midground em camadas independentes.
- Atualizar deslocamento horizontal de cada camada com fator proprio.
- Preservar escala proporcional dos assets.

### Game Settings

Responsabilidades:

- Persistir configuracoes em `user://settings.cfg`.
- Aplicar volume geral, musica, efeitos, tela cheia e VSync.
- Controlar exibicao de tutoriais e velocidade do texto animado.
- Disponivel como Autoload `GameSettings`.

### Interaction System

Responsabilidades:

- Detectar objetos interativos próximos.
- Exibir prompt simples.
- Disparar ação com tecla de interação.
- Concluir o campo de testes somente por interacao explicita na saida.

### Resonance System

Responsabilidades:

- Controlar cooldown de Ressonância.
- Validar se o alvo pode receber/ativar Ressonância.
- Emitir evento para objetos do puzzle.

### Failure/Regression System

Responsabilidades:

- Detectar morte/falha.
- Reposicionar player.
- Aplicar regressão simples de pontos.

## 5. Sistemas Futuros

- Dialogue/Lore System.
- Save System.
- Audio Manager.
- Input Manager para remapeamento e mobile.
- Build/export automation.

## 6. Convenções de Nome

```txt
Cena: PascalCase.tscn
Script: snake_case.gd
Node: PascalCase
Variável: snake_case
Constante: UPPER_SNAKE_CASE
```

## 7. Branches Recomendadas

```txt
main
develop
feature/player-controller
feature/resonance-system
feature/vertical-slice
bugfix/input
release/v0.1-demo
```

## 8. Build/Automação

A definir depois que a primeira cena jogável existir.

Prioridade inicial:

1. Rodar no editor.
2. Validar cena principal.
3. Exportar build Windows local.
4. Só depois avaliar automação.

## 9. Riscos Técnicos

| Risco | Impacto | Mitigação |
|---|---:|---|
| Mobile exigir UI diferente | Alto | PC-first na Sprint 0.1 e input mobile em fase posterior |
| Pixel art evoluir para HD-2D pesado | Médio/Alto | Testar orçamento visual antes do vertical slice final |
| Escopo narrativo crescer demais | Alto | Sala neutra de teste antes de cenas canônicas |
| Ressonância virar sistema complexo cedo demais | Alto | Começar com cooldown e poucos objetos |

## 10. Sistemas Implementados na Sprint 0.2

### Enemy / Stealth

- `CorruptedPatroller.tscn` concentra corpo, animador, visao e contato.
- Estados: reformacao, patrulha, alerta, perseguicao, atordoado e derrotado.
- A cobertura informa ao Player quando ele pode ocultar a assinatura.
- O Player fica furtivo com `Shift` ou `C` dentro da cobertura.
- Ressonancia no Patrulheiro exige aproximacao pelas costas ou assinatura oculta.
- Contato frontal dispara falha e regressao de pontos.
- Surgimento e retorno usam a sequencia de reformacao; visao e contato ficam
  suspensos ate o Patrulheiro recuperar a forma.

### Dialogue / Lore

- Cicatrizes sao cenas interativas reutilizaveis.
- O HUD apresenta dialogo em overlay e pausa a simulacao.
- `E` avanca e fecha a leitura.

### Save e Audio

- Autoload `SaveSystem`, persistindo em `user://kenosis_save.cfg`.
- Autoload `AudioManager`, com buses `Master`, `Music` e `SFX`.
- Cues iniciais para passos, UI, lore, alerta, falha, checkpoint e conclusao.

### Arquitetura da Sala

- A composicao geral continua em `test_room.gd` durante o prototipo.
- Inimigo, cobertura e cicatriz ja sao cenas modulares.
- A proxima extracao recomendada e mover checkpoint, puzzle e saida para cenas proprias.

### Animacao do Player

- O atlas atualizado foi dividido em 17 sequencias e 85 PNGs normalizados.
- Todas as sequencias usam canvas fixo e alinhamento pela base para evitar tremor.
- Estados: idle, walk, run, turn, jump start, rise, apex, fall, land, crouch,
  crouch stealth, interact, resonance, damage, death, respawn e silhouette.
- A direcao horizontal usa `flip_h`, mantendo collider e movimento independentes
  da arte para impedir caminhada visual de costas.
- Os quadros de salto, apex, queda e pouso usam caixas individuais e filtro de
  componente principal para impedir fragmentos de frames vizinhos.

### Integridade e Dano

- O Player possui 3 pontos de Integridade.
- Contato com o Patrulheiro remove 1 ponto, aplica recuo e invulnerabilidade curta.
- A falha e a regressao de pontos so acontecem quando a Integridade chega a zero.
- Checkpoints e respawn restauram toda a Integridade.
- O HUD mostra Integridade, estado agachado e visibilidade da assinatura.

## 11. Arquitetura da Sala de Expansao

### Cena

- `MapTestRoom.tscn` deriva da sala tecnica existente.
- `map_test_room.gd` adiciona ambiente, destinos, inimigos e navegacao sem
  duplicar o controlador base.
- `map_navigator.gd` controla GPS, overlay do mapa e teletransporte.

### Dados

O Autoload `DataRegistry` carrega e indexa:

- `lore_texts.json`
- `dialogue.json`
- `items.json`
- `levels.json`
- `input_config.json`
- `balance.json`
- `collectibles.json`

Os inimigos de expansao leem vida, dano, velocidades e recompensa diretamente
de `balance.json`. O mapa usa o catalogo de destinos e areas de `levels.json`.

### Inimigos

`expansion_enemy.gd` e o controlador compartilhado dos quatro novos
arquetipos. Cada cena configura collider, alcance, locomocao, sprites e VFX,
enquanto a maquina de estados comum cobre patrulha, perseguicao, ataque, dano,
morte e reformacao.

### Level Design

Os prefabs reutilizaveis ficam em `game/scenes/systems/`:

- SpawnMarker
- CheckpointMarker
- DeathZone
- TriggerArea
- CameraBounds
- TransitionZone
- InteractionArea
- PuzzleMarker

### Validacao

- Smoke geral: `tools/run_godot_smoke.ps1`.
- Expansao: `tools/run_expansion_test.ps1`.
- Novos assets devem passar pelo importador headless antes dos testes.

## 12. Story Locations

- As 16 cenas ficam em `game/scenes/levels/locations/`.
- Todas usam `story_location_room.gd`.
- Identidade, ordem, lore, fala, inimigo e tema vem de `levels.json`.
- `StoryTransition` executa fade, troca de cena e atualiza o save.
- `TransitionZoneMarker` suporta destino por ID, bloqueio e feedback.

### Persistencia v2

- Local atual.
- Locais desbloqueados.
- Cicatrizes observadas.
- Colecionaveis obtidos.
- Compatibilidade com checkpoint e pontuacao anteriores.

### Audio

O `AudioManager` usa 8 vozes de SFX, 4 de UI, 4 de passos e um player de
musica. Os streams sao pre-carregados e sons simultaneos nao se interrompem.

### Teste

`tools/run_story_regions_test.ps1` valida os 16 locais, dialogo, progressao,
save e audio simultaneo.

## 13. Fabrica de Level Design Narrativo

`story_location_room.gd` monta cada destino a partir de dois catalogos:

- `levels.json`: identidade, ordem, cena, lore, dialogo, inimigo e regiao.
- `location_layouts.json`: geometria, spawn, ritmo, puzzle e perigos.

Cada sala cria em runtime:

- `StoryLayout`, com assinatura unica de layout e desafio.
- Plataformas e perigos posicionados pelo perfil.
- `StoryPuzzleController`.
- Zero ou mais `StoryPuzzleNode`.
- Gate regional e transicoes de retorno/avanco.

`StoryPuzzleController` suporta os modos `all`, `sequence` e `none`. Os nodes
implementam `receive_resonance`, portanto usam o mesmo fluxo de cooldown e
selecao de alvo do sistema principal, sem input paralelo.

O desbloqueio da saida e calculado por estado, nao por ordem de eventos:

```txt
lore_observado AND ameaca_estabilizada AND puzzle_resolvido
```

O teste regional exige 16 assinaturas de layout e 16 IDs de desafio unicos,
valida a API do puzzle, a legibilidade dos dispositivos e o uso de sprites nos
perigos. Capturas comparativas ficam em `game/tests/artifacts/`.

## 14. Auto QA Bots

`auto_qa_bot.gd` executa perfis autonomos sobre `TestRoom.tscn` usando input
real sempre que possivel.

Perfis atuais:

- `critical_path`: percurso completo da sala.
- `failure_recovery`: morte, overlay e retry.
- `interaction_stress`: Ressonancia sem alvo, cooldown e alvo ja ativado.

`auto_qa_runner.gd` alterna os perfis por ciclo, grava relatorio JSON e emite
`KENOSIS_AUTO_QA_OK` quando a bateria termina.

Wrapper:

```powershell
.\tools\run_auto_qa.ps1 -Cycles 3
```

O wrapper executa Godot em processo isolado com `--log-file`, le
`builds/qa/autobot/latest_report.json` e falha se houver `ERROR`, `WARNING` ou
`SCRIPT ERROR`.

Runners adicionais:

```powershell
.\tools\run_map_auto_qa.ps1
.\tools\run_story_auto_qa.ps1
.\tools\run_visual_auto_qa.ps1
```

- `map_auto_qa_runner.gd` valida overlay, pausa, GPS, cinco ancoras e checkpoint
  apos teleporte.
- `story_auto_qa_runner.gd` valida o primeiro fluxo narrativo completo em
  `Awakening.tscn`.
- `visual_auto_qa_runner.gd` roda fora de headless, captura seis estados visuais
  e valida que as imagens sao 16:9, tem resolucao minima e nao estao vazias.
