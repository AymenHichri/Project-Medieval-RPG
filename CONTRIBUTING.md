# Contributing / Development Standards

Applies to all code in this project. Source: `PROJECT_PLAN.md` §10. Visual and audio rules: `ART_GUIDELINES.md`, `AUDIO_GUIDELINES.md`.

## Engine
- **Godot 4.7.2** (the plan targeted 4.6+; 4.7.2 is the installed version). GDScript only.
- Project settings are written by `tools/configure_project.gd`. Change settings there, not only in the editor, so they stay reproducible.

## Typing and naming
- Static typing everywhere (vars, params, returns, `Array[T]`, `Dictionary[K, V]`). `untyped_declaration` is an **error**.
- Files and folders `snake_case`; classes `PascalCase`; functions and vars `snake_case`; constants and enum values `UPPER_SNAKE`; private members `_leading_underscore`.
- Signals are past-tense verbs (`battle_ended`). Requests are method calls.
- Scene node names `PascalCase`. Data ids are `snake_case` and match the filename.

## Structure
- One responsibility per script; ~300 lines is the trigger to split.
- Scene scripts handle presentation and input. Rules live in `scripts/`.
- Use `%UniqueName` references, not long `$A/B/C` paths.
- Exactly **5 autoloads**: GameState, AudioManager, SaveManager, DialogueManager, SceneManager. Don't add more without approval.
- Resources loaded from disk are read-only at runtime. Runtime state lives in RefCounted wrappers.
- No `await` in pure logic classes.
- `##` doc comments on every `class_name`, public method and exported property.

## UI
- All styling comes from `scenes/ui/theme/main_theme.tres`, which is **generated** by `tools/build_theme.gd`. Edit the script, then re-run it. No per-scene font or StyleBox overrides: add a Theme type variation instead.
- Colours come only from `UIPalette` tokens (`scenes/ui/theme/ui_palette.tres`).
- UI roots set `texture_filter = Nearest`. Pixel art is shown at integer scale only.

## Assets
- Never modify anything in `assests/` (original zips). Copies are made with `tools/extract_assets.py`.
- Every external file must be covered by a row in `docs/asset_manifest.csv` (enforced by a test).
- **No generated audio or art.** If an asset is missing, ask the project owner for it.

## Tools and tests
| Command (run from project root) | Purpose |
|---|---|
| `tools/check.sh` (WSL) / `tools\check.ps1` (Windows) | Full check: source checksums, import + parse check, all tests. **Must pass before every commit.** |
| `python -I tools/extract_assets.py` | Copy the needed asset subsets out of the zips |
| `godot --headless --path . -s res://tools/upscale_ui.gd` | ×2 nearest copies of the dfgui UI |
| `python -I tools/apply_import_settings.py` | Mipmaps off for pixel UI folders (then re-run `--import`) |
| `godot --headless --path . -s res://tools/build_theme.gd` | Rebuild theme, fonts and palette (re-run after adding fonts) |
| `godot --headless --path . -s res://tools/configure_project.gd` | Re-apply project settings |
| `godot --headless --path . -s res://tools/build_battle_data.gd` | Rebuild skills, items, enemies, the Knight and its growth curve (`data/`); source of truth for the numbers |
| `godot --headless --path . -s res://tools/build_items.gd` | Rebuild the Phase 9 items (`data/items/`) and equipment (`data/equipment/`); run after `build_battle_data.gd` |
| `godot --headless --path . -s res://tools/build_maps.gd -- village_01` | Rebuild a map and its props from `tools/map_builders/` |
| `godot --headless --path . -s res://tools/build_boss.gd` | Rebuild the Phase 10 boss (stagger status, effect frames, skills, both forms, `data/bosses/`); run after `build_battle_data.gd` and `build_audio.gd` |
| `godot --headless --path . -s res://tools/build_quests.gd` | Rebuild the quests (`data/quests/`); source of truth for stages and texts |
| `tools/balance_sim.gd` (`BalanceSim.run`) | Slice balance simulation; checked by `tests/unit/test_balance.gd` (3–5 fights before resting) |
| `tools/boss_sim.gd` (`BossSim.run`) | Boss balance simulation (3-member party at one level); checked by `tests/unit/test_boss_battle.gd` |
| `godot --headless --path . -s res://tests/test_runner.gd -- --filter=<name>` | Run a subset of tests |

- Every pure-logic class gets `tests/unit/test_<name>.gd`. Every scene type gets a smoke test.
- Tests extend `TestCase`, use a seeded RNG, and never depend on wall-clock time.

## Version control
- Small commits with imperative messages. Source zips are never committed (`.gitignore`).
