# QA Plan - Kenosis

## 1. Objetivo

Garantir que Kenosis seja estável, jogável, compreensível e consistente com a visão criativa.

## 2. Escopo de QA da Sprint 0.1

Validar apenas o protótipo técnico PC-first:

- Movimento.
- Câmera.
- Interação.
- Ressonância por cooldown.
- Puzzle simples.
- Morte/falha.
- Regressão de pontos.
- Ausência de softlock na sala neutra.

## 3. Checklist da Sprint 0.1

- [x] Projeto abre no Godot 4.6.
- [x] Cena de teste carrega sem erro.
- [ ] Player se movimenta corretamente.
- [ ] Câmera acompanha sem tremor.
- [ ] Colisões impedem atravessar chão/parede.
- [ ] Prompt de interação aparece no alcance correto.
- [ ] Ressonância ativa apenas quando disponível.
- [ ] Cooldown bloqueia uso repetido imediato.
- [ ] Objeto receptor responde à Ressonância.
- [ ] Puzzle pode ser concluído.
- [ ] Saída/caminho desbloqueia após puzzle.
- [ ] Falha/morte reinicia o jogador ou restaura checkpoint.
- [ ] Regressão de pontos é aplicada e visível.
- [ ] Não há softlock.
- [x] Smoke valida limites laterais sem lacuna antes das paredes.
- [x] Smoke valida colisao das plataformas contra a largura visual.
- [x] Smoke valida camera ampla e limites do campo de testes.
- [x] Smoke valida quatro camadas de parallax.
- [x] Smoke valida HUB, historia indisponivel, tutorial e configuracoes.
- [x] Smoke valida conclusao da area por interacao explicita.

## 4. Tipos de Teste

- Funcional.
- Regressão.
- Performance básica.
- UX.
- Build/export, quando existir build.

## 5. Fora de Escopo Por Enquanto

- Teste mobile.
- Save/load.
- Acessibilidade completa.
- Compatibilidade ampla de hardware.
- Automação de CI.

## 6. Validação Automatizada Local

Smoke test disponível:

```powershell
.\tools\run_godot_smoke.ps1
```

O teste abre o projeto em modo headless, carrega `res://scenes/levels/TestRoom.tscn`, instancia a sala e verifica a existência dos nós principais: Player, ResonanceSystem, PrototypeHUD, ResonanceReceiver e ResonanceGate.

Cobertura atual do smoke test:

- Carregamento e instanciação da sala técnica.
- Existência de Player, HUD, Ressonância, receptor, gate e zona de conclusão.
- Carregamento do MenuHub como cena de entrada.
- Existência dos botões Continuar, Tutorial opcional e Fechar.
- Tutorial opcional inicia fechado, abre e fecha por chamada de UI.
- Existência de overlay de pausa, botão Retomar e opções de menu/sair.
- Existência de overlay pós-falha, botão Tentar de novo e opções de menu/sair.
- Após falha, o player congela no ponto da falha e só volta ao checkpoint ao escolher Tentar de novo.
- Receptor de Ressonância posicionado antes da zona de falha.
- Raio de interação ampliado para reduzir fricção no protótipo.
- Regressão de pontos após falha.
- Retorno do player ao checkpoint após falha.
- Ativação real de Ressonância via `ResonanceSystem`.
- Início do cooldown após Ressonância.
- Abertura do gate após ativar o receptor.
- Conclusão da sala quando o player interage com a zona final.
- Carregamento do `AnimatedSprite2D` do player.
- Existência das animações principais: idle, walk/run, jump, fall, interact, resonance, damage/hit, death, respawn e crouch/stealth.
- Troca visual para walk/run, jump, death, respawn e resonance.
- Carregamento dos sprites de fonte, receptor, gate e hazard.
- Existencia das camadas Sky, Mountain, Architecture e Midground.
- Camera com zoom amplo e limites configurados.
- Piso continuo ate os limites laterais.
- Colisao das plataformas coerente com a largura renderizada.
- HUB com logo, campo de testes, historia indisponivel e painel de configuracoes.

