# Audio Catalog

_Status: draft v2 (2026-11-17). **The workspace contains no audio files yet.** This file is the brief for the **audio asset audit and implementation**, which is **Step 0a of Phase 7A: Audio setup** in `PROJECT_PLAN.md`. Run its phases in order whenever Phase 7A starts, and again whenever new audio packs arrive. It also keeps the reference material the audit builds on: licence rules (§A), candidate sources (§B), the required track and SFX lists (§C), the hook-up table (§D) and the licence record (§E)._

_The assistant does not download or buy audio. Licences of candidate sources must be **verified per file at download time**: "free" does not mean free for commercial use._

---

## Audit brief

We are developing **The First Heresy**, a dark fantasy 2D JRPG in Godot 4 using GDScript. The audit inspects the project's existing audio assets and establishes a coherent audio direction.

**Scope rule:** Phases 1–5 are research and documentation only. They do **not** implement an audio system, change game code, or bring assets into the game. Implementation is Phase 6, and it starts only after the user approves the audit's final output.

### Creative direction

The game combines:
- Dark medieval fantasy
- Cosmic horror
- Body horror
- Forgotten gods and ancient rituals
- Unreliable companions and fragmented storytelling
- Turn-based JRPG combat
- Top-down exploration

The audio should feel ancient, oppressive, mysterious and unsettling. Avoid generic heroic fantasy music, cheerful RPG music, exaggerated cartoon sounds and overly cinematic action music.

The desired sound palette includes:
- Dark ambient
- Dungeon synth
- Medieval folk
- Dissonant orchestral strings
- Distant choirs
- Ritual percussion
- Low drones
- Organic and disturbing sound textures
- Environmental horror ambience

(This extends the direction in `AUDIO_GUIDELINES.md` §1. If the two disagree, Phase 4 resolves it and updates `AUDIO_GUIDELINES.md`.)

### Phase 1: Inspect existing audio

Inspect every relevant audio directory in the project and every downloaded asset folder that is accessible: at least `assets/audio/`, `assests/audio_sources/`, the vendor packs under `assets/vendor/`, and any audio inside the zips in `assets/` (list their contents; extract only into a scratch folder, never in place).

Identify:
- Music files
- Sound effects
- Ambient loops
- UI sounds
- Footsteps and movement
- Combat sounds
- Creature sounds
- Voice and vocal effects

Do not rely only on filenames. Listen to files when possible, read their metadata (for example with `ffprobe`), and create previews or contact sheets where they help (for example waveform or spectrogram images, or short preview clips, written to a scratch folder).

Do not modify or delete original files.

### Phase 2: Create an audio catalog

Create `docs/AUDIO_ASSET_CATALOG.md`.

For each useful asset, record:
- Filename and original location
- Audio category
- Duration
- Format and sample rate
- Whether it loops cleanly
- Its apparent mood and intended use
- Its suitability for The First Heresy
- Any known licence information

Put each asset in one of these groups:
- Excellent fit
- Possible fit after editing
- Poor fit
- Duplicate
- Unknown / needs listening

Do not invent licensing information. If a pack has no licence file or source page, write "unknown" and flag it.

### Phase 3: Identify missing audio

Create `docs/AUDIO_REQUIREMENTS.md`, starting from the required lists in §C below.

List the audio required for:
- Main menu
- Exploration
- Settlements
- Forests
- Dungeons
- Combat
- Boss battles
- Divine encounters
- Dialogue
- UI
- Character movement
- Weapons
- Magic
- Enemy attacks
- Enemy deaths
- Environmental ambience

For each category, explain what is already available (from the Phase 2 catalog) and what is missing. Mark which items belong to the vertical slice (the ✅ rows in §C).

### Phase 4: Establish the audio identity

Create `docs/AUDIO_STYLE_GUIDE.md`, building on `AUDIO_GUIDELINES.md` §1–4.

