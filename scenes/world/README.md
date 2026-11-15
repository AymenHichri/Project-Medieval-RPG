# scenes/world

- `map.gd` (`Map`): base script for every exploration map. Child layout: see PROJECT_PLAN.md §6.1.
  `place_player(spawn_id)` puts the map's player on a spawn (unknown id → first spawn + warning).
- Maps are changed only through `SceneManager.change_map(map_path, spawn_id)` (fade, swap, place, fade).
- `maps/*.tscn`, `props/village/*.tscn` and `props/necropolis/*.tscn` are **generated** by the builders in
  `tools/map_builders/` (shared code: `tools/map_build_kit.gd`). Change a layout in its builder and re-run:
  `godot --headless --path . -s res://tools/build_maps.gd [-- village_01 graveyard_01]` (no argument = all maps).
  Once a map is edited by hand in the editor, stop re-running its builder (it overwrites the scene).
- Prop scenes: the origin is the piece's base (the Y-sort point). `Sprite` is offset by the vendor pivot, and
  `Body/Footprint` is the vendor footprint on physics layer 1 `world_solid`.
- Everything that moves or stands up goes under the map's y-sorted `World` node, at the same z_index.

## Components (`components/`)
| Scene | Physics layer | Use |
|---|---|---|
| `spawn_point.gd` (Marker2D) | – | Entry point: `spawn_id`, `facing`. Put spawns under `Spawns`; the first is the fallback. Keep them clear of exits. |
| `map_transition.tscn` (Area2D) | 5 `triggers`, watches 3 `player` | Exit: `target_map`, `target_spawn`, `size`. Put exits under `Transitions`. |
| `encounter_zone.tscn` (Area2D) | 5 `triggers`, watches 3 `player` | Random encounters: `table` (`EncounterTable`), `polygon` (local px). Put zones under `Encounters`; they may overlap (last entered wins). |
| `interactable.tscn` (Area2D) | 4 `interactables` | Child of a prop, at its base: `prompt_text`, `dialogue_id` (`data/dialogue/<id>.json`), `radius`, `prompt_offset`. Emits `interacted(by)`. |

The player's `InteractionProbe` (Area2D, watches layer 4) sits 56 px in front of the feet, focuses the nearest
Interactable and interacts on `accept`. The player can't move or interact while `PlayerController.can_act()` is
false (fades, open dialogue).

## Random encounters
The player's `EncounterTracker` (`player/encounter_tracker.gd`) turns real travelled distance into steps (64 px
each; walking into a wall counts nothing), ticks `GameState.encounter_rate_modifiers` once per step and, inside a
zone, asks `EncounterRoller` for a battle. No roll for the table's `grace_steps` after entering a map, after a
battle or after a dialogue. The map turns `encounter_triggered` into a `BattleSetup` for
`SceneManager.start_battle()`, which detaches the map (kept in memory) and puts it back afterwards.
Debug builds (F3 overlay): **F4** encounters on/off, **F5** force an encounter in the current zone.
