# Audio Requirements

_Phase 7A Step 0a, audit Phase 3 (brief: `AUDIO_CATALOG.md` → "Audit brief"). Written 2026-11-17. Starts from the required lists in `AUDIO_CATALOG.md` §C and `AUDIO_GUIDELINES.md` §2–3, and checks each item against what exists (`docs/AUDIO_ASSET_CATALOG.md`)._

**Legend.** Slice ✅ = needed for the vertical slice (Milestone 1 + Phase 7A). Status: **Have** = a good candidate exists; **Interim** = a usable stand-in exists but the real thing should be sourced; **Gap** = nothing usable exists. "Strings" = `Dark Fantasy Ambient Strings.zip`, "Tracks" = `Tracks wav.zip`, "Kenney" = `kenney_interface-sounds.zip` (CC0). Licences of all three packs are recorded (`AUDIO_CATALOG.md` §E).

## At a glance (slice only)

| Area | Slice IDs | Have | Interim | Gap |
|---|---|---|---|---|
| Music | 4 loops + 3 jingles | 2 (`mus_menu`, `mus_dungeon_graveyard`) | 2 (`mus_battle`, `mus_town_hamlet`) | 3 jingles |
| UI | 5 sets | 4 (`focus`, `confirm`, `cancel`, `tick`) | 1 (`sfx_ui_open`) | — |
| Footsteps | 3–4 surfaces | — | — | all |
| Combat, magic, enemies | 4 + 3 + 3 (+ new hook sets) | — | — | all |
| Ambience | 2 beds + pyre crackle | — | — | all |
| Rewards, progression | 4 | — | — | all |

**Conclusion:** music is mostly covered (licences pending); UI is covered by Kenney; **all world SFX and ambience are missing.** That is where the sourcing effort goes.

---

## 1. Main menu
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `mus_menu` | ✅ | Sparse leitmotif variant, drone, 50–70 BPM, loop | Strings `ForgottenSouls_Loop` (alt: Tracks `1. Whispers of the Abyss`) | **Have** (licence pending) |
| `mus_main_theme` | — | The game's leitmotif | Nothing written as a theme | Gap (later; commission candidate) |
| UI on the title | ✅ | Same UI set as everywhere | Kenney (see §9) | Have |

## 2. Exploration (overworld)
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `mus_overworld` | — | Wandering, open fifths, strings + frame drum | Tracks `1. Whispers of the Abyss` (after loop edit) | Interim |

## 3. Settlements
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `mus_town_hamlet` | ✅ | Melancholic **folk**: lute, recorder, hurdy-gurdy; "safe but sad" | Nothing folk. Stand-in: Tracks `6. Veil of Eternal Nightfall` (loop edit; needs listening) | **Interim → source a folk track** |
| `amb_village_wind_loop` | ✅ | Wind, distant dog, creaking sign, faint bell | — | **Gap** |
| Later: tavern, church, market | — | | — | Gap |

## 4. Forests
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `mus_forest` | — | Unsettling woodwinds, creaks, distant voices | — | Gap |
| `amb_forest_night_loop` | — | Insects, owl, branches, wind in leaves | — | Gap |

## 5. Dungeons (graveyard, crypts)
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `mus_dungeon_graveyard` | ✅ | Drones, low strings, 40–60 BPM, loop | Strings `SinisterBows_Loop` (alt: Tracks `3. Eclipsed Desolation`) | **Have** (licence pending) |
| `amb_graveyard_wind_crows_loop` | ✅ | Wind bed + crow one-shots (+ distant bell one-shot) | — | **Gap** |
| Bone pyre crackle (positional) | ✅ (7A hook) | Fire crackle loop, mono | — | **Gap** |
| `mus_dungeon_*` (later dungeons) | — | | Tracks `2. Shadowforge Convergence`, `4. Cursed Citadel` | Interim |
| `amb_crypt_drips_loop` | — | Drips, low room tone | — | Gap |

