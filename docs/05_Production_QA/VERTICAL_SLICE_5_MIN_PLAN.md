# Vertical Slice de 5 Minutos

## Estado Atual

Status: **slice tecnico jogavel fechado para QA interno**.

O campo de testes agora cobre uma experiencia curta com começo, meio e fim:
entrada, checkpoint, puzzle de Ressonancia, lore ambiental, furtividade,
purificacao nao violenta, coleta opcional, gasto de memorias e conclusao com
save local.

Ainda nao e build publica: falta export Windows, playtest humano cronometrado e
polimento visual/sonoro fino.

## Objetivo

Transformar o campo de testes em uma experiencia curta que demonstre a
identidade de Kenosis: observar, interpretar, alterar o ambiente e sobreviver
sem combate direto.

## Ritmo Alvo

| Tempo | Batida | Sistema validado |
|---|---|---|
| 0:00-0:35 | Entrada, movimento, checkpoint e objetivo visivel | controle, camera, save, onboarding |
| 0:35-1:25 | Fonte, receptor e lago | Ressonancia, cooldown e transformacao ambiental |
| 1:25-2:05 | Cicatriz do Patrulheiro | dialogo typewriter e lore ambiental |
| 2:05-3:30 | Patrulha, cobertura e leitura do padrao | furtividade, visao e tensao |
| 3:30-4:20 | Aproximacao pelas costas e purificacao | interacao nao violenta |
| 4:20-5:00 | Segunda margem, fragmentos e selo opcional | pontuacao, gasto de memorias e risco/recompensa |
| 5:00+ | Saida, rank e save | conclusao e persistencia local |

## Fluxo Jogavel Atual

1. O Player preserva memoria no checkpoint.
2. Observa a Fonte de Exorigem.
3. Usa `F` no receptor para materializar a ponte e neutralizar o lago.
4. Le a cicatriz que explica a origem do Patrulheiro.
5. Observa a rota de patrulha antes de entrar na cobertura.
6. Mantem `Shift` ou `C` para ocultar a assinatura.
7. Sai da cobertura apos o inimigo passar.
8. Usa `F` pelas costas ou oculto para desfazer o no de corrupcao.
9. Coleta fragmentos de memoria na segunda margem.
10. Decide se gasta memorias no Selo para abrir a plataforma opcional.
11. Interage com a saida liberada e grava a conclusao local.

## Implementado Nesta Fechadura

- HUD de objetivo no topo direito com etapas do slice.
- Texto de funcao dos pontos/memorias no HUD principal.
- `balance.json` controla velocidade, pulo, vida, penalidade, cooldown,
  recompensas, custo do selo e dados do Patrulheiro.
- Fonte, checkpoint, lore, fragmentos, selo e inimigo usam dados de balance.
- Segunda margem recebeu mais uma cicatriz e mais um fragmento.
- Contrato automatizado do vertical slice em
  `game/tests/vertical_slice_contract.gd`.
- Wrapper de validacao em `tools/run_vertical_slice_contract.ps1`.

## Criterios de Aceite

- Uma primeira tentativa deve durar entre 4 e 7 minutos em playtest humano.
- O objetivo deve ser compreensivel sem abrir o tutorial.
- A falha nunca pode reiniciar automaticamente por tras do overlay.
- Nenhum salto obrigatorio pode depender de precisao extrema.
- O Patrulheiro deve comunicar patrulha, alerta e contato por imagem e som.
- O jogador deve entender que Ressonancia altera estados, nao causa dano.
- A saida deve permanecer bloqueada ate o desafio furtivo ser resolvido.
- Pontos/memorias devem ter pelo menos um gasto significativo.
- O save deve sobreviver ao fechamento e reabertura do jogo.

## Validacao Automatizada Atual

Comandos verdes em 2026-06-17:

```powershell
.\tools\run_vertical_slice_contract.ps1
.\tools\run_godot_smoke.ps1
.\tools\run_auto_qa.ps1 -Cycles 3
.\tools\run_story_auto_qa.ps1
.\tools\run_story_regions_test.ps1
```

Resultado do Auto QA rapido:

```txt
Cycles: 3
Passed: 3
Failed: 0
Average: 9.16s
Issue frequency: none
```

Observacao: o bot percorre o caminho critico rapidamente por automacao; o tempo
alvo de 5 minutos continua sendo criterio de playtest humano.

## Proxima Iteracao

- Rodar tres playtests humanos cronometrados.
- Melhorar indicador visual de campo de visao/assinatura do inimigo.
- Criar ambiencia continua e variacoes de passos.
- Exportar build Windows e repetir o checklist fora do editor.
- Capturar video curto do fluxo completo para avaliar leitura visual.
