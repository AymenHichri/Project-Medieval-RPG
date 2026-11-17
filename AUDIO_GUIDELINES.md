# Audio Guidelines

> The audio identity is detailed and extended (cosmic and body horror, the three "layers" of the world, mixing lanes, transitions) in [`docs/AUDIO_STYLE_GUIDE.md`](docs/AUDIO_STYLE_GUIDE.md) (2026-11-17). Where it is more specific, it wins.

_Status: v2 (2026-11-17). Musical direction, sound categories, technical standards and the audio architecture. The architecture (§5) is implemented; the slice audio is integrated (Phase 7A, `AUDIO_CATALOG.md` §D)._

---

## 1. Direction

**One sentence:** the world sounds old, cold and hollow, with sparse warmth and dread that builds slowly.

- **Do:** orchestral and chamber fantasy, medieval instruments (hurdy-gurdy, nyckelharpa, viola da gamba, lute, recorder, frame drum, church bells), haunting solo strings, low choirs and solo voice, drones, restrained taiko/timpani in battle, generous reverb, silence as a tool.
- **Don't:** chiptune or arcade bleeps, bright major-key fanfares, EDM or dubstep, overly heroic Hollywood brass, comedic stingers, generic "coin" blips.
- **Dynamics:** exploration music sits quietly *under* ambience. Battle music is the energy peak. Boss and story tracks are the emotional peaks. A soft score leaves room for dread.

## 2. Music categories

| ID prefix | Category | Mood / instrumentation | Tempo | Loop | Slice? |
|---|---|---|---|---|---|
| `mus_main_theme` | Main theme | The game's leitmotif; solo cello or viol + low choir, building to strings | 60–80 | Yes | — |
| `mus_menu` | Main menu | Leitmotif variant, sparse, bells and drone | 50–70 | Yes | ✅ |
| `mus_town_*` | Village / town | Melancholic folk: lute, recorder, hurdy-gurdy; safe but sad | 70–90 | Yes | ✅ |
| `mus_overworld` | Overworld exploration | Wandering, open fifths, strings and frame drum | 70–90 | Yes | — |
| `mus_forest` | Forest | Unsettling woodwinds, creaks, distant voices | 60–80 | Yes | — |
| `mus_dungeon` | Dungeon / crypt / caves | Drones, low strings, reversed textures, occasional bell | 40–60 | Yes | ✅ (graveyard) |
| `mus_battle` | Regular battle | Driving low strings, taiko, choir stabs; minor key; 60–120 s loop | 120–150 | Yes | ✅ |
| `mus_boss` | Boss battle | Full choir, organ, heavy percussion; leitmotif in minor | 130–160 | Yes | — |
| `mus_story_*` | Story moments | Solo instrument, sorrowful, sometimes no percussion | free | Optional | — |
| `jng_victory` | Victory | Short (4–8 s) solemn resolve, **not** a cheerful fanfare | — | No | ✅ |
| `jng_gameover` | Game over | Descending strings / tolling bell, 6–10 s, then silence or a drone loop | — | No → loop | ✅ |
| `jng_levelup` | Level up | 1–2 s bell shimmer | — | No | ✅ |

## 3. Sound effect library categories

| Category | Folder | Examples | Slice minimum |
|---|---|---|---|
| UI | `sfx/ui/` | move, confirm, cancel, error/denied, open/close menu, page turn, buy/sell | move, confirm, cancel, open |
| Footsteps | `sfx/footsteps/` | stone, grass, mud, wood, bone; 4–6 variants each, keyed to TileSet custom data `surface` | stone, grass, mud |
| Doors and chests | `sfx/interact/` | wooden door, iron gate, chest open/locked, lever, sarcophagus lid | chest open |
| Weapons and impacts | `sfx/combat/` | sword swing/hit/crit, blunt hit, claw, bite, shield block, miss/whoosh, body fall | swing, hit, crit, miss |
| Magic | `sfx/magic/` | cast charge, fire, frost, lightning (crack + rumble), holy, shadow, heal, buff, debuff | cast, fire, heal |
| Enemies | `sfx/enemies/` | wolf growl/howl/yelp, goblin chatter/shriek, skeleton rattle/collapse, boss breath/laugh | wolf howl, skeleton rattle, goblin shriek |
| Ambience (loops) | `amb/` | village wind and dogs, graveyard wind and crows, crypt drips, forest night, fire crackle (positional) | village, graveyard |
| Weather | `amb/weather/` | light/heavy rain, thunder (sync with the lightning FX), wind gusts, snow hush | — |
| Loot and rewards | `sfx/reward/` | gold pickup, item get, rare drop, key item | gold, item |
| Progression | `sfx/progress/` | level up (with `jng_levelup`), skill learned, quest updated, save | level up, save |