## 7. Template de Bug

```md
# Bug

## Título

## Versão/Build

## Plataforma

## Passos para reproduzir
1.
2.
3.

## Resultado esperado

## Resultado atual

## Severidade
Baixa / Média / Alta / Crítica

## Evidência
Print/vídeo/log
```

## 8. QA da Sprint 0.2 - 2026-06-12

### Validacao automatizada: aprovado

- [x] Projeto importa e abre no Godot 4.6.3 sem erro de script.
- [x] Patrulheiro possui oito animacoes com pelo menos tres frames cada.
- [x] Visao altera o estado do inimigo para perseguicao.
- [x] Cobertura oculta e restaura a assinatura do Player.
- [x] Ressonancia valida purificacao furtiva e atordoa o Patrulheiro.
- [x] Purificacao libera a saida.
- [x] Dialogo pausa, avanca e devolve o controle.
- [x] Morte congela o jogo atras do overlay.
- [x] Retry retorna ao checkpoint e restaura a simulacao.
- [x] Checkpoint, AudioManager e SaveSystem existem na arvore.
- [x] Conclusao grava progresso local.
- [x] Buses Music e SFX sao carregados.
- [x] Smoke completo executado por `tools/run_godot_smoke.ps1`.

### Inspecao visual: aprovado com ressalvas

- [x] Sala renderizada em 1280x720.
- [x] HUD permanece legivel e sem sobreposicao.
- [x] Piso, parallax, plataformas e lago permanecem enquadrados.
- [x] Checkpoint e VFX foram recortados sem texto do guia.
- [x] Sprites principais do Patrulheiro foram isolados em quadros separados.
- [ ] Fazer playtest humano de 3 tentativas para calibrar distancia de visao.
- [ ] Medir tempo medio entre checkpoint, cobertura e purificacao.
- [ ] Confirmar em fones o volume relativo de alerta, passos e falha.

### Regressao do Player atualizado

- [x] Atlas atualizado recortado em 85 frames.
- [x] Frames normalizados e alinhados pela base.
- [x] Smoke valida todas as 17 sequencias e suas contagens.
- [x] Orientacao para esquerda espelha o sprite.
- [x] Orientacao para direita remove o espelhamento.
- [x] Collider nao e invertido nem deslocado pela direcao visual.
- [x] Erro de parser de `actor_is_behind` corrigido com tipo booleano explicito.
- [x] `C` ativa agachamento em captura real.
- [x] Smoke sintetiza e valida eventos de `C` e `Shift`.
- [x] Um hit reduz Integridade de 3 para 2 sem abrir a tela de morte.
- [x] Checkpoint e respawn restauram Integridade.
- [x] Cadeia aerea inspecionada em folha com 16 frames limpos.
- [x] Topo visual da plataforma coincide com o topo da colisao.
- [x] Arvores e tronco estao apoiados na linha de piso e sem vizinhos do atlas.

Evidencias adicionais:

- `builds/qa/crouch_input_verified.png`
- `builds/qa/player_air_animation_sheet_v3.png`

Evidencias locais:

- `builds/qa/test_room_enemy.png`
- `builds/qa/stealth_encounter.png`
# QA da Sala de Expansao

## Gate Automatizado

- Executar `tools/run_godot_smoke.ps1`.
- Executar `tools/run_expansion_test.ps1`.
- Nao aceitar `SCRIPT ERROR`, `ERROR` ou recurso ausente.

## Checklist Manual

- Abrir "Sala de mapa e ameacas" pelo Menu Hub.
- Confirmar fonte Cinzel no menu, HUD, GPS e mapa.
- Abrir e fechar mapa com `M`, `Tab` e `Esc`.
- Teletransportar para as cinco ancoras sem cair, travar ou nascer dentro de
  collider.
