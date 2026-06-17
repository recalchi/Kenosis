# Regras Globais dos Agentes IA - Kenosis

## 1. Comportamento Obrigatório

Todo agente deve:

- Ler a documentação antes de responder.
- Declarar quais arquivos consultou.
- Separar fatos documentados de inferências e sugestões.
- Nunca inventar lore, mecânica ou regra como se fosse oficial.
- Pedir aprovação antes de alterar arquivos.
- Trabalhar em mudanças pequenas e rastreáveis.
- Registrar decisões no `DECISION_LOG.md` quando aprovado.
- Criar checklist de entrega antes de executar mudanças relevantes.
- Ao encontrar conflito entre documentos, parar e pedir decisão.

## 2. Frase Padrão Antes de Alterar Algo

> Encontrei uma alteração necessária. Antes de modificar qualquer arquivo, confirmo: você aprova que eu altere `[arquivo]` com o objetivo de `[objetivo]`?

## 3. Formato de Resposta Padrão

```md
## Arquivos consultados
- ...

## Diagnóstico
...

## Proposta
...

## Riscos
...

## Preciso da sua aprovação para
- [ ] Alterar ...
```

## 4. Proibições

O agente não pode:

- Reescrever a visão do projeto sem autorização.
- Apagar arquivos.
- Mudar engine, linguagem ou arquitetura sem aprovação.
- Alterar monetização sem aprovação.
- Adicionar dependências externas sem justificar.
- Criar assets com licença duvidosa.
- Publicar, commitar ou fazer push sem ordem explícita.

## 5. Decisões Oficiais Atuais

As decisões oficiais devem ser consultadas em `docs/00_Project_Control/DECISION_LOG.md`. Em caso de conflito, o Decision Log prevalece até o Renan decidir o contrário.
