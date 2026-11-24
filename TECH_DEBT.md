# Tech debt and optimisation backlog

Things we knowingly left for later. Most are checked **after the first release build** (Phase 12),
when the game can be profiled as an exported `.exe` instead of in the editor. Phase 12 in
`PROJECT_PLAN.md` holds the planned release tasks; this file holds the debt that piled up while
building Phases 1–10 and the questions only a real build can answer.

**How to use it:** add a row when you take a shortcut (phase, what, why it matters, how to check).
When an item is fixed, move it to *Done* with the date and the commit. Priorities:
**P1** = before or right after the first release build, **P2** = during Chapter 1 content,
**P3** = when it starts to hurt.

Started 2026-11-24 (end of Phase 10). Test suite at that point: 381 tests, `tools/check.sh` ≈ 6 min.

---

## 1. Release blockers to verify (P1)

These are licence and legal questions, not code. The build must not ship until each one is closed.

| ID | Item | Why | How to check / close |
|---|---|---|---|
| RB-1 | **dfgui kit licence unknown** (`All Assets.zip`: MP/XP bars, command icons, map icons, MENU button) | Risk R2b; `release_blocker` in the manifest | Find the source and licence, or replace with the full Gimble's packs. `test_asset_manifest.gd` must report zero release blockers |
| RB-2 | **AlkaKrab licence: "open-source projects need written permission"** | The repo is public. Now 3 tracks are in use (village, boss, dread). The audio files are not committed, but the game code is public | Ask AlkaKrab for written permission, or make the repo private, or replace the tracks |
| RB-3 | Gimble's kit is **AI-assisted** (icons, portraits, backgrounds) | Store disclosure (risk R3b) | Answer store AI-content forms accurately; list it in `CREDITS.md` |
| RB-4 | SovDigital licence: no redistribution as stand-alone assets | The exported `.pck` must not expose the raw sheets as a reusable pack | Check the export (encrypted `.pck` or accept the vendor terms as read); never ship `assests/` |
| RB-5 | `PROJECT_PLAN.md` front matter still says "DRAFT… No gameplay has been implemented" | Misleading for anyone reading the repo | Update the status header to the real state |

## 2. Performance and memory: profile the release build (P1)

Measure in the exported build on the target PC (and a weaker second PC), not in the editor.

| ID | Item | Where | Why it may matter | How to check |
|---|---|---|---|---|
| PF-1 | **Vendor sprite sheets imported whole: 8 directions, but battles use only one row (E or W)** | `assets/vendor/sovdigital/*` (blade_assassin ≈ 89 MB, village 84 MB, knight 76 MB on disk) | VRAM and load time, the boss's second form is 547×422 × 12 frames × 8 rows per animation (risk R11) | Godot *Monitors* → video memory on entering the boss battle; then strip unused rows/animations or cut battle-only atlases |
| PF-2 | Texture import settings never tuned per folder | World art, UI | VRAM, mipmap shimmer at camera zoom 0.75 | Phase 12 task: VRAM compressed + mipmaps for world, lossless for UI; compare memory before/after |
| PF-3 | **Map picture capture** renders the whole map once (1280 px wide) in a `SubViewport` on the first visit | `scenes/ui/menus/map_atlas.gd` | A hitch on first entry of each map, during the fade-in | Profiler on first entry of each map; if visible, capture during the fade-out or lower `CAPTURE_WIDTH` |
| PF-4 | `MapAtlas.save_info` walks every node and writes JSON **on every map entry** | `Map._record_visit` | Small, but it is file I/O on each transition | Measure the map-change time; write only when the file is missing or `VERSION` changed |
| PF-5 | Map page recomputes the auto-exposure (image copy + resize) every time a map is shown | `MapPage.exposure_gain` | Small hitch when browsing the Map tab | Cache the gain in the map's JSON at capture time |
| PF-6 | Map change load time | `SceneManager.change_map` loads the PackedScene synchronously | Target is < 3 s per map (Phase 12 manual check) | Time each transition in the release build; use `ResourceLoader.load_threaded_request` if needed |
| PF-7 | Lights per canvas item (vendor note: 16 max) | Maps with many lamps | Lighting artefacts as maps grow (risk R18) | Visual check in the build; split ground into chunks |
| PF-8 | Battle effects are spawned and freed per hit (`BattleFx.spawn`) | `scenes/battle/battle_fx.gd` | Fine now; may stutter with many targets or multi-hit spells | Profiler during Whirlwind / Blood Mist on 3+ targets; pool them if needed |
| PF-9 | Each quest-giver NPC, BossTrigger and keyed chest connects to `GameState.flag_changed` | `npc.gd`, `boss_trigger.gd`, `chest.gd` | Fine at 5 NPCs; scales with Chapter 1 content | Count connections on the biggest map; switch to a single "quests changed" refresh if it grows |
| PF-10 | Exit-time leaks in headless runs (RIDs, 31 ObjectDB instances, resources still in use) | Test runner output | Usually harmless at exit, but can hide a real leak | Run the release build with `--verbose` and check for leaks after several battles and map changes |