- Confirmar GPS e distancia apos cada teletransporte.
- Encontrar os quatro novos inimigos e validar idle, movimento, alerta, ataque,
  dano, morte e respawn.
- Confirmar que cada inimigo usa VFX diferente no ataque e na Ressonancia.
- Confirmar que a Sombra remove pontos apenas ao acertar o Player.
- Confirmar que morte do Player pausa a simulacao e exibe as opcoes de retorno.
- Validar parallax sem emendas, texto de atlas ou elementos cortados.
- Validar plataformas, chao, camera e saida da sala herdada.

## Jornada Narrativa

- Executar `tools/run_story_regions_test.ps1`.
- Iniciar historia pelo Menu Hub.
- Confirmar abertura em Clareira do Despertar.
- Confirmar que `E` completa e avanca a fala.
- Confirmar que prompt e banner nao sobrepoem a caixa de dialogo.
- Confirmar que a saida bloqueada informa o requisito.
- Ler a cicatriz, estabilizar a ameaca e confirmar desbloqueio.
- Recolher fragmento, recarregar e confirmar que ele nao reaparece.
- Avancar e retornar entre dois locais.
- Reiniciar e confirmar retomada no ultimo local visitado.
- Testar passos, UI, alerta e lore simultaneamente sem cortes.
- Limpar o painel Debugger e exigir zero erros novos.

### Gate automatizado dos 16 layouts

- [x] Todos os destinos possuem perfil de layout.
- [x] IDs de layout e desafio sao unicos.
- [x] Todas as cenas instanciam `StoryLayout` e `StoryPuzzleController`.
- [x] Puzzles livres e sequenciais concluem e liberam o gate.
- [x] Saida exige lore, ameaca e puzzle.
- [x] Perigos usam sprites de corrupcao e podem ser neutralizados.
- [x] Dispositivos de Ressonancia possuem escala minima legivel.
- [x] Capturas comparativas geradas para Despertar, Forja e Coracao do Vazio.
- [ ] Playtest humano de cada sequencia para calibrar alcance e ordem.
- [ ] Validar mixagem em fones quando uma trilha ambiente estiver disponivel.

## Auto QA da Sala de Teste

Comando principal:

```powershell
.\tools\run_auto_qa.ps1 -Cycles 3
```

Perfis cobertos:

- Critical Path.
- Failure Recovery.
- Interaction Stress.

Gates atuais:

- [x] Caminho critico conclui a sala usando input real.
- [x] Morte, overlay e retentativa nao geram softlock.
- [x] Ressonancia valida sucesso, cooldown e alvo invalido.
- [x] Ponte de Ressonancia nao cria parede invisivel.
- [x] Cobertura detecta a camada fisica do Player.
- [x] Player consegue selecionar inimigo por `F` usando corpo fisico.
- [x] Wrapper gera `latest_report.json` e falha se o log tiver erro.

Documento de analise: `docs/05_Production_QA/AUTO_QA_ANALYSIS.md`.

## Auto QA de Mapa e Historia

Comandos:

```powershell
.\tools\run_map_auto_qa.ps1
.\tools\run_story_auto_qa.ps1
.\tools\run_visual_auto_qa.ps1
```

Gates atuais:

- [x] Mapa abre/fecha sem deixar a arvore pausada indevidamente.
- [x] 5 ancoras registradas e teletransportaveis.
- [x] Checkpoint acompanha teleporte de mapa.
- [x] Sala de mapa possui os 4 inimigos de expansao.
- [x] Primeira sala narrativa fecha intro, le lore, resolve puzzle, estabiliza
  inimigo, coleta fragmento e desbloqueia saida.
- [x] Visual Auto QA gera capturas de sala tecnica, mapa e historia.
- [x] Capturas visuais validam proporcao, resolucao minima e diversidade de cor.