Define:
- Musical identity
- Instrumentation
- Sound design principles
- Ambient sound palette
- Combat audio direction
- Divine and cosmic horror sound direction
- UI sound direction
- Audio mixing principles (keep the loudness targets in `AUDIO_GUIDELINES.md` §4 unless the guide argues for a change)
- Music transition principles (they must work with the existing `MusicManager`: crossfades, battle `push`/`pop`, jingles)

Audio should be coherent across the whole game.

### Phase 5: Recommendations

Recommend additional asset packs only where there is a genuine gap from Phase 3. Start from the candidates in §B and check each one against the licence rules in §A.

Prioritise:
1. Free assets with explicit commercial-use permission
2. CC0 assets
3. Affordable packs with clear commercial licences

Record the original source and licence for every recommendation.

Do not download anything, buy anything, modify original files, or bring assets into the game without approval.

### Final output

Present to the user:
1. A summary of the existing audio assets
2. The strongest candidates for the game
3. The missing audio categories
4. The recommended external packs
5. A proposed initial audio library for the first playable vertical slice (mapped to the slice IDs in §C)

The user's approval of this output closes the analysis and starts Phase 6.

### Phase 6: Implement the audio (after approval)

Once the user has approved the final output:

1. **Sourcing:** the user obtains the approved packs (Phase 7A Step 0). The originals go untouched into `assests/audio_sources/`, with their licence or EULA files.
2. **Pipeline and hooks:** build the Phase 7A pipeline (`import_audio.py`, `build_audio.gd`, import settings, manifest rows) and wire the missing hooks (battle, level-up, rewards, field sounds, pause low-pass). These tasks can start before the files arrive.
3. **Integration:** assign the approved slice library to the hook-up points in §D. Normalise and mix it to the targets in `docs/AUDIO_STYLE_GUIDE.md` and `AUDIO_GUIDELINES.md` §4.
4. **Records:** fill in §E and `docs/asset_manifest.csv`, add CC BY credit lines to `CREDITS.md`, and set the §D gate status to met. Update `docs/AUDIO_ASSET_CATALOG.md` to show which assets are now used in the game.
5. **Verification:** the Phase 7A automated tests and manual checks pass.

Only assets the user approved in the final output are brought into the game. A pack that is not in the approved library needs a new approval first.

---

## A. Licence acceptance rules

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

## B. Candidate sources (to investigate; not downloaded)

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

## C. Required music and SFX

### Music (track list)

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

### SFX (slice minimum; full list by category in `AUDIO_GUIDELINES.md` §3)

`sfx_ui_move`, `sfx_ui_confirm`, `sfx_ui_cancel`, `sfx_ui_open` · `sfx_footsteps_{stone,grass,mud}_01..04` · `sfx_interact_chest_open` · `sfx_combat_{swing,hit,crit,miss}` · `sfx_magic_{cast,fire,heal}` · `sfx_enemies_{wolf_howl,skeleton_rattle,goblin_shriek}` · `amb_village_wind_loop`, `amb_graveyard_wind_crows_loop` · `sfx_reward_{gold,item}` · `sfx_progress_{levelup,save}`.

## D. Sourcing gate status (Milestone 1, 2026-11-17)

**Not met.** No audio was supplied before Phase 7, so the vertical slice runs silent (no placeholder tones, per the 2026-11-13 decision). The audit above, then sourcing and integration, are **Phase 7A: Audio setup** in `PROJECT_PLAN.md`, the next step. The rows marked "not wired yet" are built there too. Current hook-up points:

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

## E. Licence records (one row per file or per pack; fill in when added)

| Name | Creator | Source URL | Licence | Commercial use | Attribution required (exact credit line) | Format | Intended usage | Project path | Original kept at | Date added |
|---|---|---|---|---|---|---|---|---|---|---|
| _(empty: no audio yet)_ | | | | | | | | | | |

The machine-readable copy of these rows lives in `docs/asset_manifest.csv`. The test `test_asset_manifest.gd` fails if any file under `assets/audio/` lacks a row, or if a row has an empty licence field or `commercial_use = no`.
