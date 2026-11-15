# scenes/battle — battle presentation (Phase 5)

Shows what the pure rules in `scripts/battle/` decide. Nothing here changes battle state: the engine
resolves an action, and this folder only plays back the `BattleEvent`s it returns.

| File | Role |
|---|---|
| `battle_scene.tscn` + `battle_controller.gd` (`BattleController`) | Root. `await start(setup, party, rng, items)` runs one battle: intro → [commands → `begin_round` → present each `execute_next()` → present `end_round()`]… → results. Emits `finished(result)`. Never applies rewards (that is `SceneManager.end_battle`, Phase 6). |
| `battle_presenter.gd` (`BattlePresenter`) | `await play(events)`. One handler per `BattleEvent.Type`. All timing constants live at the top. Keeps its own *shown* HP/MP per combatant, because the engine state is already final when events arrive. |
| `battle_sprite.tscn/.gd` (`BattleSprite`) | One battler: `start_logical(anim)` → `await wait_hit()` → `await wait_finished()`, step/knockback tweens, flash, stand-ins (cast glow, defend stance, victory raise), death, enemy HP bar and shadow. |
| `ui/menu_list.gd` (`MenuList`) | Keyboard/gamepad list with the gauntlet cursor. `await pick()` returns the chosen value or null. Tests drive it with `press(action)`. |
| `ui/command_menu.tscn` | Attack / Skills / Magic / Items / Defend / Flee and the skill/item sub-list (MP cost, greyed when unaffordable). |
| `ui/target_selector.tscn` | Gauntlet cursor over heads; ONE or ALL. `await choose(sprites, all)` → `[]` on cancel. |
| `ui/battle_hud.tscn` | Party rows: name, HP/MP `StatBar`s (`scenes/ui/widgets/stat_bar.tscn`), status icons or tags. |
| `ui/damage_popup.tscn`, `ui/battle_message.tscn`, `ui/results_screen.tscn` | Rising numbers, the top message line, the victory summary. |
| `backgrounds/*.tscn` | **Generated** by `tools/build_battle_backgrounds.gd`: the Gimble's painting (`graveyard_bg`) and the necropolis composite (`graveyard_composite_bg`). Contract: a Node2D behind the battlers; overlays that cover them go on CanvasLayer 1. |
| `debug_battle.tscn` | F6: Knight vs Wolf + Goblin Scout from the exported `BattleSetup`; loops. Set `party_hp = 1` to check defeat, or swap `setup.background` to compare the backgrounds. |

## Conventions
- **Coordinates:** the scene has a fixed `Camera2D` at the screen centre, so battlefield and UI coordinates are the
  same 1920×1080 space. Slots are `Marker2D`s under `PartySlots` (3) and `EnemySlots` (5), at the feet.
- **Battle visuals** are `CombatantVisual` resources in `res://data/visuals/`, generated with the rest of the data by
  `tools/build_battle_data.gd`. Logical animations: `idle, move, attack, skill, cast, hurt, death` plus per-move keys
  named by `SkillData.anim_key` (`whirlwind`, `charged_strike`, `combo`). Moves from the Knight's separate vendor sheets
  are listed in `move_frames`. Anything unmapped falls back as described in `BattleSprite.STAND_INS` and
  `BattlePresenter.melee_anim / cast_anim`.
- **Instant mode** (`BattleController.instant`): no animation and no waiting, but each round still takes one frame.
  `auto_battle` makes the party attack the first living enemy. Tests use both.
- **Input:** project actions `move_*`, `accept` and `cancel` (plus the built-in `ui_*` actions), so keyboard and
  gamepad behave the same. Every handled press is marked handled before the next menu opens, so one press never
  confirms two menus.