## 3. Code health (P2)

| ID | Item | Where | Note |
|---|---|---|---|
| CH-1 | **`battle_presenter.gd` is 671 lines** (the split trigger is ~300) | `scenes/battle/` | Split the effects/sound choice (`choose_fx`, `choose_sfx`, `_play_*`) and the status handlers into helpers |
| CH-2 | Other files past the trigger: `build_battle_data.gd` 634, `map_build_kit.gd` 478, `battle_sprite.gd` 355, `scene_manager.gd` 350, `action_resolver.gd` 320 | various | Split when next touched (battle_sprite: stand-ins; scene_manager: battle hand-off vs map flow) |
| CH-3 | **Maps are patched by hand and the builders are updated to match** (Phases 8–10) | `scenes/world/maps/*.tscn`, `tools/map_builders/` | Nothing checks that the two still agree. Decide: either the builders stay the source of truth (rebuild and diff in a test), or stop using them for these maps |
| CH-4 | **Flag names are plain strings repeated** in dialogue JSON, `tools/build_quests.gd`, `tools/build_boss.gd` and map scenes | data | A typo breaks a quest silently. Add a test: every flag a quest stage or BossEncounter waits for is set by some dialogue line, choice or `defeated_flag` |
| CH-5 | Dialogue conditions are one flag → one other file, so flag-dependent NPCs become chains of files (`elder_intro → elder_again → elder_again_agreed → elder_report → elder_after`) | `data/dialogue/` | Fine for now (`MAX_REDIRECTS` = 8). For Chapter 1, consider a `conditions` list (first match wins) in one file |
| CH-6 | Generated data is overwritten when its tool runs again (`build_battle_data`, `build_items`, `build_boss`, `build_quests`); `build_boss` also edits `blood_mist.tres` written by `build_battle_data` | `tools/` | Document the run order in one place (or one `build_all` script); any Inspector tuning is lost on re-run |
| CH-7 | Enemies held by a turn-skipping status (Stun, Stagger) skip silently: the engine never queues their actions, so no "cannot move" message shows for them | `BattleEngine.begin_round` | Queue a skip event for enemies too, so the player sees the opening |
| CH-8 | The crypt door's dialogue cue (dread) pops back to the map music, then the boss battle pushes its own music a moment later | `BossTrigger` + `DialogueManager` | Audible blip. Let a trigger keep the cue until the battle push, or skip the cue pop when a battle follows |
| CH-9 | Coroutines on world nodes (NPC `interact`, chest, boss trigger) can resume after their map is freed (Game Over, quit to title) | world components | The boss win flag was moved to `SceneManager` for this reason; audit the others when saving/loading arrives (Phase 11) |
| CH-10 | `QuestLog.to_dict()` exists but there is no `from_dict()`; `visited_maps` and the map cache are not part of a save | `scripts/rpg/quest_log.gd`, `GameState` | Phase 11 save/load must cover quests and visited maps; the `user://map_cache` pictures can stay a cache |
| CH-11 | Map picture cache is invalidated only by bumping `MapAtlas.VERSION` by hand | `map_atlas.gd` | A changed map keeps its old picture. Key the file name on the scene's modified time or a hash, or bump `VERSION` in the release checklist |
| CH-12 | Orphan file `tools/tmp_audio_session.gd.uid` (its `.gd` is gone) | `tools/` | Delete |
| CH-13 | Stats and balance live in tool scripts; there is no `docs/balance.csv` yet | `tools/build_*.gd` | Planned for Phase 11 |

