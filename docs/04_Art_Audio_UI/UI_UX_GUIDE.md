# UI/UX Guide - Kenosis

## 1. Princípios

- UI discreta e imersiva.
- Legibilidade em PC e mobile.
- Evitar poluição visual.
- Interface deve reforçar o tom místico/rústico.
- Sprint 0.1 deve priorizar clareza de teste acima de estilo final.

## 2. Plataformas

### PC

Foco da Sprint 0.1.

- Teclado/mouse.
- Controle fica como possibilidade futura.

### Mobile

Alvo futuro. Não bloqueia a Sprint 0.1.

## 3. HUD da Sprint 0.1

Elementos mínimos:

- Indicador de cooldown da Ressonância.
- Pontos ou indicador de regressão.
- Prompt de interação.
- Feedback de falha.

## 4. Telas Futuras

- Menu inicial. Criado como hub básico na Sprint 0.1.
- Novo jogo/continuar.
- Configurações.
- Pausa.
- Diário/Lore.
- Tela de morte/falha.
- Créditos.

## 5. Acessibilidade

Prioridades futuras:

- Legendas.
- Tamanho de texto.
- Remapeamento de controles.
- Controle de brilho.
- Redução de efeitos visuais.

## 6. Critério de UX Para Protótipo

O jogador precisa entender sem explicação externa:

- Onde pode andar.
- Com o que pode interagir.
- Quando Ressonância está disponível.
- O que mudou após ativar o puzzle.
- O que causou falha.

## 7. Menu Hub da Sprint 0.1

Estado atual:

- Botão Continuar abre a sala neutra de teste.
- Tutorial opcional abre um painel simples com objetivo, controles e regra de falha.
- Botão Sair encerra o jogo.
- Dentro da sala, `Esc` abre pausa com Retomar, Voltar ao menu e Sair.
- Após falha, o jogador vê opções para Tentar de novo, Voltar ao menu ou Sair.

O hub ainda usa visual placeholder e deve receber assets/estilo final depois.

## 8. UI Canonica da Expansao

- Fonte oficial de interface: Cinzel, carregada pelo tema
  `game/assets/ui/themes/kenosis_theme.tres`.
- HUD, menu, dialogo, pausa, morte e mapa devem herdar esse tema.
- Molduras, botoes, icones de interacao e marcadores devem usar os recortes de
  `game/assets/ui/reference/`.
- Overrides locais sao permitidos para contraste e estado, mas nao devem trocar
  a familia tipografica.

### Mapa e GPS

- `M` ou `Tab` abre o mapa central.
- O mapa apresenta 16 destinos narrativos e cinco ancoras ativas na sala de
  expansao.
- O GPS permanece no canto superior direito, informa a ancora mais proxima e
  a distancia aproximada.
- Teletransporte move o Player para uma ancora segura e atualiza o ponto de
  retorno.
- `Esc` fecha primeiro o mapa antes de abrir a pausa da sala.
