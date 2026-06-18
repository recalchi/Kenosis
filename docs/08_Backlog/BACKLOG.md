# Backlog - Kenosis

## Prioridade P0 - Sala de Expansao e Mapa Central

- [x] Processar os quatro novos atlas de inimigos em animacoes normalizadas.
- [x] Implementar Abominacao Ancestral.
- [x] Implementar Energia Instavel.
- [x] Implementar Sentinela Mistica.
- [x] Implementar Sombra da Queda.
- [x] Conectar VFX de ataque e Ressonancia de cada inimigo.
- [x] Criar backgrounds de sky, arquitetura, midground, foreground e atmosfera.
- [x] Criar sala de teste derivada com cinco regioes de validacao.
- [x] Criar mapa central com 16 destinos mapeados.
- [x] Criar GPS e teletransporte entre cinco ancoras.
- [x] Criar os sete arquivos de dados minimos e o DataRegistry.
- [x] Integrar balanceamento dos inimigos ao `balance.json`.
- [x] Criar sete shaders e materiais base.
- [x] Criar oito prefabs de marcadores de level design.
- [x] Aplicar fonte e tema canonicos ao menu, HUD e mapa.
- [x] Criar teste automatizado da expansao.
- [x] Transformar o atlas central em mapa interativo com hotspots invisiveis.
- [x] Mapear os 16 pontos nos simbolos e rotulos nativos sem sobreposicao visual.
- [x] Mesclar missao, localizacao, distancia e memorias em um unico painel.
- [x] Projetar a posicao atual com marcador cartografico dourado.
- [x] Dessaturar os simbolos nativos das fases ainda nao liberadas.
- [x] Exibir nome e status da fase ao selecionar um ponto do atlas.
- [x] Adicionar zoom, pan e centralizacao.
- [x] Adicionar abertura animada do mapa com oito frames do pergaminho.
- [x] Adicionar viagem para fases narrativas ja visitadas.
- [x] Impedir viagem para a fase atual ou para destinos ainda bloqueados.
- [x] Criar Lente Cartografica persistente na sala de mapa e em Awakening.
- [x] Bloquear o mapa ate a coleta da Lente Cartografica.
- [ ] Executar rodada de playtest manual de ritmo, colisao e legibilidade.
- [ ] Ajustar balanceamento apos cinco sessoes de teste.

## Prioridade P0 - Auto QA e Estabilidade

- [x] Criar bot autonomo da sala de teste.
- [x] Criar perfil de caminho critico.
- [x] Criar perfil de morte e retentativa.
- [x] Criar perfil de estresse de Ressonancia/interacao.
- [x] Gerar relatorio JSON em `builds/qa/autobot/latest_report.json`.
- [x] Criar wrapper `tools/run_auto_qa.ps1`.
- [x] Corrigir ponte de Ressonancia bloqueando travessia.
- [x] Corrigir cobertura sem deteccao da camada do Player.
- [x] Corrigir selecao de inimigo por `F`.
- [x] Criar Auto QA da sala de mapa.
- [x] Criar Auto QA de pelo menos uma sala narrativa.
- [x] Adicionar feedback visual ativo na cobertura furtiva.
- [x] Adicionar pulso de materializacao da ponte de Ressonancia.
- [x] Criar captura visual nao-headless opcional para comparacao de screenshots.
- [x] Melhorar nomes longos truncados nos botoes laterais do mapa.
- [ ] Expandir Story Auto QA para as 16 salas narrativas.

## Prioridade P0 - Jornada Narrativa dos 16 Locais

- [x] Criar cena independente para cada destino do mapa central.
- [x] Criar controlador compartilhado de local narrativo.
- [x] Conectar os 16 locais em ordem, com retorno e avancar.
- [x] Habilitar iniciar/continuar historia no Menu Hub.
- [x] Criar fala de entrada e cicatriz para cada local.
- [x] Criar colecionavel persistente para cada local.
- [x] Bloquear saida ate observar lore e estabilizar a ameaca.
- [x] Criar caixa de dialogo com typewriter, speaker e contador.
- [x] Migrar save para local atual, desbloqueios, lore e colecionaveis.
- [x] Corrigir cortes de audio com pools de reproducao.
- [x] Eliminar erros de tween e loops do depurador.
- [x] Criar teste automatizado da jornada narrativa.
- [x] Criar layouts exclusivos de plataforma para cada local.
- [x] Criar puzzles exclusivos por regiao.
- [ ] Criar encontros narrativos sem combate para locais de transicao.

## Prioridade P0 - Sprint 0.2: Ameaca, furtividade e persistencia

