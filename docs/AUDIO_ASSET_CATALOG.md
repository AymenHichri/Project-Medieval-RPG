# Audio Asset Catalog

_Phase 7A Step 0a, audit Phases 1–2 (brief: `AUDIO_CATALOG.md` → "Audit brief"). Written 2026-11-17. Research only: no original file was modified, no audio was brought into the game._

## How this audit was done

- **Searched:** `assets/audio/` (does not exist yet), every zip in `assests/`, `assests/audio_sources/` and `assests/later/` (31 zips), and the vendor packs under `assets/vendor/`. **Only the three packs in `assests/audio_sources/` contain audio.** No art pack ships any sound (the necropolis `godot/ambience/` folder is a lighting/time-of-day controller, not audio).
- **Extracted** copies to the session scratch folder only. The originals are untouched and still match `tools/source_assets.sha256`.
- **Measured** (no ffprobe in WSL; Python stdlib + the Windows `ffmpeg.exe` 4.2.3 bundled with ImageMagick):
  - RIFF chunks and metadata (`smpl` loop points, `acid` tempo, `bext`, `LIST/INFO`).
  - Integrated loudness, loudness range and true peak (EBU R128, `ffmpeg -af ebur128=peak=true`).
  - Loop seams: sample jump and level difference across the `smpl` loop points, or across file end → start.
  - Coarse spectrograms + 1 s envelopes (contact sheets), band energy split, spectral centroid, spectral flatness (tonal vs noisy).
  - Pulse strength: autocorrelation of the onset envelope (does it have a beat?).
- **Limitation (important):** the assistant cannot *listen*. Mood, instrumentation and "use" columns are inferred from the measurements, titles and spectrogram shapes. Every music rating is therefore **provisional until the user listens**; the listening checklist at the end lists what to confirm.

## Summary

| Pack (original) | Files | Content | Licence | Status |
|---|---|---|---|---|
| `Dark Fantasy Ambient Strings.zip` | 6 WAV (3 tracks × full + `_Loop` edit), 216 MB | Dark ambient string drones | **Dreamgarden free pack EULA** (Luis Ignacio Osores; PDF added to the zip 2026-11-17): commercial use and modification allowed, credit optional, no resale or re-upload | ✅ usable |
| `Tracks wav.zip` | 6 WAV, 157 MB | Dense dark orchestral/ambient pieces, 109–164 s | **AlkaKrab Music License** (PDF added to the zip 2026-11-17): commercial use allowed, credit optional; only timing/volume/EQ/transition edits; no redistribution as-is; open-source use needs permission | ✅ usable (edits limited) |
| `kenney_interface-sounds.zip` | 100 OGG, 0.8 MB | Synthetic UI clicks, chimes, whooshes | **CC0 1.0** (`License.txt` in the zip; Kenney, kenney.nl, "Interface Sounds 1.0", 2020-02-11) | ✅ usable; credit optional |

The two music packs had no licence file at first; the user added the licence PDFs to the zips the same day (the audio inside is byte-identical to what was audited).

**Used in the game (2026-11-17)**, mapped in `tools/audio_sources.csv`: `ForgottenSouls_Loop` → `mus_menu`; `SinisterBows_Loop` → `mus_dungeon_graveyard`; `ForsakenStrings_Loop` → `mus_battle` (interim); `6. Veil of Eternal Nightfall` → `mus_town_hamlet` (interim, loop edit); `MUS_Ambient_ForgottenSouls` (full) → `jng_victory` (0–7 s) and `jng_gameover` (its ending); Kenney `click_002/003/005` (focus), `confirmation_001`, `back_002–004`, `tick_001/002/004`, `drop_003`, `error_006`, `drop_002`, `pluck_001`, `bong_001`, `maximize_008`, `confirmation_004` → UI, reward, progression sounds and `jng_levelup`. After the first playtest ("the menu clicks feel off-theme") they are **darkened in the copies**: pitched down to 55–80 %, low-passed at 1.2–2.5 kHz, a short room echo on confirm/open/rewards (`filters` column of `tools/audio_sources.csv`).

## Group overview

