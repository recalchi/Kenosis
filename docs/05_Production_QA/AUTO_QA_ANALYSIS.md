# Auto QA - Analise da Sala de Teste

Data: 2026-06-13

## Objetivo

Criar bots autonomos para deixar a sala de teste rodando, encontrar erros de
fluxo, colisao, interacao, morte/retentativa e Ressonancia antes do playtest
humano.

## Como Rodar

```powershell
.\tools\run_auto_qa.ps1 -Cycles 3
```

- `Cycles 3`: executa uma volta de cada perfil.
- `Cycles 12`: executa quatro voltas de cada perfil.
- `Cycles 0`: modo continuo, ate interrupcao manual.

Relatorios:

- `builds/qa/autobot/latest_report.json`
- `builds/qa/vertical_slice/vertical_slice_contract.log`
- `builds/qa/autobot/auto_qa_latest.log`
- `builds/qa/mapbot/latest_report.json`
- `builds/qa/storybot/latest_report.json`
- `builds/qa/visualbot/latest_report.json`

## Perfis de Bot

### 1. Critical Path

Percorre a sala como jogador:

- testa limite esquerdo;
- ativa checkpoint e fonte;
- pula;
- ativa receptor;
- atravessa a ponte de Ressonancia;
- le a cicatriz;
- usa cobertura;
- purifica o Patrulheiro;
- coleta fragmento no chao;
- investe pontos no selo;
- conclui a saida.

### 2. Failure Recovery

Forca tres danos, valida tela de falha e confirma:

- jogo pausado apos morte;
- botao de retentativa responde;
- vida volta para 3/3;
- player retorna ao checkpoint;
- simulacao retoma.

### 3. Interaction Stress

Valida casos ruins de input:

- Ressonancia sem alvo;
- Ressonancia valida no receptor;
- rejeicao durante cooldown;
- rejeicao em receptor ja ativado;
- feedback sem travamento.

## Resultado Atual

Ultima bateria longa:

```txt
Cycles: 12
Passed: 12
Failed: 0
Average: 8.76s
Issue frequency: none
```

Ultima bateria rapida pelo wrapper publico:

```txt
Cycles: 3
Passed: 3
Failed: 0
Average: 9.16s
```

Contrato do vertical slice:

```powershell
.\tools\run_vertical_slice_contract.ps1
```

Resultado atual:

```txt
KENOSIS_VERTICAL_SLICE_CONTRACT_OK
```

Cobertura do contrato:

- `balance.json` aplicado a Player, Ressonancia, selo e recompensas.
- HUD de objetivo e explicacao de memorias/pontos presente.
- Pelo menos quatro fragmentos e quatro cicatrizes na sala.
- Saida inicia bloqueada e desbloqueia apos purificar o Patrulheiro.
- Fonte e checkpoint pagam recompensas definidas por dados.

## Erros Encontrados e Corrigidos

### Ponte de Ressonancia

Sintoma: o bot travava em `x ~= 576` depois de ativar o receptor.

Causa: a ponte ficava com superficie fisica desalinhada do piso, funcionando
como uma parede baixa invisivel.

Correcao:

- ponte reposicionada para `GROUND_SURFACE_Y`;
- colisao alinhada ao topo visual;
- smoke test passou a validar que a ponte materializada nao cria parede.

### Cobertura de Furtividade

Sintoma: o bot agachava dentro da cobertura, mas continuava detectavel.

Causa: `StealthCover` nao detectava a camada fisica do Player.

Correcao:

- `StealthCover` agora usa `collision_layer = 0` e `collision_mask = 2`;
- smoke test valida a mascara correta.

### Ressonancia no Inimigo

Sintoma: o bot nunca conseguia selecionar o Patrulheiro com `F`.

Causa: a area de interacao do Player varria apenas `Area2D`; o Patrulheiro e
um `CharacterBody2D`.

Correcao:

- `InteractionArea` agora detecta a camada do inimigo;
- `PlayerController` busca `overlapping_bodies` alem de `overlapping_areas`;
- o Critical Path purifica o inimigo via input real.

### Runner Headless

Sintoma: Auto QA passava funcionalmente, mas gerava erro ao capturar screenshot
em modo headless.

Causa: `ViewportTexture` sem backing valido no renderizador dummy.

Correcao:

- snapshots sao pulados quando `DisplayServer` esta em `headless`;
- wrapper usa processo isolado com `--log-file`;
- logs com `ERROR`, `WARNING` ou `SCRIPT ERROR` quebram o comando.

## Analise Critica de Gameplay

### Pontos Fortes Atuais

- Caminho principal e concluivel de forma repetida.
- Falha nao causa softlock.
- Retentativa restaura controle, vida e checkpoint.
- Ressonancia possui feedback para sucesso, cooldown e alvo invalido.
- Pontos ja tem gasto minimo funcional via selo de memoria.
- Furtividade agora funciona pelo input real, nao so por chamada de teste.
- Campo de teste possui objetivo persistente de etapa no HUD.
- Balance do slice foi centralizado em `balance.json`.