## 4. Tests (P2)

| ID | Item | Note |
|---|---|---|
| TS-1 | **Full check takes ≈ 6 min** (381 tests) | The boss and slice balance simulations and the map smoke tests dominate. Add a quick tier (unit only) for day-to-day, keep the full check before commits |
| TS-2 | **Headless tests that wait a fixed number of frames for something timed in seconds** | Headless frames run at ~7 ms, so "60 frames" is not 1 s. `test_recruitment` was fixed in Phase 10; search for other `for i in N: await process_frame` waits on tweens/timers and wait on the condition instead |
| TS-3 | The map picture capture, sepia grade and every real render path can't run headless | Only covered by manual windowed captures. Add a small windowed smoke run (CI with a GPU, or a manual script kept in `tools/`) before releases |
| TS-4 | Tests share autoload state and each saves/restores what it touches (`flags`, `inventory`, `party`, `quests`, `visited_maps`, music stack) | Easy to forget one (the music stack leak after Game Over was found this way). Add a `GameState.snapshot()/restore()` helper for tests |
| TS-5 | Boss balance is simulated without items or gear | Add a run with the expected kit (potions, Holy Water, Worn Longsword, Pilgrim's Chalice) and check it's not trivial |

## 5. Placeholders to replace (P2–P3)

Content shortcuts that work but should not stay. Most need assets from the owner (see the
missing-asset list in `PROJECT_PLAN.md` §11).

| ID | Placeholder | Real thing needed |
|---|---|---|
| PH-1 | Villagers, Elder, merchant are Knight recolours; the new villagers have no portraits | Villager / NPC sprites and portraits (risk R5) |
| PH-2 | Warden and Hexblade are Knight recolours with Witch Hunter / Witch portraits | Real party member art (risk R6) |
| PH-3 | Chests use the courtyard supply crate | A chest sprite (shut / open) |
| PH-4 | Journal is a dark panel | Worn parchment page (9-slice) |
| PH-5 | Boss music is an interim pick (*Shadowforge Convergence*); story cues reuse existing tracks; **none were chosen by ear** | Listen; commission or source a boss theme |
| PH-6 | Silent hooks: footsteps, combat, magic, monster cries, the boss's voice, chests, doors, ambience | SFX from the owner (`docs/AUDIO_REQUIREMENTS.md`) |
| PH-7 | Boss has no `entrance` animation (not in the free pack); the red-glow "enraged" sheets were not extracted | Full boss pack, or keep the blink-arrival effect |
| PH-8 | No bestiary / boss intro card | Build when there is more than one boss |

## 6. First release build checklist (P1)

Run these on the exported build; file anything found as a new row above.

- [ ] Export preset exists (none yet: no `export_presets.cfg`) and the headless export command in Phase 12 exits 0.
- [ ] Debug-only things are off: F3 overlay (`OS.is_debug_build()`), test switches in `SceneManager` (`instant_*`, `auto_battles`, `battle_rng`).
- [ ] `user://` contents after a play session: `settings.cfg`, `map_cache/` (size of the PNGs), saves (Phase 11). Nothing written next to the `.exe`.
- [ ] FPS ≥ 60 on village, graveyard and the boss battle; note the lowest frame during map changes and the first visit of each map (PF-3).
- [ ] Memory after: title → village → graveyard → 5 battles → boss → back to title. Does it return to the starting level? (PF-1, PF-10)
- [ ] Load time per map < 3 s (PF-6).
- [ ] Audio: every track loops cleanly; volume sliders reach every bus; music returns correctly after battles, dialogue cues and Game Over.
- [ ] Credits screen lists every manifest attribution; zero release blockers (RB-1 … RB-4).

---

## Done

| ID | Item | Fixed | Commit |
|---|---|---|---|
| — | Game Over left the battle's music entry on the push stack (the map music "waited" forever) | 2026-11-24, Phase 10 | `870a33e` |
| — | `test_recruitment` waited 60 frames for a 0.6 s fade | 2026-11-24, Phase 10 | `870a33e` |