- [x] Importar e recortar o atlas do Patrulheiro Corrompido.
- [x] Criar animacoes multi-frame de idle, patrulha, alerta, furtividade, ataque, dano, morte e reformacao.
- [x] Criar IA de patrulha, visao, alerta, perseguicao e contato fatal.
- [x] Criar cobertura e ocultacao de assinatura com `Shift` ou `C`.
- [x] Criar interacao de Ressonancia pelas costas, sem combate direto.
- [x] Bloquear a saida ate o Patrulheiro ser purificado.
- [x] Criar Cicatriz de Lore e overlay de dialogo pausavel.
- [x] Animar checkpoint e persistir checkpoint/pontuacao.
- [x] Criar save local em `user://kenosis_save.cfg`.
- [x] Integrar SFX e jingle CC0 da Kenney.
- [x] Criar buses configuraveis de Music e SFX.
- [x] Integrar VFX de alerta, corrupcao, checkpoint e Ressonancia.
- [x] Ampliar smoke test para furtividade, dialogo, inimigo, save e desbloqueio da saida.
- [x] Planejar o vertical slice jogavel de 5 minutos.
- [x] Adicionar Integridade 3/3 e eliminar hitkill do Patrulheiro.
- [x] Adicionar HUD de vida e feedback de dano.
- [x] Corrigir comandos de agachar em `Shift` e `C`.
- [x] Exibir estado agachado, cobertura disponivel e assinatura oculta.
- [x] Recortar individualmente toda a cadeia aerea do Player.
- [x] Corrigir recortes de arvores, tronco e VFX usados na sala.
- [x] Apoiar props decorativos na mesma linha visual do piso.
- [x] Alinhar o topo visual das plataformas com a colisao.

## Prioridade P0 - Sprint 0.1: Protótipo Técnico PC-first

- [x] Criar estrutura inicial dentro de `game/`: `scenes/`, `scripts/`, `assets/`, `data/` e `tests/`.
- [x] Criar cena neutra de teste.
- [x] Criar player controller 2D para PC.
- [x] Criar câmera seguindo o jogador sem tremor.
- [x] Criar colisão básica de chão, parede e plataforma.
- [x] Criar sistema básico de interação.
- [x] Criar sistema inicial de Ressonância baseado em cooldown.
- [x] Criar objeto fonte de Exorigem e objeto receptor.
- [x] Criar puzzle simples que desbloqueia caminho ao usar Ressonância.
- [x] Criar HUD mínimo com cooldown/status de Ressonância.
- [x] Criar menu hub inicial com botão Continuar.
- [x] Criar tutorial opcional básico.
- [x] Criar pausa pelo `Esc` com retomar, menu e sair.
- [x] Criar sistema de morte/falha.
- [x] Criar opções pós-falha: tentar de novo, voltar ao menu e sair.
- [x] Criar regressão simples de pontos após falha.
- [x] Criar checklist manual de QA da Sprint 0.1.
- [x] Criar estrutura expandida de pastas de assets, data, cenas, scripts e marketing.
- [x] Importar e fatiar sprites principais do Escriba/Player.
- [x] Montar `AnimatedSprite2D` do player com os estados principais.
- [x] Trocar sprite visual do player por estado: idle, movimento, pulo, queda, Ressonância, falha e respawn.
- [x] Substituir fonte, receptor, gate, hazard e saída por sprites placeholder próprios.
- [x] Importar atlas de cenario e gerar recortes iniciais de tiles/props.
- [x] Fazer Ressonancia materializar ponte e neutralizar lago de falha.
- [x] Ajustar velocidade e pulo do player para a sala tecnica.
- [x] Corrigir limites laterais para impedir queda infinita.
- [x] Alinhar colisao e largura visual das plataformas.
- [x] Ampliar viewport e campo de visao da camera.
- [x] Transformar a saida em interacao concluivel por `E`.
- [x] Implantar parallax diurno em quatro camadas.
- [x] Reconstruir HUB e HUD com a referencia visual Kenosis.
- [x] Adicionar texto animado no HUB e na abertura da gameplay.
- [x] Adicionar configuracoes persistentes de audio, video, tutoriais e velocidade de texto.
- [x] Identificar o primeiro nivel como campo de testes e manter historia indisponivel.
- [x] Corrigir recorte da animacao `interact` removendo a pedra.

## Prioridade P1 - Vertical Slice de 5 Minutos

- [x] Definir mapa curto do vertical slice.
- [x] Definir ritmo de entrada, puzzle, ameaca e saida.
- [x] Criar uma leitura de cicatriz/lore.
- [x] Criar um momento simples de furtividade/fuga.
- [x] Criar estado de alerta da ameaca.
- [x] Criar feedback visual e sonoro minimo para falha.
- [x] Criar arte pixel art temporária do Escriba.
- [x] Criar tileset placeholder.
- [x] Criar SFX placeholder para interacao, Ressonancia e alerta.
- [x] Testar fluxo completo com contrato automatizado e Auto QA.
- [x] Centralizar balance do slice em `balance.json`.
- [x] Criar HUD de objetivos e explicacao de memorias/pontos.
- [x] Adicionar gasto opcional de memorias no selo.
- [ ] Testar fluxo completo em ate 5 minutos com playtest humano.
- [ ] Exportar build Windows e repetir QA fora do editor.

## Prioridade P2 - Fundação de Produção

- [ ] Definir público-alvo.
- [ ] Detalhar regras finais da Ressonância.
- [ ] Detalhar sistema de regressão de pontos.
- [ ] Definir guia inicial de pixel art.
- [ ] Definir paleta inicial.
- [ ] Definir política de licenças para assets temporários.
- [ ] Definir padrão de versionamento.
- [ ] Definir pipeline de export Windows.

## Prioridade P3 - Pós-Vertical Slice

- [ ] Reavaliar mobile.
- [ ] Reabrir decisão de monetização.
- [ ] Planejar página oficial.
- [ ] Planejar Steam futura.
- [ ] Criar trailer curto.
- [ ] Criar press kit.