## 4. Technical standards

| Topic | Standard |
|---|---|
| Formats | **Music and ambience: Ogg Vorbis** (`.ogg`, quality ~0.6–0.7). **SFX: WAV** 16-bit PCM (instant start, imported as `AudioStreamWAV`). No MP3 |
| Sample rate | 44.1 kHz (or 48 kHz consistently, never mixed in one category) |
| Channels | Music and ambience stereo. World SFX **mono** (for `AudioStreamPlayer2D` panning). UI SFX mono or stereo |
| Loudness | Music around **−18 LUFS** integrated, ambience around −24 LUFS, SFX peaks ≤ −1 dBTP. Normalise before import (e.g. in Audacity) |
| Loops | Ogg: set `loop = true` and `loop_offset` in Import (intro → loop body). WAV ambience: loop points in Import. Every loop is checked for clicks at the seam |
| Length | UI SFX ≤ 0.3 s; impacts ≤ 1 s; battle music loop ≥ 60 s to avoid fatigue |
| Naming | `mus_<category>_<name>.ogg`, `amb_<place>_<name>_loop.ogg`, `sfx_<category>_<name>_<nn>.wav` (e.g. `sfx_footsteps_stone_03.wav`) |
| Folders | `assets/audio/{music,ambience,sfx/<category>}/` + `LICENSE` notes per source folder |
| Originals | Original downloads (zip plus licence) are kept untouched in `assests/audio_sources/`; only processed copies go into `assets/audio/` |
| Variation | Every frequent SFX has ≥ 3 variants or ±5% random pitch, so repeats don't sound mechanical |

## 5. Audio architecture (implemented in Phases 1, 6, 7 and 7A; weather and the full library in Phase 12)

To keep the project's "5 autoloads" rule, there is **one** `AudioManager` autoload that **composes** the three requested managers as child nodes with their own `class_name`. Each manager has one job and its own tests.

```
AudioManager (autoload, Node)               # thin facade: AudioManager.music / .sfx / .ambience
├── MusicManager (Node)                     # scripts/audio/music_manager.gd
│     PlayerA, PlayerB : AudioStreamPlayer  # crossfade pair, bus "Music"
├── SFXManager (Node)                       # scripts/audio/sfx_manager.gd
│     UiPool   : 6 × AudioStreamPlayer      # bus "UI"
│     WorldPool: 12 × AudioStreamPlayer2D   # bus "SFX" (positional)
└── AmbientAudioManager (Node)              # scripts/audio/ambient_audio_manager.gd
	  Layers   : up to 4 × AudioStreamPlayer # bus "Ambience" (looping beds)
```

**Bus layout** (`default_bus_layout.tres`):
```
Master
├── Music
├── Ambience      (light low-pass when the pause menu is open)
├── SFX           (Reverb send: "SFX_Reverb" for crypts/dungeons, toggled per map)
└── UI
```
Settings expose **Master, Music, SFX (incl. UI), Ambience** sliders. Values are stored as linear 0–1 in `user://settings.cfg` and applied with `linear_to_db`.

**Data Resources**

| Resource | Fields |
|---|---|
| `MusicTrack` | `stream: AudioStream`, `volume_db`, `resume_on_return: bool`, `fade_in`, `fade_out` |
| `SfxSet` | `streams: Array[AudioStream]` (variants), `volume_db`, `pitch_range: Vector2`, `cooldown_ms` (prevents stacking), `bus` |
| `AmbienceProfile` | `layers: Array[AmbienceLayer]` (`stream`, `volume_db`, `random_oneshots: Array[AudioStream]`, `oneshot_interval: Vector2`) |

