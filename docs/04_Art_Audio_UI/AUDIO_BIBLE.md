# Audio Bible - Kenosis

## 1. Direcao Sonora

Som melancolico, mistico, organico e ritualistico, com contraste entre silencio
contemplativo e colapso sistemico.

## 2. Objetivo da Sprint 0.1

Usar audio placeholder simples apenas para validar feedback de gameplay.

Sons minimos:

- Interacao.
- Ressonancia ativada.
- Ressonancia em cooldown/erro.
- Receptor ativado.
- Falha/morte.

## 3. Ferramentas

- Edicao: Audacity.
- Musica: Reaper.
- Middleware: FMOD fica como possibilidade futura, nao obrigatorio para Sprint 0.1.
- Bibliotecas: apenas com licenca clara.

## 4. Musica

Nao e obrigatoria na Sprint 0.1. Para vertical slice, usar ambiencia curta e
discreta.

### Ato I

- Sensacao: grandeza, ordem artificial, tensao oculta.
- Instrumentos: a definir.

### Ato II

- Sensacao: colapso, pressao, instabilidade.
- Instrumentos: a definir.

### Ato III

- Sensacao: silencio, renuncia, preservacao e renascimento.
- Instrumentos: a definir.

## 5. SFX

| Sistema | Sons necessarios | Prioridade |
|---|---|---|
| Movimento | passos, queda, pouso | Media |
| Ressonancia | ativacao, pulso, erro/cooldown | Alta |
| Lore | transe, memoria, ruido espiritual | Media |
| UI | selecao, confirmacao, erro | Media |
| Ameacas | presenca, alerta, perseguicao | Alta para vertical slice |

## 6. Licencas e Creditos

Todo audio externo deve ter:

- Nome do arquivo.
- Fonte.
- Licenca.
- Autor.
- Link.
- Uso permitido.

## 7. Biblioteca Inicial Integrada

Fonte: Kenney, licenca Creative Commons Zero (CC0 1.0).

Pacotes:

- RPG Audio: leitura de lore.
- Interface Sounds: selecao, confirmacao, abertura, fechamento e erro.
- Impact Sounds: passos, falha e checkpoint.
- Music Jingles: assinatura curta de conclusao.

Os arquivos selecionados ficam em `game/assets/audio/` e os creditos em
`game/assets/audio/LICENSES.md`.

Ainda falta para o vertical slice:

- Ambiencia continua propria para o campo.
- Camada musical discreta que nao concorra com leitura e furtividade.
- Variacoes de passos, pouso e perseguicao.
