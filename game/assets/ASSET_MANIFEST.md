# Kenosis Asset Manifest

## Regra Canonica

As cenas e scripts devem usar apenas arquivos processados dentro de `game/assets/`.
Os atlas em `assets/**/source/` sao preservados como origem e nunca devem ser
referenciados diretamente em runtime.

## Player e Inimigos

- Player: `assets/sprites/player/animations/<estado>/`.
- Patrulheiro Corrompido: `assets/sprites/enemies/corrupted_patroller/`.
- Abominacao Ancestral: `assets/sprites/enemies/ancestral_abomination/`.
- Energia Instavel: `assets/sprites/enemies/unstable_energy/`.
- Sentinela Mistica: `assets/sprites/enemies/mystic_sentinel/`.
- Sombra da Queda: `assets/sprites/enemies/fallen_shadow/`.

Cada inimigo de expansao possui `idle`, `move`, `alert`, `attack`, `damage`,
`death` e `respawn`, com canvas normalizado e alinhamento consistente.

## Ambiente

- Dia e base anterior: `assets/sprites/backgrounds/day/`.
- Expansao: `assets/sprites/backgrounds/expansion/`.
- Locais de historia: `assets/sprites/backgrounds/locations/<location_id>/`.
  - Clareira do Despertar: `assets/sprites/backgrounds/locations/awakening/`.
- Mapa central: `assets/maps/central_map.png`.

Ordem visual preferencial:

1. Sky e haze.
2. Arquitetura distante.
3. Maquinas e ruinas de midground.
4. Pedras, raizes e sombras de foreground.
5. Fog, luz e particulas de atmosfera.

## UI

- Componentes recortados: `assets/ui/reference/`.
- Fonte padrao: `assets/ui/fonts/Cinzel-Regular.ttf`.
- Tema padrao: `assets/ui/themes/kenosis_theme.tres`.
- Licenca da fonte: `assets/ui/fonts/OFL.txt`.

Menus, HUD, dialogos, mapa e overlays devem herdar o tema padrao antes de
adicionar overrides locais.

## VFX

- Combate: `assets/vfx/combat/`.
- Corrupcao: `assets/vfx/corruption/`.
- Arcano: `assets/vfx/arcane/`.
- Sombra: `assets/vfx/shadow/`.

Os quatro inimigos de expansao possuem VFX distintos para ataque e para dano
por Ressonancia. Novos efeitos devem ser recortados em PNG transparente e
registrados no script ou recurso da entidade que os utiliza.

## Pipeline

- `tools/slice_player_sheet.ps1`
- `tools/slice_enemy_vfx_assets.ps1`
- `tools/slice_expansion_assets.ps1`
- `tools/slice_parallax_assets.ps1`
- `tools/slice_scenario_assets.ps1`
- `tools/slice_ui_reference.ps1`

Depois de gerar novos PNGs, executar:

```powershell
Godot_v4.6.3-stable_win64.exe --headless --path game --import
```