Each `Map` exports `music: MusicTrack` and `ambience: AmbienceProfile`. Each `EncounterTable` and `BossEncounter` exports `music: MusicTrack`.

**MusicManager API and behaviour**
- `play(track, fade := 1.0)`: crossfade from the current player to the other one. If the same track is already playing, do nothing.
- `push(track, fade := 0.4)`: **battle start**. Store the current track and its playback position, then crossfade to the battle track.
- `pop(fade := 1.5)`: **battle end**. Crossfade back to the stored track and resume at the stored position if `resume_on_return`.
- `play_jingle(stream)`: duck or stop the music, play a non-looping jingle (victory, level up), and emit `jingle_finished`.
- `stop(fade)`.
- Flow: exploration → `push(battle)` → victory → `play_jingle(victory)` → results screen → `pop()` → exploration resumes where it left off. On defeat: `play(gameover)`.

**SFXManager API and behaviour**
- `play_ui(set: SfxSet)` and `play_at(set: SfxSet, world_pos: Vector2)`.
- Picks the next free player in the pool. If all are busy, it steals the oldest **non-UI** voice, and UI sounds are never dropped.
- Applies random variant, random pitch and the per-set cooldown.
- The footstep helper `play_footstep(surface: StringName, pos)` reads the TileSet custom data `surface`.

**AmbientAudioManager API and behaviour**
- `set_profile(profile, fade := 2.0)`: crossfade each layer on map change. Layers present in both profiles keep playing seamlessly.
- Random one-shots (crow caw, distant bell) are scheduled with a timer within `oneshot_interval`.
- `set_weather_layer(stream | null)` is driven by the vendor WorldWeather / ambience presets.
- During battle the ambience is lowered by 12 dB, and restored afterwards.

**Rules**
- No scene creates its own `AudioStreamPlayer` for music or ambience. Everything goes through `AudioManager`.
- Local positional loops (a crackling bonfire) **may** use their own `AudioStreamPlayer2D` on the `Ambience` bus, with a max distance set.
- All audio references in code are `SfxSet` or `MusicTrack` Resources. **No hardcoded file paths.**
- No placeholder tones in the game (decision 2026-11-13): tests use in-memory silent `AudioStreamWAV`s, and a hook without a file is silent.
- **Pipeline (Phase 7A):** originals in `assests/audio_sources/` → `tools/audio_sources.csv` (one row per target: cut, loop, fades, loudness) → `tools/import_audio.py` (ffmpeg; writes `assets/audio/` and the Ogg loop settings in the `.import` files) → `tools/build_audio.gd` (generates `data/audio/music/*.tres`, `data/audio/sfx/*.tres` and `sfx_library.tres`, with per-ID volume, pitch and cooldown) → hook-up points (`AUDIO_CATALOG.md` §D). The processed copies are not committed (licences forbid redistribution; the repository is public).

## 6. Testing standards

- Unit tests run with fade durations of 0 and placeholder streams. They never depend on wall-clock time.
- `test_music_manager.gd`: crossfade leaves exactly one player audible; `push`/`pop` restores the track and position (± one mix chunk); a jingle emits `jingle_finished`.
- `test_sfx_manager.gd`: the pool never exceeds its size; UI voices are never stolen; the cooldown suppresses duplicates; the pitch stays inside `pitch_range`.
- `test_ambient_manager.gd`: profile switch keeps shared layers playing and fades out removed ones; one-shot scheduling respects the interval (seeded).
- `test_audio_buses.gd`: buses Master/Music/Ambience/SFX/UI exist with the correct routing; settings round-trip through `settings.cfg`.
- `test_asset_manifest.gd`: every file under `assets/audio/` has a complete licence row (see `AUDIO_CATALOG.md`).
- **Manual (each milestone):** play with headphones and speakers; no clipping, no loop clicks, music never masks UI feedback, and volume sliders respond immediately.