| Group | Assets |
|---|---|
| **Excellent fit** | `MUS_Ambient_SinisterBows_Loop`, `MUS_Ambient_ForgottenSouls_Loop`, `MUS_Ambient_ForsakenStrings_Loop` (provisional: confirm by ear) |
| **Possible fit after editing** | All six `Tracks wav` pieces (need a loop edit: trim the decay tail, find a loop point); Kenney `back_*`, `click_001`, `select_002/005/007`, `confirmation_001`, `tick_*`, `bong_001`, `drop_002/003`, `error_005–008`, `switch_003–006`, `toggle_*` (play pitched down 10–20 % and quieter) |
| **Poor fit** | Kenney `open_*`, `close_*`, `maximize_*`, `minimize_*` (bright airy synth whooshes, centroid 4–13 kHz), `glitch_*` (digital), `glass_*` (bright chimes), `scroll_*` (1 s whirs), `question_*`, `scratch_*`, `pluck_002`, `select_008` |
| **Duplicate** | `MUS_Ambient_ForgottenSouls.wav`, `MUS_Ambient_ForsakenStrings.wav`, `MUS_Ambient_SinisterBows.wav` (full versions of the `_Loop` edits, which are better for the game). Kenney `minimize_00n` mirrors `maximize_00n` and `close_00n` mirrors `open_00n` (identical lengths: same sounds reversed) |
| **Unknown / needs listening** | The mood and instrumentation of all 12 music files (see the checklist); Kenney `pluck_001`, `bong_001` (as a reward/level-up accent?) |

---

## A. `Dark Fantasy Ambient Strings.zip`

Origin: `assests/audio_sources/Dark Fantasy Ambient Strings.zip` → folder `Dark Fantasy Ambient Strings/`. File dates 2026-10-07/08. Licence: **unknown (flagged)**.