## 6. Combat (regular battles)
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `mus_battle` | ✅ | Driving low strings, taiko, choir stabs, 120–150 BPM, loop ≥ 60 s | Nothing driving. Stand-in: Strings `ForsakenStrings_Loop` (≈109 BPM ostinato, 62 s loop) | **Interim → source a battle track** |
| `jng_victory` | ✅ | 4–8 s solemn resolve, not a fanfare | — | **Gap** |
| `jng_gameover` | ✅ | 6–10 s descending strings / tolling bell | Could be cut from the ending of Tracks `5. Dread March` (if its licence allows edits) | **Gap** (or edit) |
| `battle_flee` | (7A hook) | Hurried footsteps / cloth whoosh | — | Gap |
| `combat_defend` | (7A hook) | Shield brace, metal | — | Gap |

## 7. Boss battles
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `mus_boss_assassin` | — | Choir, organ, heavy percussion, leitmotif in minor | Nothing with percussion; Tracks `2. Shadowforge Convergence` (heavy, grinding) used as the interim since Phase 10 | Interim (commission candidate) |
| Boss vocalisations | — | Breath, laugh, blade sounds | — | Gap (Phase 10 hooks: the boss visuals' `cry_sfx` / `death_sfx` stay empty) |

## 8. Divine encounters (forgotten gods, cosmic horror)
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `mus_divine_*` | — | Distant choirs, wrong-sounding intervals, sub drones | Strings `ForgottenSouls_Loop` can carry a shrine scene for now | Gap (later) |
| `sfx_divine_presence`, whispers, risers | — | Reversed choirs, granular voices, sub swells | — | Gap |

## 9. Dialogue
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `tick` (typewriter) | ✅ | Tiny dry tick, ≥ 3 variants | Kenney `tick_001/002/004` | **Have** |
| Advance / choice | ✅ | Uses UI `confirm`/`focus` | Kenney | Have |
| `mus_story_sorrow`, `mus_story_dread` | — | Solo instrument; slow build | Strings `ForgottenSouls_Loop` (sorrow), Tracks `5. Dread March` (dread) | Interim (in use since Phase 10, dialogue `music` key) |

## 10. UI
| ID / set key | Slice | Need | Available (Kenney, played −10 to −14 dB and 10–20 % lower) | Status |
|---|---|---|---|---|
| `ui.focus` (`sfx_ui_move`) | ✅ | Soft, ≤ 0.1 s, ≥ 3 variants | `select_002`, `select_007`, `click_001` | **Have** |
| `ui.confirm` | ✅ | Low, short | `confirmation_001` (alt `select_005`) | **Have** |
| `ui.cancel` | ✅ | Soft thump | `back_002`, `back_003`, `back_004` | **Have** |
| `sfx_ui_open` (pause menu) | ✅ | Book / cloth / low tone | `bong_001` or `drop_003` (needs listening); a page-turn or leather foley would fit better | Interim |
| `denied`, settings toggles | — | | `error_005–008`, `switch_003–006` | Have (later) |
| Buy/sell, equip | — | | `drop_002/003` (equip); coins missing | Gap (Phase 9) |

## 11. Character movement
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `footsteps.stone` | ✅ | 4–6 variants, mono, short | — | **Gap** |
| `footsteps.grass` | ✅ | 4–6 variants | — | **Gap** |
| `footsteps.mud` | ✅ | 4–6 variants | — | **Gap** |
| `footsteps.ash` | (key exists) | Falls back to `stone` if missing | — | Gap (optional) |
| Armour jingle / cloth layer | — | Knight chainmail layer | — | Gap |

## 12. Weapons
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `sfx_combat_swing` | ✅ | Sword whoosh, ≥ 3 variants | — | **Gap** |
| `sfx_combat_hit` | ✅ | Blade into flesh / armour | — | **Gap** |
| `sfx_combat_crit` | ✅ | Heavier hit + bass thump | — | **Gap** |
| `sfx_combat_miss` | ✅ | Whoosh past + nothing | — | **Gap** |
| Bone hit (skeleton `hit_sfx`) | ✅ (7A hook) | Dry bone crack | — | **Gap** |

## 13. Magic
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `sfx_magic_cast` | ✅ | Charge / whisper riser | — | **Gap** |
| `sfx_magic_fire` (Ember) | ✅ | Ignite + burn | — | **Gap** |
| `sfx_magic_heal` (Minor Heal, potion) | ✅ | Soft shimmer, **not** sparkly-cute | — | **Gap** |
| Frost, lightning, holy, shadow, buffs | — | | — | Gap (Phase 8+) |

## 14. Enemy attacks
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| Wolf bite/claw | ✅ (as `attack_sfx`) | Snap + growl | — | **Gap** |
| Goblin Scout stab | ✅ | Dagger swish | — | **Gap** (can reuse `combat_swing`) |
| Skeleton swing | ✅ | Rusty blade swing | — | **Gap** (can reuse `combat_swing`) |
| `sfx_enemies_wolf_howl` (cry) | ✅ | Howl / snarl | — | **Gap** |
| `sfx_enemies_goblin_shriek` (cry) | ✅ | Shriek / chatter | — | **Gap** |
| `sfx_enemies_skeleton_rattle` (cry) | ✅ | Bone rattle | — | **Gap** |

## 15. Enemy deaths
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| Wolf yelp, goblin death cry, skeleton collapse | ✅ (as `death_sfx`) | One per enemy family; the Charred Skeleton reuses the skeleton set | — | **Gap** |

## 16. Environmental ambience
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| Village bed | ✅ | See §3 | — | **Gap** |
| Graveyard bed + crow/bell one-shots | ✅ | See §5 | — | **Gap** |
| Weather (rain, thunder, gusts) | — | Synced with the vendor WorldWeather FX | — | Gap (Phase 12) |

## 17. Rewards and progression (from §C)
| ID | Slice | Need | Available | Status |
|---|---|---|---|---|
| `jng_levelup` | ✅ | 1–2 s bell shimmer | — | **Gap** |
| `sfx_progress_levelup` | ✅ | Accent on the "reached level N" line | — | **Gap** (can be the same bell) |
| `sfx_reward_gold` | ✅ | Coins, dull not "blip" | — | **Gap** |
| `sfx_reward_item` | ✅ | Soft pouch / item accent | Kenney `pluck_001` (needs listening) | Gap / interim |
| `sfx_progress_rest` (well) | ✅ (7A hook) | Water + soft chord | — | **Gap** |
| `sfx_progress_save`, `sfx_interact_chest_open` | (§C) | | — | Gap (no save or chest in the slice; Phases 9/11) |

---

## Sourcing shopping list (slice gaps only)

| # | Need | Count | Best-fit source type (R1–R7 in the next section) |
|---|---|---|---|
| 1 | Footsteps stone, grass, mud (+ ash) | 12–24 files | CC0 foley pack |
| 2 | Weapon swing, hit, crit, miss, bone hit, defend, flee | 7 sets × 3 | Pro SFX library |
| 3 | Magic cast, fire, heal | 3 sets | Pro SFX library |
| 4 | Wolf, goblin, skeleton: cry + death (+ wolf bite) | 6–7 sets | Pro SFX library / CC0 creature recordings |
| 5 | Village bed, graveyard bed, crow and bell one-shots, fire crackle | 2 loops + 3 one-shot sets + 1 loop | Pro ambience library |
| 6 | Coins, item, level-up bell, rest | 4 sets | CC0 foley + bell recording |
| 7 | Battle music loop | 1 | Music pack / CC0 track |
| 8 | Folk village music loop | 1 | Music pack / CC BY track |
| 9 | Victory, game over, level-up jingles | 3 | Jingle pack, or edits of owned tracks |

---

## Recommended sources for the gaps (audit Phase 5)

Only for genuine gaps above. Ordered by the brief's priorities (free with commercial permission → CC0 → affordable paid). Checked 2026-11-17 against `AUDIO_CATALOG.md` §A. **Nothing has been downloaded.** Re-check every licence at download time and keep the licence file next to the zip in `assests/audio_sources/`.

| # | Covers gaps | Source | Licence (as checked) | Cost | Notes |
|---|---|---|---|---|---|
| R1 | Footsteps (1), weapon foley, coins (6), impacts | **Kenney "Impact Sounds"** (130 files), kenney.nl/assets/impact-sounds | CC0 (shown on the page) | Free | Same author and licence as the UI pack we have. The page doesn't list the files, so check for stone/grass coverage after download; **mud is probably missing** (→ R3) |
| R2 | Footsteps, cloth, coins, weapon draw/swing, book/page (UI `open`) | **Kenney "RPG Audio"** (50 files), kenney.nl/assets/rpg-audio | CC0 (shown on the page) | Free | Tagged foley/footstep/weapon. Small and coherent; a good first download |
| R3 | Ambience beds, crows, wind, fire crackle (5), monster cries and deaths (4), magic (3), weapon hits, bells (level-up) | **Sonniss "GameAudioGDC" bundles** (archive 2015–2024 and GDC 2026), sonniss.com/gameaudiogdc | Royalty-free, commercial use allowed, **no attribution required** (per the page). **Restrictions:** no redistribution of the original *or edited* files as sounds; **no AI/ML training**; media production only | Free | The best fit for the realistic, heavy foley this direction needs. Tens of GB: download only the parts with the libraries we need. **The redistribution clause means the repository must stay private** (or `assets/audio/` stays out of any public repo). Read the full licence at /gdc-bundle-license/ before use |
| R4 | Specific creature sounds (wolf howl, goblin-like shriek), crows, church bells | **Freesound.org**, filtered to **CC0** (CC BY acceptable with a credit line) | Per file. **Reject CC BY-NC** | Free | Use only to fill what R1–R3 miss. Record each file's URL and author |
| R5 | Battle music (7) | **OpenGameArt "Fantasy – Battlegrounds"** (dark fantasy, strings + percussion, "for encountering enemies") | Reported as **CC0** in search results; **the page could not be opened automatically (HTTP 403), so verify it there** | Free | The only free candidate found that matches "driving strings + percussion". Alternative: a paid dark-fantasy battle pack on itch.io with a written commercial licence |
| R6 | Folk village music (8) | **Alexander Nakarada (Serpent Sound Studios), "Celtic Fantasy"** category | CC BY 4.0 according to a third-party credit list; **verify on each track's page** | Free (attribution) | Needs an exact credit line in `CREDITS.md`. Widely used, so some players will recognise it. Pick the sparest, saddest track (lute/whistle, no jolly jig) |
| R7 | Jingles (9) | **A:** edit owned tracks once their licence is known (game over = the last 8 s of `5. Dread March`; victory = a cadence from `ForgottenSouls`). **B:** OpenGameArt CC0 collection by "Joth" (includes victory and game-over pieces; verify each). **C:** "L.A.A. Orchestral Victory Jingles Pack #1" (itch.io, $5+; licence not shown, so verify) | A: depends on the unknown licence; B: CC0 (verify); C: unknown | Free / $5 | `jng_levelup` is better as a **bell SFX** (1–2 s) from R3/R4 than as music |
| — | Anything left | AI-generated SFX (Q15) | Provider-dependent | — | **Not recommended** (Q15 default: no). Revisit only if gaps remain after R1–R4 |

### Licences of the two music packs: resolved

The user added the licence PDFs to both zips on 2026-11-17 (Dreamgarden free pack EULA; AlkaKrab Music License). Both allow commercial use in a game. See `AUDIO_CATALOG.md` §E.

### User decision (2026-11-17): use only the supplied packs

R1–R7 above are **not** being pursued: no further audio is downloaded. The slice uses the supplied packs only (as built: `AUDIO_CATALOG.md` §D). The gaps stay open, with their hooks built and silent: footsteps, combat, magic and monster sounds, ambience beds, the pyre crackle, a real battle track and folk village music. R1–R7 remain the recommendation if the decision changes.

---

## Proposed initial slice library

Mapped to the slice IDs in `AUDIO_CATALOG.md` §C and the hook-up points in §D. "Own" = already in `assests/audio_sources/`.

| Slice ID | Proposed asset | From | Treatment on import |
|---|---|---|---|
| `mus_menu` | `MUS_Ambient_ForgottenSouls_Loop.wav` | Own (licence pending) | Ogg, gain to −18 LUFS (≈ −3.5 dB), `loop_offset` 2.87 s |
| `mus_town_hamlet` | Folk track from R6; **interim** `6. Veil of Eternal Nightfall.wav` | R6 / own | Interim: trim the 3 s tail, choose a loop point, −3 dB |
| `mus_dungeon_graveyard` | `MUS_Ambient_SinisterBows_Loop.wav` | Own (licence pending) | Ogg, ≈ −0.1 dB, `loop_offset` 1.37 s |
| `mus_battle` | R5 "Battlegrounds"; **interim** `MUS_Ambient_ForsakenStrings_Loop.wav` | R5 / own | Interim: Ogg, ≈ −4 dB, `loop_offset` 0.87 s |
| `jng_victory` | R7 | R7 | ≤ 8 s, −18 LUFS in the file |
| `jng_gameover` | R7 (option A: end of `5. Dread March`) | R7 / own | ≤ 10 s, natural fade |
| `jng_levelup` | Short bell (1–2 s) | R3 / R4 | −18 LUFS in the file |
| `ui.focus` | Kenney `select_002`, `select_007`, `click_001` | Own (CC0) | WAV mono; `volume_db` ≈ −12, `pitch_range` 0.82–0.92 |
| `ui.confirm` | Kenney `confirmation_001` | Own (CC0) | ≈ −12 dB, pitch 0.85–0.9 |
| `ui.cancel` | Kenney `back_002`, `back_003`, `back_004` | Own (CC0) | ≈ −12 dB, pitch 0.85–0.95 |
| `ui.tick` | Kenney `tick_001`, `tick_002`, `tick_004` | Own (CC0) | ≈ −18 dB, pitch 0.9–1.0 |
| `sfx_ui_open` | Page/book foley from R2; **interim** Kenney `bong_001` | R2 / own | ≈ −12 dB |
| `footsteps.{stone,grass,mud}` | R1 / R2 footsteps; mud from R3 | R1–R3 | 4–6 variants each, mono, pitch ±5 % |
| `sfx_combat_{swing,hit,crit,miss}`, bone hit, defend, flee | R3 (weapons library), R2 for swings | R2 / R3 | ≥ 3 variants each |
| `sfx_magic_{cast,fire,heal}` | R3 | R3 | — |
| `sfx_enemies_*` (cry + death for wolf, goblin, skeleton) | R3, gaps from R4 | R3 / R4 | Charred Skeleton = skeleton set, lower pitch |
| `amb_village_wind_loop`, `amb_graveyard_wind_crows_loop` (+ crow, bell one-shots) | R3 ambience libraries, crows from R4 if needed | R3 / R4 | −24 LUFS beds, seamless loops |
| Pyre crackle (positional) | R3 fire loop | R3 | Mono loop, `AudioStreamPlayer2D` |
| `sfx_reward_{gold,item}`, `sfx_progress_{levelup,rest}` | R1/R2 coins and pouch; bell from R3/R4; water from R3 | R1–R4 | — |