### Lacunas Criticas Restantes

- O bot percorre a sala de forma funcional, mas nao avalia prazer, ritmo ou
leitura emocional.
- A sala ainda tem composicao visual muito linear para uma primeira impressao.
- Os marcos de interacao estao corretos, mas precisam de silhueta e contraste
mais claros para jogador novo.
- A Ressonancia tem utilidade real, porem ainda parece um interruptor binario:
falta variacao visual e efeito ambiental mais forte.
- Furtividade funciona, mas o jogo ainda comunica pouco o cone/alcance da
ameaca.
- O sistema de pontos tem gasto, mas ainda precisa de escolhas: risco, atalho,
recompensa ou melhoria temporaria.
- O tempo de 5 minutos ainda precisa ser validado por playtest humano, porque
  o bot percorre a sala em ritmo artificialmente rapido.

## Plano de Melhorias Criticas

### P0 - Antes de Expandir Conteudo

- Criar indicador visual discreto do alcance de cobertura/furtividade.
- Melhorar feedback da Ressonancia na ponte: pulso, som e materializacao mais
legiveis.
- Adicionar gate visual para o selo de memoria, deixando claro que pontos foram
gastos.
- Adicionar Auto QA para a sala de mapa e pelo menos uma sala narrativa.
- Criar captura visual nao-headless automatica opcional para comparar antes/depois.

### P1 - Ritmo e Legibilidade

- Reduzir texto incidental durante travessia automatica; interacoes de lore
devem exigir escolha mais clara.
- Separar melhor as camadas de fundo por contraste e valor, especialmente no
primeiro plano.
- Adicionar microobjetivos visuais entre checkpoint, receptor, cobertura e saida.
- Criar medicao de tempo por trecho para detectar pontos lentos.

### P2 - Experiencia

- Variar reacao do inimigo ao perder o jogador em cobertura.
- Adicionar audio ambiente real em loop, separado do jingle.
- Criar pontuacao com rank explicavel: bonus por risco, furtividade e coleta.
- Criar pequenas recompensas visuais por completar a sala sem dano.

## Gates Recomendados

Antes de considerar a sala de teste pronta para playtest externo:

- `.\tools\run_godot_smoke.ps1`
- `.\tools\run_vertical_slice_contract.ps1`
- `.\tools\run_auto_qa.ps1 -Cycles 12`
- `.\tools\run_map_auto_qa.ps1`
- `.\tools\run_story_auto_qa.ps1`
- `.\tools\run_visual_auto_qa.ps1`
- `.\tools\run_expansion_test.ps1`
- `.\tools\run_story_regions_test.ps1`

Aceite minimo:

- zero erros no log;
- zero ciclos falhos;
- critical path abaixo de 25s no bot;
- recovery abaixo de 5s;
- nenhum `stuck_event`;
- nenhum dano no critical path.

## Extensoes Criadas em 2026-06-15

### Map Auto QA

Comando:

```powershell
.\tools\run_map_auto_qa.ps1
```

Cobertura:

- overlay de mapa abre, pausa e fecha;
- cinco ancoras sao registradas;
- teleporte para Despertar, Queda, Forja, Abismo e Vazio;
- checkpoint sincroniza com a ancora;
- inimigos de expansao existem na sala;
- tolerancia vertical pequena permite assentamento fisico do Player no chao.

### Story Auto QA

Comando:

```powershell
.\tools\run_story_auto_qa.ps1
```

Cobertura:

- fecha dialogo inicial;
- confirma saida inicialmente bloqueada;
- observa lore;
- resolve puzzle por Ressonancia real;
- estabiliza inimigo regional;
- coleta fragmento;
- confirma desbloqueio da saida.

### Retificacoes Visuais

- Cobertura furtiva agora pulsa e muda de cor quando o Player entra.
- Ponte de Ressonancia materializa com pulso visual curto e mantem colisao
  alinhada ao topo.

### Visual Auto QA

Comando:

```powershell
.\tools\run_visual_auto_qa.ps1
```

Capturas geradas:

- `test_room_start.png`
- `test_room_resonance_cover.png`
- `map_overlay.png`
- `map_void_anchor.png`
- `story_dialogue.png`
- `story_gameplay.png`

O runner valida resolucao minima, proporcao 16:9 e diversidade de amostras de
cor para detectar tela preta, render vazio ou viewport errado. A primeira
execucao mostrou que o Windows pode renderizar em 1920x1080 mesmo com viewport
base 1280x720; o gate agora exige proporcao e minimo de resolucao em vez de
tamanho exato.

Observacao visual atual:

- Os botoes do mapa central ainda truncam nomes longos de regioes. Nao bloqueia
  o teste, mas deve entrar no proximo polimento de UI.
