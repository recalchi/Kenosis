# GDD - Game Design Document - Kenosis

## 1. Resumo

Kenosis é uma aventura narrativa 2D side-scrolling com metroidvania lite, ambientada antes dos eventos principais de Exorigem. O jogador controla o Escriba do Fluxo, um arquivista/guardião que não vence pela força, mas pela observação, manipulação de Ressonância e preservação de memórias.

## 2. Loop Principal

```txt
Explorar -> Observar cicatrizes/lore -> Resolver puzzle de Ressonância -> Desbloquear caminho -> Evitar ameaça -> Preservar memória/fragmento -> Avançar
```

## 3. Escopo da Sprint 0.1

- Plataforma: PC-first.
- Cena: sala neutra de teste.
- Objetivo: validar controle, câmera, interação, puzzle de Ressonância e falha.
- Estilo visual: pixel art placeholder.
- Duração do vertical slice futuro: 5 minutos.

## 4. Controles Iniciais

### PC

- Movimento: `A/D` ou setas.
- Pulo: a definir na implementação do player controller.
- Interação: `E`.
- Ressonância: tecla dedicada a definir, sugestão inicial `F`.
- Pausa/Menu: `Esc`.

### Mobile

Mobile é alvo futuro. Não bloqueia a Sprint 0.1.

## 5. Mecânicas Principais

### 5.1 Ressonância

O Escriba manipula Exorigem no ambiente, sem combate direto.

Modelo aprovado para início:

- Uso limitado por cooldown.
- Ativação por proximidade/interação com objetos.
- Primeiro puzzle: transferir/ativar energia entre uma fonte e um receptor.
- Resultado esperado: desbloquear porta, plataforma ou passagem.

Pendências:

- Duração exata do cooldown.
- Feedback visual e sonoro.
- Se haverá medidor de energia além do cooldown.

### 5.2 Leitura de Cicatrizes

Mecânica planejada para revelar lore ambiental. Entra no vertical slice, não precisa bloquear a Sprint 0.1.

### 5.3 Silêncio Intencional

Mecânica planejada para furtividade/sobrevivência. Entra no vertical slice.

### 5.4 Morte/Falha e Regressão de Pontos

O Escriba pode morrer ou falhar. O protótipo deve ter uma consequência simples:

- Reiniciar em checkpoint ou início da sala.
- Reduzir pontuação, fragmentos temporários ou progresso de avaliação.

O modelo exato de regressão ainda precisa ser definido.

## 6. Progressão

Para Sprint 0.1, progressão é local à sala de teste:

- Estado inicial: caminho bloqueado.
- Estado intermediário: Ressonância usada corretamente.
- Estado final: caminho liberado.

Progressão de habilidades, itens narrativos e colecionáveis fica para depois do protótipo técnico.

## 7. Level Design

### Sala Neutra de Teste

Função:

- Validar escala do player.
- Validar colisões e câmera.
- Validar primeira interação.
- Validar puzzle simples.
- Validar falha/regressão.

Elementos mínimos:

- Chão e paredes.
- Fonte de Exorigem.
- Receptor.
- Obstáculo bloqueando a saída.
- Zona de falha ou ameaça simples.
- Saída/desbloqueio.

## 8. Vertical Slice

Critérios do vertical slice de 5 minutos:

- Movimento básico.
- Um puzzle completo de Ressonância.
- Uma leitura de cicatriz.
- Um momento de stealth/fuga.
- Uma cena curta de lore.
- Arte pixel art inicial consistente.
- Áudio temporário coerente.
- Build jogável fora do editor.

## 9. Encontro com o Patrulheiro Corrompido

O Patrulheiro e uma ameaca de furtividade, nao um alvo de combate.

- Patrulha uma faixa definida da sala.
- Detecta a assinatura visivel do Escriba.
- Contato frontal causa falha e regressao de pontos.
- Coberturas permitem ocultar a assinatura com `Shift` ou `C`.
- Ressonancia aplicada pelas costas desfaz temporariamente o no de corrupcao.
- A purificacao libera a saida do campo de testes.

A Cicatriz de Lore antes do encontro ensina a regra dentro da ficcao: antigos
guardioes foram corrompidos, e o Escriba preserva o que resta em vez de
destrui-los.

### Integridade

- O Escriba possui 3 pontos de Integridade no prototipo.
- Ataques do Patrulheiro removem 1 ponto e causam recuo.
- A regressao de pontos acontece apenas ao perder toda a Integridade.
- Checkpoints restauram Integridade e preservam o progresso local.

## 10. Progressao Narrativa por Local

Os 16 destinos do mapa central sao cenas independentes.

```txt
Entrar -> Ouvir memoria de abertura -> Explorar puzzle -> Ler cicatriz
-> Estabilizar ameaca -> Coletar fragmento -> Desbloquear saida
```

- A saida permanece instavel enquanto a cicatriz nao for observada.
- Quando existe inimigo regional, ele tambem precisa ser estabilizado.
- Fragmentos e cicatrizes sao persistidos e nao concedem recompensa repetida.
- O ultimo local troca a saida pela conclusao da memoria.

### Caixa de Dialogo

- Nome do interlocutor.
- Texto com escrita progressiva.
- `E` completa a linha atual e depois avanca.
- Contador de linhas.
- Pausa segura da simulacao.
- Falas carregadas por ID de `dialogue.json`.

## 11. Identidade de Gameplay dos Locais

Cada destino possui um perfil proprio de level design em
`location_layouts.json`. O perfil define:

- Geometria e ritmo de plataformas.
- Posicao de lore, colecionavel e ameaca.
- Perigos regionais.
- Dispositivos de Ressonancia.
- Regra do puzzle: ativacao livre, sequencia ou conclusao narrativa.

As familias de desafio evoluem de tutorial e exploracao para precisao,
sequencias, travessias com perigo, furtividade e ritual. A saida exige tres
condicoes quando aplicaveis: observar a cicatriz, estabilizar a ameaca e
resolver o padrao de Ressonancia.

Os perigos regionais sao neutralizados quando o puzzle local e concluido. Em
puzzles de sequencia, uma ativacao fora de ordem reinicia os dispositivos e
mantem o jogador na sala sem aplicar morte automatica.
