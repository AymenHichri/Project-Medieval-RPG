# Audio Catalog

_Status: draft v1 (2026-11-13). **The workspace contains no audio files.** This catalog defines what is needed, lists candidate sources to investigate, and holds the licence record for every track and sound once it is added. The assistant does not download audio. Licences of candidate sources must be **verified per file at download time**: "free" does not mean free for commercial use._

## 1. Licence acceptance rules

| Licence | Accept? | Notes |
|---|---|---|
| CC0 / public domain | ✅ | Keep a copy of the source page or licence anyway |
| CC BY 3.0/4.0 | ✅ | **Attribution required** in credits. Record the exact credit line |
| Royalty-free commercial EULA (e.g. Sonniss GDC bundles, paid itch packs) | ✅ after reading | Keep the EULA file next to the originals |
| CC BY-SA | ⚠ Case by case | Share-alike may apply to modified audio. Avoid for music |
| CC BY-ND | ⚠ Avoid | "No derivatives" can forbid loop edits and fades baked into the file |
| CC BY-NC (any) | ❌ | No commercial use |
| "No copyright" YouTube re-uploads, unknown origin | ❌ | Unverifiable provenance |
| AI-generated (e.g. ElevenLabs via the available `sound-effects` skill) | ⚠ User decision | Licence depends on the provider plan. Must be disclosed on stores like Steam |

## 2. Candidate sources (to investigate; not downloaded)

| Source | Type | Licence model (verify) | Fit for direction |
|---|---|---|---|
| Kenney.nl audio packs (e.g. *Interface Sounds*, *RPG Audio*, *Impact Sounds*) | SFX | CC0 | Good for UI clicks, footsteps, doors, coins. Some sounds are bright, so pick darker ones |
| Sonniss "GDC Game Audio Bundle" (yearly) | SFX, ambience | Royalty-free, commercial, no attribution (per its EULA) | Excellent: weapons, foley, weather, ambiences |
| Freesound.org | SFX, ambience | Per file: CC0 / CC BY / **CC BY-NC (reject)** | Large; filter by licence; good for crows, bells, wind |
| OpenGameArt.org | Music, SFX | Per asset: CC0 / CC BY / CC BY-SA / GPL / OGA-BY | Mixed quality; some dark fantasy music |
| Kevin MacLeod (incompetech.com) | Music | CC BY 4.0 (paid no-attribution licence available) | Some dark and medieval tracks. Widely used, so players may recognise them |
| Alexander Nakarada (serpentsoundstudios.com) | Music | CC BY 4.0 for many tracks (verify per track) | Strong medieval/fantasy catalogue |
| itch.io dark fantasy / medieval music packs | Music | Per pack | Check each pack's terms; many are paid with commercial rights |
| Commissioned composer | Main theme, boss, key story cues | Contract (buy-out or licence) | Best for a unique identity. Budget decision |

## 3. Required music (track list)

| ID | Category | Status | Slice |
|---|---|---|---|
| `mus_main_theme` | Main theme | Needed | — |
| `mus_menu` | Main menu | Needed | ✅ |
| `mus_town_hamlet` | Village | Needed | ✅ |
| `mus_overworld` | Overworld | Needed | — |
| `mus_forest` | Forest | Needed | — |
| `mus_dungeon_graveyard` | Dungeon / graveyard | Needed | ✅ |
| `mus_battle` | Regular battle | Needed | ✅ |
| `mus_boss_assassin` | Boss | Needed | — |
| `mus_story_sorrow`, `mus_story_dread` | Story moments | Needed | — |
| `jng_victory` | Victory jingle | Needed | ✅ |
| `jng_gameover` | Game over | Needed | ✅ |
| `jng_levelup` | Level up | Needed | ✅ |

## 4. Required SFX (slice minimum; full list by category in `AUDIO_GUIDELINES.md` §3)

`sfx_ui_move`, `sfx_ui_confirm`, `sfx_ui_cancel`, `sfx_ui_open` · `sfx_footsteps_{stone,grass,mud}_01..04` · `sfx_interact_chest_open` · `sfx_combat_{swing,hit,crit,miss}` · `sfx_magic_{cast,fire,heal}` · `sfx_enemies_{wolf_howl,skeleton_rattle,goblin_shriek}` · `amb_village_wind_loop`, `amb_graveyard_wind_crows_loop` · `sfx_reward_{gold,item}` · `sfx_progress_{levelup,save}`.

### Sourcing gate status (Milestone 1, 2026-11-17)

**Not met.** No audio was supplied before Phase 7, so the vertical slice runs silent (no placeholder tones, per the 2026-11-13 decision). Every hook is in place, so adding the files is data work only:

| What | Where to assign it |
|---|---|
| `mus_menu` | `TitleScreen.music` (`scenes/ui/title_screen.tscn`) |
| `mus_village`, `mus_graveyard` + ambience beds | `Map.music` / `Map.ambience` on each map (set in `tools/map_builders/*`, then rebuild) |
| `mus_battle` | `EncounterTable.music` (`tools/build_encounters.gd`) |
| `jng_victory`, `jng_gameover` | `SceneManager.victory_jingle` / `SceneManager.game_over_jingle` |
| `jng_levelup` | not wired yet: play it on `GameState.member_leveled` once the file exists |
| UI sounds | `data/audio/sfx_library.tres` → `ui`: `focus`, `confirm`, `cancel`, `tick` (typewriter) |
| Footsteps | `data/audio/sfx_library.tres` → `footsteps`: `grass`, `mud`, `stone`, `ash` (unknown surfaces fall back to `stone`) |
| Combat and monster SFX | not wired yet: the battle presenter has no sound calls. Add them when the files exist (`AudioManager.sfx.play_ui` for hits/casts, one set per enemy for cries) |

## 5. Licence records (one row per file or per pack; fill in when added)

| Name | Creator | Source URL | Licence | Commercial use | Attribution required (exact credit line) | Format | Intended usage | Project path | Original kept at | Date added |
|---|---|---|---|---|---|---|---|---|---|---|
| _(empty: no audio yet)_ | | | | | | | | | | |

The machine-readable copy of these rows lives in `docs/asset_manifest.csv`. The test `test_asset_manifest.gd` fails if any file under `assets/audio/` lacks a row, or if a row has an empty licence field or `commercial_use = no`.
