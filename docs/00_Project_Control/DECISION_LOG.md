# Decision Log - Kenosis

Use este arquivo para registrar decisoes oficiais do projeto.

| Data | Area | Decisao | Motivo | Impacto | Aprovado por |
|---|---|---|---|---|---|
| 2026-06-11 | Engine | Godot 4.6 | Versao aberta ja considerada oficial pelo Renan | Define compatibilidade tecnica, projeto e export futuro | Renan |
| 2026-06-11 | Plataforma | PC-first para prototipo tecnico | Reduz complexidade inicial e acelera validacao jogavel | Mobile fica como alvo posterior, nao como bloqueio da Sprint 0.1 | Renan |
| 2026-06-11 | Plataformas alvo | PC e mobile | Escopo inicial informado | Afeta UI, controles, performance e build | Renan |
| 2026-06-11 | Infraestrutura | Offline | Reduz custo e complexidade inicial | Sem backend/multiplayer no MVP | Renan |
| 2026-06-11 | Genero | Aventura narrativa side-scrolling com metroidvania lite | Alinha a visao de exploracao, lore ambiental e puzzles | Orienta GDD, level design e prototipo | Renan |
| 2026-06-11 | Vertical slice | Duracao alvo de 5 minutos | Escopo pequeno, demonstravel e testavel | Define tamanho da primeira experiencia completa | Renan |
| 2026-06-11 | Primeira sala | Sala neutra de teste | Evita travar producao em arte/lore antes de validar mecanicas | Sprint 0.1 prioriza prototipo tecnico | Renan |
| 2026-06-11 | Ressonancia | Baseada em cooldown | Facilita implementacao inicial e balanceamento | Define o primeiro modelo de custo/limitacao da mecanica | Renan |
| 2026-06-11 | Falha | Escriba pode morrer/falhar, com regressao de pontos | Cria consequencia jogavel desde cedo | Exige sistema simples de checkpoint/pontuacao/regressao | Renan |
| 2026-06-11 | Furtividade | Entra no vertical slice | Mantem o prototipo tecnico focado e reserva stealth para a proxima camada jogavel | Afeta backlog da Sprint 0.2/vertical slice | Renan |
| 2026-06-11 | Estilo visual inicial | Pixel art | Reduz custo inicial e viabiliza placeholders coerentes | Guia Art Bible e assets temporarios | Renan |
| 2026-06-11 | Monetizacao | Congelada ate depois do vertical slice | Evita conflito prematuro com narrativa e escopo | Marketing/negocio nao bloqueiam o prototipo | Renan |
| 2026-06-11 | Sprint | Sprint 0.1 aprovada | Comecar prototipo tecnico jogavel | Autoriza organizacao documental e preparacao da base tecnica | Renan |
| 2026-06-17 | Lore | Logos Primordial e Coracao Silencioso sao conceitos distintos | Corrigir desvio canonico entre escopo antigo e Narrative Bible | Missao do Escriba passa a preservar o Coracao sem restaurar o Logos institucionalizado | Renan |
| 2026-06-17 | Lore | Pecados capitais ficam reservados para o jogo principal 3D | Renan confirmou que o framework de pecados nao e eixo de Kenosis | Docs, dados, dialogos e locais de Kenosis devem usar Engenharia Social Mistica, controle, eficiencia e padronizacao | Renan |
| 2026-06-17 | Lore | Final canonico aponta para Kenosis e renascimento, nao sacrificio total | Alinha Ato III, Rebirth e dialogos atuais | O Escriba esvazia a vontade de permanencia e abre espaco para outra vida | Renan |
| 2026-06-17 | Mapa/GPS | O mapa e desbloqueado por uma Lente Cartografica e passa a usar interacao direta no atlas | Transformar o mapa em recompensa de exploracao e reduzir dependencia da lista lateral | Mapa central recebe descoberta, marcadores, ponto do jogador, zoom, pan e abertura animada | Renan |
| 2026-06-17 | Mapa/GPS | A interacao central usa hotspots invisiveis sobre os simbolos nativos do atlas | Preservar integralmente a leitura da arte e eliminar marcadores genericos sobrepostos | Os 16 pontos usam coordenadas nativas; descoberta e posicao do Player sao comunicadas no painel lateral | Renan |
| 2026-06-17 | Mapa/GPS | Missao e navegacao compartilham o ObjectivePanel; bloqueios dessaturam a arte e a posicao atual usa marcador dourado | Eliminar paineis concorrentes e tornar progresso/localizacao legiveis sem badges genericos | Clique no ponto informa a fase; teleporte fica explicito na lista lateral | Renan |
| 2026-06-17 | Mapa/GPS | A abertura usa oito frames de pergaminho e fases visitadas aceitam viagem direta | Dar identidade ao acesso do mapa e reduzir retrabalho ao revisitar memorias | A animacao bloqueia input; viagem valida unlock, fase atual e cena antes de atualizar o save | Renan |
| 2026-06-17 | Mapa/GPS | A viagem pelo mapa usa StoryTransition e a interface permanece oculta durante o pergaminho | Corrigir encerramento por acesso ao MapNavigator removido e eliminar dois mapas simultaneos | Troca de cena sobrevive ao descarte da sala; atlas e painel aparecem somente no crossfade final | Renan |
