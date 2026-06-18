# Kenosis UI Assets - Cursores, Ícones e HUD

Pacote gerado para uso no jogo, seguindo a estética pixel-art místico/pergaminho das referências enviadas.

## Conteúdo

- `cursors/`: 6 variações de mouse/selector em 32, 48, 64 e 96 px.
- `icons/`: 8 ícones em 16, 24, 32, 48, 64 e 128 px.
  - vida
  - falha
  - energia
  - ressonância
  - corrupção
  - memória
  - aviso
  - recarga
- `hud_superior_esquerdo/`: HUD completo em 383x105, 766x210, 1532x420 e 1024x281.
- `hud_superior_esquerdo/elementos_individuais/`: frame, bússola, barra de ressonância, fileira de vidas e elementos separados.
- `sprite_sheets/`: sheets de ícones e cursores.
- `manifest.json`: lista de arquivos, tamanhos e hotspot sugerido dos cursores.
- `preview_pack.png`: prévia visual do pacote.

## Recomendações de importação

- Para Unity/Godot: importar PNG com filtro `Nearest/Point`, compressão desativada ou baixa, sem blur.
- Para cursor: usar o hotspot sugerido em `manifest.json`.
- Para UI 2D: preferir os assets 2x ou 4x e reduzir dentro do motor se precisar manter nitidez.

## Observação

Os arquivos são PNG com fundo transparente, exceto a área interna do HUD que usa fundo pergaminho claro.