All files: WAV PCM 24-bit, 44.1 kHz, stereo. The `_Loop` files carry a `smpl` chunk with one forward loop (Godot's WAV importer reads it with *Loop Mode: Detect From WAV*; for Ogg it becomes `loop_offset`).

Character shared by the pack: very low register (spectral centroid 125–200 Hz, nothing above ~3 kHz), strongly tonal (flatness 0.02–0.08), long sustained tones, tiny loudness range. Reads as **slow bowed low strings over a sub drone**: exactly the "dissonant strings / low drones / dark ambient" part of the palette.

| File | Duration | Loop | Loudness | Measured character | Apparent mood → intended use | Fit |
|---|---|---|---|---|---|---|
| `MUS_Ambient_SinisterBows_Loop.wav` | 101.8 s (intro 1.37 s + loop 100.5 s) | `smpl` loop; seam jump 1.7× a normal sample step, levels match (−24.0 / −23.8 dB): **clean** | −17.9 LUFS, TP −5.4 dB, LRA 2.8 | Quietest and darkest: 62 % of the energy below 80 Hz, steady envelope, no pulse | Oppressive, still, subterranean → **graveyard / crypt / dungeon** exploration under ambience | **Excellent** (provisional) |
| `MUS_Ambient_ForgottenSouls_Loop.wav` | 159.1 s (intro 2.87 s + loop 156.3 s) | `smpl` loop; jump 0.4×, levels −25.2 / −29.0 dB: **clean** | −14.5 LUFS, TP −4.5 dB, LRA 9.2 | Sub drone (48 % < 80 Hz) with a higher sustained line entering in the middle third and receding; no pulse; widest dynamics of the pack | Mournful, spectral, slowly evolving → **main menu**, story/sorrow moments, shrines | **Excellent** (provisional) |
| `MUS_Ambient_ForsakenStrings_Loop.wav` | 63.0 s (intro 0.87 s + loop 62.1 s) | `smpl` loop; jump 1.2×, levels −19.2 / −18.2 dB: **clean** | −13.9 LUFS, TP −4.0 dB, LRA 1.2 | **The only file with a clear regular pulse** (onset autocorrelation r = 0.58 at ≈ 109 BPM): a low-string ostinato (83 % of the energy 80–250 Hz) on a steady pedal; a dip roughly every 25 s | Tense, uneasy, forward-moving but restrained → **tension / danger zones**; the closest thing we have to **battle** music (too slow and quiet to be a real battle track) | **Excellent** for tension; **possible** as interim battle |
| `MUS_Ambient_SinisterBows.wav` | 202.3 s | No loop points; head −45 dB, tail −24 dB (cut, not faded) | −18.7 LUFS, TP −5.1 dB | Full version of the above | Same | **Duplicate**: use the `_Loop` edit |
| `MUS_Ambient_ForgottenSouls.wav` | 153.6 s | No loop points; ends with a fade (tail −43.6 dB) | −11.7 LUFS, TP −2.0 dB | Full version with natural ending | Same; a full-length cutscene version | **Duplicate** |
| `MUS_Ambient_ForsakenStrings.wav` | 134.4 s | No loop points; jump at end → start 56×: **would click** | −12.1 LUFS, TP −2.0 dB | Longer version (2 phrases) | Same | **Duplicate** |

## B. `Tracks wav.zip`

Origin: `assests/audio_sources/Tracks wav.zip` → folder `Tracks wav/`. File dates 2023-12-06 … 2024-01-22. `bext` chunk present with empty description/originator; `acid` chunk with a tempo tag (exported from a DAW). Licence: **unknown (flagged)**.

Shared character: dense, broadband-in-the-lows, strongly tonal, centroid 117–204 Hz; spectrograms show many simultaneous sustained partials with fine vertical striation (tremolo or textured articulation, **not** drums: no file has a measurable beat; pulse r ≤ 0.18 despite tempo tags of 70–120 BPM). Reads as **dark orchestral / dark-ambient compositions** with a beginning and an ending. None has loop points; most end with a 3–5 s decay to silence. Track 1 is 24-bit 48 kHz; the others are 16-bit 44.1 kHz (convert to one rate on import).

| File | Duration | Format | Loudness | Start / end | Measured character | Apparent use | Fit |
|---|---|---|---|---|---|---|---|
| `1. Whispers of the Abyss.wav` | 164.0 s | 24-bit 48 kHz | −17.1 LUFS, TP −3.4, LRA 2.8 | Starts at full level (−24 dB in the first 50 ms); 3 s decay | The flattest envelope of the pack; tempo tag 120 but no beat | Hypnotic, vast → **overworld** or alternative **menu** | Possible after editing |
| `2. Shadowforge Convergence.wav` | 108.8 s | 16-bit 44.1 kHz | −16.7 LUFS, TP −2.1, LRA 4.1 | Swells in; louder final section; 3 s decay | 67 % of energy 80–250 Hz; tag 86 BPM | Heavy, grinding → later **dungeon** (forge / mine), mid-boss | Possible after editing |
| `3. Eclipsed Desolation.wav` | 142.5 s | 16-bit 44.1 kHz | −16.7 LUFS, TP −1.7, LRA 4.1 | Starts from silence; 3 s decay | The darkest of the pack (centroid 117 Hz, 34 % sub) | Bleak, empty → alternative **graveyard**, ruins, `mus_story_dread` | Possible after editing |
| `4. Cursed Citadel .wav` | 131.2 s | 16-bit 44.1 kHz | −16.1 LUFS, TP −1.3, LRA 7.0 | Starts from silence; **no decay tail** (ends at −45 dB) | A clear break (near-silence) at ≈ 111 s, then a short coda; tag 75 BPM | Foreboding → castle / **cursed-kingdom dungeon**, boss approach | Possible after editing |
| `5. Dread March .wav` | 123.4 s | 16-bit 44.1 kHz | −16.8 LUFS, TP −3.4, LRA 7.4 | Builds from quiet over ≈ 20 s; 5 s decay | Widest dynamics (13.9 dB), the most low-mid presence (22 % 250–1 kHz: the most "melodic"); tag 70 BPM | Slow inexorable build → `mus_story_dread`, boss lead-in; its ending could be cut into **`jng_gameover`** | Possible after editing |
| `6. Veil of Eternal Nightfall.wav` | 112.0 s | 16-bit 44.1 kHz | −15.0 LUFS, **TP −0.7**, LRA 5.7 | Starts at full level; 3 s decay | The only one with a faint slow pulse (r 0.18 ≈ 45 BPM); loudest of the pack | Nocturnal, heavy → night exploration; **interim village** music (needs listening) | Possible after editing |

**Editing needed for any of these to loop:** cut the decay tail, pick a loop point on a phrase boundary, and either bake a short crossfade into the copy or rely on `loop_offset`. The AlkaKrab licence allows edits for timing and transitions (so loop edits), but not remixing or sampling: don't cut jingles or stingers out of these tracks.

## C. `kenney_interface-sounds.zip` (CC0)

Origin: `assests/audio_sources/kenney_interface-sounds.zip` → `Audio/*.ogg`. Ogg Vorbis, 44.1 kHz, mono except `drop`, `error`, `glitch`, `pluck`, `select`, `switch` (stereo). Every file is peak-normalised to about −1 dBFS, so they need −10 to −14 dB of `volume_db`. The character is clean and synthetic (designed for software UIs), so on its own it fights the "no chiptune / no bleeps" rule; the low, soft families work if played **pitched down 10–20 % and quietly**. That can be done with `SfxSet.pitch_range`/`volume_db`, without editing the files.

"Centroid" = spectral centroid of the loudest 46 ms (low = dull/soft, high = bright/airy).

| Family | Files | Length | Centroid | Character | Proposed use | Fit |
|---|---|---|---|---|---|---|
| `back` | 001–004 | 0.07–0.09 s | 240–530 Hz | Soft low thump | **`cancel`** (3 variants) | Possible after editing (pitch/volume) |
| `click` | 001 (+002–005: 10–20 ms micro-clicks) | 0.11 s | 99–490 Hz | Muted click | **`focus`** (001), micro-clicks as variants | Possible after editing |
| `select` | 001–008 | 0.06–1.95 s | 430–7300 Hz | 002/007 short, soft; 003–005 short tonal; 006 long; 008 bright | **`focus`** variants: 002, 007; 005 as an alternative confirm | Possible (002/005/007); poor (008) |
| `confirmation` | 001–004 | 0.29–0.56 s | 386–2500 Hz | 001 is low and short; 002–004 are brighter, longer chimes | **`confirm`**: 001 | Possible (001); poor (002–004) |
| `tick` | 001, 002, 004 | 0.02–0.06 s | 855–1480 Hz | Tiny dry tick | **`tick`** (typewriter), 3 variants + pitch | Possible after editing |
| `bong` | 001 | 0.13 s | 231 Hz | Low soft tone | Alternative `sfx_ui_open`, or a dull accent | Needs listening |
| `drop` | 001–004 | 0.13–0.29 s | 690–3100 Hz | 002/003 soft thuds | Alternative `sfx_ui_open`/close; equip in Phase 9 | Possible (002/003) |
| `error` | 001–008 | 0.10–0.56 s | 80–2000 Hz | 005–008 are low buzzes | `denied` (not in the slice; menus later) | Possible (005–008) |
| `switch`, `toggle` | 7 + 4 | 0.07–0.62 s | 86–4000 Hz | Mechanical switches | Settings check box / option change | Possible (switch_003–006); needs listening |
| `pluck` | 001–002 | 0.11–0.18 s | 1000–2000 Hz | Short plucked tone | Maybe `reward_item` accent | Needs listening (001); poor (002) |
| `open`/`close`, `maximize`/`minimize` | 4+4, 9+9 | 0.15–0.55 s | 3900–13500 Hz (except maximize/minimize 006/008) | Bright airy synth whooshes; each pair is the same sound reversed | — | **Poor fit** |
| `glass`, `glitch`, `scroll`, `question`, `scratch` | 6, 4, 5, 4, 5 | 0.01–1.02 s | wide | Glassy chimes, digital glitches, 1 s whirs | — | **Poor fit** |

## Listening checklist for the user (confirms the provisional ratings)

Listen with headphones and tick or correct each item; the result decides the final slice library.

1. `SinisterBows_Loop`: does it feel like a graveyard at night (cold, still) and not too busy under wind and crows?
2. `ForgottenSouls_Loop`: does the middle-section line sound like a theme? Is it right for the title screen, or too sad?
3. `ForsakenStrings_Loop`: is the ostinato tense enough to stand in for battle music for now, or is it clearly "exploration tension"?
4. `Tracks wav`, each piece: are there drums or choirs we did not detect? Is any of them warm enough for a sad village (`6. Veil of Eternal Nightfall` is the proposed interim)? Is any of them heroic or cinematic in a way the direction rejects?
5. Kenney `back_002`, `click_001`, `select_002`, `confirmation_001`, `tick_002`: pitched down ~15 %, do they sit with the painted dark UI, or do they still sound like a phone app?
