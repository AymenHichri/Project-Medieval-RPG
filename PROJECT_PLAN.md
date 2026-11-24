---
date: 2026-11-13
git_commit: none (workspace is not yet a git repository)
branch: none
topic: "Dark Fantasy JRPG — Godot 4.6 project plan"
tags: [plan, godot, jrpg, architecture, battle-system, exploration, encounters]
status: draft — awaiting user approval
---

# Dark Fantasy JRPG — Project Plan

> **Status: DRAFT for review.** No gameplay has been implemented. No downloaded asset has been modified, moved, renamed or deleted. Implementation starts only after explicit approval.
> Companion document: [`ASSET_ANALYSIS.md`](ASSET_ANALYSIS.md) (full inventory, classifications, licences).

## Decisions already confirmed by the user

| # | Decision | Choice |
|---|---|---|
| D1 | Engine version | **Upgrade to Godot 4.6.x stable** (installed 4.1.2 cannot load the vendor TileSets) |
| D2 | Visual direction | **HD painted 2D sprites, dark medieval**: not hard-edged pixel art. Future assets must match. |
| D3 | Battle sprite facing | **E row for the party (facing right), W row for enemies (facing left)** |
| D4 | Exploration movement | **Free 8-direction movement** (not grid-locked) |
| D5 | Font | **Alegreya** (SIL OFL), files to be supplied by the user |
| D6 | UI art | **Gimble's Dark Fantasy Kit Sampler** (`Gimbles_Dark_Fantasy_Kit_Sampler_Free_v1.0.zip`), using the vendor-supplied **2×** files, **combined with** the `dfgui` kit (`All Assets.zip`), upscaled ×2 (nearest) to the same pixel size, for what Gimble's lacks (MP/XP bar fills, command icons, round portrait frames, MENU button, map icons) |
| D7 | Phase order | Outline accepted: battle logic **before** encounters; vertical slice at Phase 7 |
| D8 | UI, typography and audio identity | Dedicated planning added (user requirement). Typography: **Alegreya** (body, confirmed) + **Cinzel** (titles/names, recommended); Press Start 2P evaluated and not recommended. Audio: one `AudioManager` autoload composed of `MusicManager`, `SFXManager` and `AmbientAudioManager`. Details in the supporting documents below |

### Supporting documents (part of this plan)
| Document | Content |
|---|---|
| `ASSET_ANALYSIS.md` | Inventory and classification of all downloaded packs |
| `ART_GUIDELINES.md` | Visual pillars, the two art layers (painted world / pixel interface), semantic colour palette, UI styling, typography summary, consistency checklist |
| `UI_ASSET_CATALOG.md` | UI pack licence records, file inventory, required UI component → asset → gap mapping |
| `FONT_CATALOG.md` | Cinzel / Alegreya / Press Start 2P evaluation: licence, coverage, readability, Godot Theme setup |
| `AUDIO_GUIDELINES.md` | Musical direction, SFX categories, technical standards, audio architecture design, audio tests |
| `AUDIO_CATALOG.md` | Audio asset audit and implementation brief (Phase 7A Step 0a), licence acceptance rules, candidate sources, required track/SFX lists, hook-up table, licence record table |
| `docs/asset_manifest.csv` (Phase 1) | Machine-readable licence record per external file. Checked by `test_asset_manifest.gd` |

---

## 1. Executive overview

An original, solo-developed 2D JRPG in Godot 4.6 with typed GDScript. It follows the classic Dragon Quest *structure*: explore towns and dangerous regions, random encounters, turn-based round combat, levelling and loot. Its identity is a serious, mysterious dark medieval world: abandoned kingdoms, necropolises, cursed wilds.

- **Exploration:** a three-quarter top-down view (~30°) built from SovDigital HD tilesets at a 128 px grid. The Knight moves freely in 8 directions, and the camera is zoomed out to about 20×11 tiles.
- **Combat:** side-view, round-based (DQ-style: choose all commands, then everyone acts in speed order). The party is on the left facing right and enemies are on the right facing left. The **battle logic is a pure GDScript layer with no Nodes**, fully unit-tested headless. The presentation layer only replays the events that logic produces.
- **Data-driven content:** characters, enemies, skills, items, equipment, status effects, encounter tables and quests are `.tres` Resources. Dialogue is JSON.
- **Scope discipline:** the first milestone is a **vertical slice**: one hero, one village, one dangerous area, one NPC conversation, random encounters with three enemy types, a complete battle, and rewards. Everything after that is incremental.

**Strengths of the current assets:** a high-quality hero (Knight), three regular enemies with colour variants, a two-phase boss, three environment kits (village, castle courtyard, necropolis), weather and ambience tools, and the Gimble's dark-fantasy UI kit (panels, buttons, bars, cursors, item and status icons, 6 portraits, 2 side-view battle backgrounds).
**Biggest gaps:** audio, NPC/villager sprites, a party beyond the Knight, forest/cave/dungeon tiles, cast/defend/victory poses, and battle backgrounds beyond the two sampler ones (see §11).

---

## 2. Asset inventory and compatibility (summary)

Full detail is in `ASSET_ANALYSIS.md`. Summary:

| Category | Asset | Classification | How we use it |
|---|---|---|---|
| Hero | Knight (8-dir, idle/walk/run/attack×2/hurt/death + 5 special moves) | ✅ Ready (exploration) · ⚙ Config (battle) | Player avatar; battle E-row; moves become skills |
| Enemies | Wolf, Goblin Scout, Skeleton (+4 colour variants each) | ⚙ Config | Battle W-row; variants = enemy tiers |
| Boss | Blade Assassin (2 forms, enraged, stagger, injured idles, 4 FX) | ⚙ Config | Two-phase chapter boss |
| Environments | Village, Castle Courtyard, Necropolis (128 px grid, 4 palettes each) | ⚙ Config (needs Godot ≥4.3) | Maps; battle-background composites |
| Weather / FX | Rain, snow, fog, cloud shadow, lightning, splashes | ✅ Ready | Map mood; lightning = "Thunder" spell FX |
| Battle / map FX (added 2026-11-17) | SovDigital spell effects (frost ×4 colours, shadow orb, energy burst), spell patterns (fire nova, arcane spirals, shadow orbit), projectiles (fire, arrow), blood splash (4 colours), ambient (embers, smoke, sparks, steam, dust, toxic gas) | ✅ In use | `FxSpec` + `BattleFx` (hits, Ember, healing); embers and smoke on the graveyard bone pyre. Unused effects are kept for Phase 8–10 spells and statuses |
| HD item icons (added 2026-11-17) | SovDigital Inventory UI kit: 5 icons + 5 equipment-slot silhouettes (the kit's panels/slots are not used, D6) | ✅ Partial | Minor Potion icon; Phase 9 equipment slots |
| Ambience | MIT-0 day/dusk/night/storm/fog/blood-moon controller | ⚙ Config | Map mood presets |
| UI | Gimble's kit: iron 9-slice panel + tooltip, red button (4 states), bar frame + red fill, 36 px slots, 2 cursors | ✅ Ready (2× files) · ⚙ MP fill needs recolour | Theme, HUD, menus, target cursor |
| Item icons | Gimble's: 15 items (longsword, axe, bow, helm, kite shield, health/mana potion, holy water, grimoire, soul gem, skull key, old map, silver stake, gold coins, torch) at 32/64/128 px | ✅ Ready | Item/equipment icons |
| Status / HUD icons | Gimble's: bleeding, burning, cursed, blessed, fire, talk, locked, quest, health, gold | ✅ Ready | Status tags, interaction prompt, quest marker |
| Portraits | Gimble's: Knight, Witch Hunter, Witch, Vampire Lord, Skeleton Warrior, Werewolf (framed and transparent, 64/128/256 px) | ✅ Ready | Dialogue portraits, party menu, bestiary |
| Battle backgrounds | Gimble's: Graveyard, Haunted Forest (1920×1080, true side view) | ✅ Ready · 🛠 style check vs HD battlers | Graveyard region battles; forest for later |
| UI complement | `All Assets.zip` (dfgui): red/blue/purple bar fills + segmented bar frames, 25 icons (sword, skill book, wand, pouch, shield, chest, monster book…), round portrait frames, MENU button, 11 map icons | ⚙ Config (×2 nearest copies, atlas regions) · ⚠ licence unknown | HP/MP/XP bars, command-menu icons, boss/bestiary frames, exploration MENU button, future journal/map |
| Font | Alegreya (OFL) | ⏳ Awaiting files | Theme default font |
| Audio | — | ❌ Missing | Needs sourcing per `AUDIO_CATALOG.md`; placeholder tones are generated for development |
| Fonts | Alegreya (chosen), Cinzel (recommended), both OFL | ⏳ Files to be supplied | Theme typography per `FONT_CATALOG.md` |
| NPCs | — | ❌ Missing | Knight recolour / prop-based NPC for slice |
| Party members 2–3 | — | ❌ Missing | Knight colour variants as placeholders |
| Forest / cave / dungeon tiles | — | ❌ Missing | Chapter 1 limited to village + courtyard + necropolis |
| Cast / defend / victory poses | — | 🛠 Adapt | Procedural stand-ins (tint, hold-frame, FX, tween) |

**Exploration and side-view compatibility:** every character sheet is top-down 3/4. The E/W rows are near-profile seen slightly from above and read convincingly as side-view battlers (verified visually). We do **not** redraw anything. The Gimble's battle backgrounds are drawn at eye level, which suits side-view battles. Our battlers are seen from slightly above, but standing on the background's open ground band with feet shadows, this reads naturally. Regions without a Gimble's background use a composite built from tileset pieces at the same 3/4 angle.

---

## 3. Visual direction and technical specifications

### Visual direction
- **Tone:** desaturated earth, slate, bone and rust. Warm light comes only from fire and lamps; cold fog and night otherwise.
- **Palettes:** necropolis `ash`/`frost`, village and courtyard `ash` or `slate`. Avoid the default bright `amber` village grass in "dangerous" areas.
- **Grading:** every map uses the vendor `map_grade` shader or ambience controller presets (dusk / fog / night / blood moon) for consistent mood.
- **UI:** Gimble's iron panels and crimson buttons, Alegreya text in bone/parchment colour (`#E8DCC0`-ish), gauntlet cursor for menu selection, and framed portraits in dialogue. Damage numbers are white, healing pale green, weaknesses crimson. UI colours are picked from the kit's own palette (`palette/dark_fantasy_kit_icons_80.hex`). The `dfgui` complements (gold-trimmed bars, command icons, round frames) share the dark-slate, gold and crimson look. Both kits are shown at a **2 screen-px per art-px** grid, so their pixel sizes match.
- **Pixel elements:** UI, icons, portraits and Gimble's battle backgrounds are hard-edged pixel art. World sprites and battlers are HD painted. This mix is deliberate and is reviewed at Milestone 1 (risk R3).
- **Rule for future assets:** HD painted sprites with a top-down 3/4 camera at the 128 px grid, matching SovDigital scale (humanoid ≈158 px). Pixel art is allowed **only** for UI.

### Technical specifications

| Setting | Value | Reason |
|---|---|---|
| Engine | Godot **4.6.x stable**, GDScript only | Vendor resources are 4.6 |
| Renderer | **Forward+** (change from current "Mobile") | PC target; 2D lights; vendor examples tested on desktop |
| Base viewport | **1920×1080**, stretch `canvas_items`, aspect `expand` | HD art needs HD base resolution |
| Default texture filter | **Linear + mipmaps** | Vendor-recommended for painted sprites (downscaled crisply) |
| UI texture filter | **Nearest** (set on the UI root `Control`) | Pixel UI stays sharp |
| World scale | Full-size assets (128 px tiles, characters at 1.0) | One asset size for world **and** battle; fewer imports |
| Exploration camera | `Camera2D.zoom = 0.75` (tunable 0.6–1.0) → ≈20×11 tiles, hero ≈118 px on screen | DQ-like framing without upscaling blur |
| Battle scale | Combatants at `CombatantVisual.scale` (≈1.0–1.2; boss ≈0.9) | Tunable per enemy |
| UI scale | Gimble's **2× files** used as-is (panel 256 px with 32 px margins, button 192×48, bar 192×24, icons 64 px, portraits 256 px). The middle parts of 9-slices use **Tile** mode, not stretch (vendor `ui_index.json`). The `dfgui` pieces are generated as ×2 nearest copies by `tools/upscale_ui.gd` (icons 52 px, bars ~250×24) | Godot 9-patch/progress textures cannot pixel-scale, so we use the pre-scaled files. ×4 is possible later with a nearest-upscale tool if 2× reads too small |
| Fonts | Alegreya Regular/Bold/Italic (+ Alegreya SC for titles, optional), sizes 28 / 34 / 48 | Readable at 1080p |
| Physics | Vendor layer 1 `world_solid`, layer 2 `water`; we add layer 3 `player`, layer 4 `interactables`, layer 5 `triggers` | Keeps vendor TileSet layers intact |
| Y-sorting | One `World` Node2D, `y_sort_enabled`, characters and props as siblings at the same z_index | Vendor-documented setup |
| Input actions | `move_up/down/left/right` (WASD, arrows, D-pad, left stick), `accept` (Enter/Space/E, pad A), `cancel` (Esc/Backspace, pad B), `menu` (Tab/M, pad Start) | Keyboard + gamepad from day 1 |
| Target | Windows desktop first; Linux build tested later | |

---

## 4. Godot project architecture

### 4.1 Guiding principles
1. **Five autoloads, no more**, each with one responsibility.
2. **Data is Resources; runtime state is RefCounted objects.** `.tres` files are never mutated at runtime. A `PartyMember` or `Combatant` wraps its `CharacterData`/`EnemyData` and holds the live HP/MP/status.
3. **Battle logic has zero Node dependencies.** It takes actions in and returns `BattleEvent`s out. It is deterministic given a seeded `RandomNumberGenerator`.
4. **Signals go up, calls go down.** Children emit signals; parents and autoloads call methods. There is no global EventBus: cross-system signals live on the autoload that owns the data, e.g. `GameState.flag_changed`.
5. **Composition over inheritance.** Reusable components (`Interactable`, `MapTransition`, `EncounterZone`) are small scenes dropped into maps.

### 4.2 Mapping of the requested systems

| Requested system | Realised as | Type | Notes |
|---|---|---|---|
| GameManager | `GameState` (data) + `SceneManager` (flow) | Autoloads | A single "GameManager" tends to become a god object, so it is split in two |
| SceneManager | `SceneManager` | Autoload | Map changes, fades, world↔battle hand-off, game over |
| SaveManager | `SaveManager` | Autoload | JSON save slots, versioned |
| AudioManager → MusicManager, SFXManager, AmbientAudioManager | One `AudioManager` autoload with three child managers (`scripts/audio/*.gd`) | Autoload + child Nodes | Keeps 5 autoloads while giving each audio concern its own class and tests (`AUDIO_GUIDELINES.md` §5) |
| DialogueManager | `DialogueManager` | Autoload | Owns the dialogue `CanvasLayer`; any NPC can call it |
| WorldManager | `Map` base script on each map scene + `SceneManager` | Scene script | Each map knows its spawn points, regions, music, ambience |
| PlayerController | `player.tscn` / `player_controller.gd` | Scene | CharacterBody2D, 8-dir |
| CameraController | `follow_camera.gd` on the player's Camera2D | Scene component | Limits read from the map |
| InteractionSystem | `InteractionProbe` (Area2D on player) + `Interactable` component | Scene components | `interacted(by)` signal |
| MapTransitionSystem | `MapTransition` (Area2D) + `SpawnPoint` (Marker2D) + `SceneManager.change_map()` | Scene components | |
| EncounterManager | `EncounterTracker` (node on player) + `EncounterZone` (Area2D in map) + `EncounterTable` Resource | Scene + Resource | No autoload needed |
| BattleManager | `BattleController` (`battle_scene.tscn` root) orchestrating `BattleEngine` | Scene + RefCounted | Async coordinator between logic, UI and presenter |
| TurnOrderSystem | `TurnOrder` | RefCounted (static funcs) | |
| CombatActionSystem | `BattleAction` + `ActionResolver` | RefCounted | |
| EnemyAI | `EnemyAI` + `AIProfile` Resource | RefCounted + Resource | |
| DamageCalculator | `DamageCalculator` | RefCounted (static funcs) | |
| StatusEffectSystem | `StatusEffects` + `StatusEffectData` Resource | RefCounted + Resource | |
| PartyManager | `Party` (inside GameState) | RefCounted | |
| CharacterStats | `StatBlock` Resource + `PartyMember`/`Combatant` runtime | Resource + RefCounted | |
| ExperienceSystem | `Progression` (static) + `GrowthCurve` Resource | RefCounted + Resource | |
| InventoryManager | `Inventory` (inside GameState) | RefCounted | |
| EquipmentSystem | `EquipmentData` Resource + `PartyMember.equip()` | Resource + method | |
| QuestManager | `QuestLog` (inside GameState) + `QuestData` Resource | RefCounted + Resource | |

### 4.3 Autoloads (exactly five)

| Autoload | Responsibility | Key API | Signals |
|---|---|---|---|
| `GameState` | Holds the session: `party: Party`, `inventory: Inventory` (a plain `items: Dictionary[StringName, int]` until Phase 9), `gold`, `flags: Dictionary[StringName, Variant]`, `quests: QuestLog`, `current_map`, `play_time`, `encounter_rate_modifiers: Dictionary[StringName, RateModifier]` | `set_flag()`, `get_flag()`, `add_gold()`, `apply_battle_rewards(result)`, `to_dict()`, `from_dict()`, `new_game()` | `flag_changed`, `gold_changed` |
| `SceneManager` | Owns the scene tree root swap, fade overlay, world↔battle transfer | `change_map(map_path: String, spawn_id: StringName)`, `start_battle(setup: BattleSetup)`, `end_battle(result: BattleResult)` (the **single owner** of reward application), `game_over()`, `to_title()`, `instant_transitions: bool` (tests) | `map_changed`, `battle_started`, `battle_ended(result)` |
| `AudioManager` | Facade over `music: MusicManager` (crossfade pair, `push`/`pop` for battles, jingles), `sfx: SFXManager` (UI pool + positional pool), `ambience: AmbientAudioManager` (layered loops). Buses Master/Music/Ambience/SFX/UI | `music.play/push/pop/play_jingle`, `sfx.play_ui/play_at/play_footstep`, `ambience.set_profile`, `set_bus_volume(bus, linear)` | `music.jingle_finished` |
| `SaveManager` | Serialises `GameState.to_dict()` to `user://saves/slot_N.json` with `"version"` and a migration hook | `save_slot(slot)`, `load_slot(slot)`, `list_slots()`, `has_save(slot)` (not `load()`, which would shadow the global) | `saved`, `loaded` |
| `DialogueManager` | Loads dialogue JSON, runs lines/choices, writes flags, drives the `DialogueBox` UI, pauses player input | `start(dialogue_id) -> await finished` | `dialogue_started`, `dialogue_finished(id)` |

**Why not more?** An encounter manager, battle manager and quest manager don't need to exist globally. Each lives either inside the scene that uses it or inside `GameState` as plain objects. That keeps the global surface small and testable.

### 4.4 Communication diagram

```
				 ┌──────────────────────── Autoloads ─────────────────────────┐
				 │ GameState   SceneManager   DialogueManager   Audio   Save   │
				 └────▲─────────▲───────▲─────────▲──────────────────▲────────┘
	 flags/rewards    │  change_map()   │ start_battle()   start()   │ save()
					  │         │       │         │                  │
┌──── World (map.tscn) ─────────┼───────┼─────────┼──────────┐  ┌────┴───────┐
│ Player ── InteractionProbe ───┼───────┼──► Interactable(NPC)│  │ PauseMenu  │
│   │                           │       │      (signal)       │  └────────────┘
│   └─ EncounterTracker ◄── EncounterZone(EncounterTable)     │
│         │ steps → roll → encounter_triggered(group)─────────┘
│ MapTransition ── body_entered ──► SceneManager.change_map()
└────────────────────────────────────────────────────────────┘

┌──── Battle (battle_scene.tscn) ─────────────────────────────────────────┐
│ BattleController (Node, async)                                          │
│   ├─ asks CommandMenu/TargetSelector  ──► BattleAction                  │
│   ├─ asks EnemyAI                      ──► BattleAction                 │
│   ├─ BattleEngine (RefCounted, pure)   ──► Array[BattleEvent]           │
│   └─ BattlePresenter.play(events) ──► BattleSprites, popups, HUD (await)│
│ on end ─► finished(BattleResult) ─► SceneManager.end_battle(result) ─► GameState.apply_battle_rewards()
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.5 World ↔ battle hand-off
1. `EncounterTracker` emits `encounter_triggered(group: EncounterGroup, table: EncounterTable)`.
2. The map builds a `BattleSetup` (enemies, background scene, music, `can_flee`, `is_boss`) and calls `SceneManager.start_battle(setup)`.
3. `SceneManager` fades out, **detaches** the world scene (`remove_child`, not freed) to preserve player position and map state, and adds `battle_scene.tscn`.
4. The battle finishes and emits `finished(result: BattleResult)`. `SceneManager.end_battle(result)` calls `GameState.apply_battle_rewards(result)` on victory (the only place rewards are applied), frees the battle, re-attaches the world, fades in and emits `battle_ended(result)`.
5. On defeat, `SceneManager.game_over()` shows the Game Over screen, which offers **Load last save** or **Title**.

### 4.6 Battle logic vs. presentation

```
			input                          output
BattleAction ──► BattleEngine.execute_next() ──► Array[BattleEvent]
				 (uses DamageCalculator,      e.g. ActionStarted(actor, skill)
				  StatusEffects, TurnOrder,        Damage(target, amount, element, crit, weak)
				  RNG injected)                    Heal(...), StatusApplied(...), Defeated(target)
												   PhaseChange(enemy, new_data), Message(text),
												   RoundEnded, BattleEnded(outcome)
```
- **Engine API (used identically everywhere in this plan):**
  - `setup(setup: BattleSetup, party: Array[Combatant], rng)`
  - `begin_round(party_actions: Array[BattleAction])`: adds the enemy actions from `EnemyAI.choose(enemy, engine)` and sorts everything with `TurnOrder`.
  - `has_next_action() -> bool`
  - `execute_next() -> Array[BattleEvent]`: one action's events, so the controller can present it and check the end after each action.
  - `end_round() -> Array[BattleEvent]`: status ticks.
  - `outcome() -> Outcome` (`ONGOING/VICTORY/DEFEAT/FLED`)
  - `compute_rewards() -> BattleResult`
- `BattleEvent` is a small RefCounted with `type: BattleEvent.Type` and a payload. The presenter pattern-matches on `type`.
- **Logic never awaits and never touches nodes.** The presenter can be skipped entirely in tests, or replaced by a fast-forward presenter (a "battle speed" option for later).
- `BattleEngine` state: `party: Array[Combatant]`, `enemies: Array[Combatant]`, `round: int`, `rng: RandomNumberGenerator`.

### 4.7 Key data Resources (`class_name`, all `@export`-typed)

| Resource | Main fields |
|---|---|
| `StatBlock` | `max_hp, max_mp, attack, defense, magic, spirit, agility, luck: int` |
| `CombatantVisual` | `sprite_frames: SpriteFrames`, `battle_scale: float`, `offset: Vector2`, `facing: StringName` (`&"E"`/`&"W"`), `anim_map: Dictionary[StringName, StringName]` (idle/attack/hurt/death/cast/move → vendor anim), `hit_frame: int`; since Phase 5 also `move_frames`, `hit_frames`, `last_frames`, `height` |
| `CharacterData` | `id, display_name, portrait: Texture2D, base_stats: StatBlock, growth: GrowthCurve, visual: CombatantVisual, starting_skills: Array[SkillData], skill_unlocks: Array[SkillUnlock]`; `allowed_equipment: Array[EquipmentData.Category]` is added in Phase 9 |
| `SkillUnlock` | `level: int, skill: SkillData` |
| `DropEntry` | `item: ItemData, chance: float` |
| `RateModifier` (RefCounted, not a file) | `mult: float, steps_left: int` (−1 = permanent) |
| `EnemyData` | `id, display_name, stats: StatBlock, affinities: Dictionary[Element, float], skills: Array[SkillData], ai: AIProfile, xp, gold: int, drops: Array[DropEntry], visual: CombatantVisual, status_immunities, phase_two: EnemyData (optional), phase_two_at_hp_pct: float` |
| `SkillData` | `id, display_name, category (SKILL/MAGIC), mp_cost, power, scaling_stat, element, target_mode (ONE_ENEMY/ALL_ENEMIES/ONE_ALLY/ALL_ALLIES/SELF), hits, inflicts: StatusEffectData, inflict_chance, anim_key, fx: PackedScene, description` |
| `ItemData` | `id, display_name, icon, price, usable_in_field, usable_in_battle, target_mode, effect (HEAL_HP/HEAL_MP/CURE_STATUS/REVIVE/DAMAGE), amount, cures: Array[StatusEffectData], description` |
| `EquipmentData` (extends `ItemData`) | `category (WEAPON/SHIELD/HELM/ACCESSORY), stat_bonus: StatBlock, attack_element, resist: Dictionary[Element, float], encounter_rate_mult: float` |
| `StatusEffectData` | `id, display_name, kind (BLEED/BURN/CURSE/BLESSED/SLEEP/STUN…), icon: Texture2D (optional), duration_turns, dot_percent, skip_turn, stat_mult: Dictionary, wears_off_on_hit: bool, tag_color` |
| `GrowthCurve` | `xp_base, xp_exponent, stat_gain_per_level: StatBlock, max_level` |
| `AIProfile` | `skill_weights: Dictionary[SkillData, int]`, `target_strategy (RANDOM/LOWEST_HP/HIGHEST_ATTACK)`, `heal_below_hp_pct` |
| `EncounterGroup` | `enemies: Array[EnemyData]`, `weight: int`, `is_rare: bool`, `required_flag: StringName`, `forbidden_flag: StringName`, `can_flee: bool` |
| `EncounterTable` | `id, groups: Array[EncounterGroup]`, `base_chance_per_step: float`, `grace_steps: int`, `background: PackedScene`, `music: AudioStream` |
| `BossEncounter` | `group: EncounterGroup`, `required_flags`, `defeated_flag`, `background`, `music` (phase two lives on `EnemyData`) |
| `QuestData` | `id, title, description, stages: Array[String]`, `stage_flags: Array[StringName]` |

Dialogue is **JSON** (`data/dialogue/*.json`), not Resources. Writing text in the Inspector is slow and error-prone, while JSON is diffable and easy to author. Its schema is validated by a unit test.

```json
{ "id": "elder_intro", "lines": [
  { "speaker": "Elder Maren", "text": "The bells stopped ringing three nights ago.",
	"set_flag": "met_elder" },
  { "speaker": "Elder Maren", "text": "Will you look into the graveyard?",
	"choices": [ { "text": "I will.", "goto": 2, "set_flag": "quest_graveyard_accepted" },
				 { "text": "Not now.", "goto": "end" } ] },
  { "speaker": "Elder Maren", "text": "Then take this, and go before dark.", "give_item": "minor_potion" } ],
  "conditions": { "if_flag": "met_elder", "use": "elder_again" } }
```

### 4.8 Trade-offs considered

| Choice | Chosen | Alternative | Why |
|---|---|---|---|
| Global state | `GameState` autoload with composed `Party`/`Inventory`/`QuestLog` | One autoload per system | Fewer globals and one serialisation point |
| Event bus | **None**: signals on owning autoloads | Global `EventBus` | An event bus hides data flow and is hard to trace solo |
| Battle model | **Round-based** (all choose, then resolve by agility) | CTB/ATB individual turns | Matches DQ, simplest to test. `TurnOrder` is isolated, so a CTB switch later touches one class |
| Battle logic | Pure RefCounted + event list | Logic in nodes + AnimationPlayer | Testable headless, deterministic, presentation swappable |
| Saves | JSON `Dictionary` | `ResourceSaver` `.tres` | Loading untrusted `.tres` can execute scripts; JSON is safe and migratable |
| Dialogue | JSON + tiny runner | Dialogic addon / Resources | Avoids a dependency; easy to write |
| Tests | **Own minimal runner** (~150 lines) | GUT / GdUnit4 addons | User asked for no unnecessary dependencies; our tests are mostly pure logic. GUT can be adopted later if needed |
| World↔battle | Detach world node, keep in memory | Save position + reload map | Instant return, preserves map state (opened chests, NPC positions) |
| Vendor scripts | Adopt `ambience_controller.gd`, `light_fx.gd` and the weather shaders/scripts as-is (MIT-0), copied into `res://addons/sovdigital/` | Re-write | Free and tested, saves weeks. Under `addons/`, Godot's default `exclude_addons` skips their untyped-code warnings, so our strict typing rule doesn't break on vendor code. The vendor `Fx` autoload is **not** registered: we keep 5 autoloads and use our own `FxPlayer` component |

---

## 5. Scene and script organisation

```
res://
├── project.godot
├── PROJECT_PLAN.md · ASSET_ANALYSIS.md · README.md · CREDITS.md · CONTRIBUTING.md (coding standards)
├── docs/balance.csv             # Phase 11: target levels and stat tables per region
├── assests/                      # ORIGINAL ZIPS — untouched; `.gdignore` added so Godot skips it
├── addons/sovdigital/           # vendor MIT-0 scripts/shaders (ambience, weather), unmodified
├── assets/
│   ├── vendor/sovdigital/        # COPIED subsets only (sheets/, godot/, json, LICENSE.txt)
│   │   ├── knight/  wolf/  goblin_scout/  skeleton/  blade_assassin/
│   │   ├── village/  castle_courtyard/  necropolis/  weather/
│   ├── vendor/gimbles/           # COPIED: ui/2x/, ui/ui_index.json, item_icons/64px/, hud_icons/64px/,
│   │                             #   portraits/framed/256px/, portraits/transparent/128px/,
│   │                             #   backgrounds/1920x1080/, palette/, LICENSE.txt
│   ├── vendor/dfgui/1x/          # COPIED dfgui_*.png from All Assets.zip
│   ├── vendor/dfgui/2x/          # generated ×2 nearest copies (tools/upscale_ui.gd)
│   ├── fonts/{alegreya,cinzel}/  # user-provided TTFs + OFL.txt
│   └── audio/{music,ambience,sfx/<category>}/   # processed copies; originals in assests/audio_sources/
│       └── placeholder/          # generated test tones (tools/make_placeholder_audio.gd)
├── data/
│   ├── characters/  enemies/  skills/  items/  equipment/  status_effects/
│   ├── encounters/  bosses/  quests/  growth/  ai/
│   └── dialogue/*.json
├── scenes/
│   ├── boot/main.tscn                       # entry: title → new game / continue (since Phase 7: ui/title_screen.tscn)
│   ├── ui/
│   │   ├── theme/{main_theme.tres, ui_palette.tres, fonts/font_*.tres}
│   │   ├── title_screen.tscn · pause_menu.tscn · game_over.tscn · shop_menu.tscn
│   │   ├── menus/{settings_menu, save_load_menu, inventory_page, equipment_page,
│   │   │          status_page, journal_page, map_page}.tscn
│   │   ├── debug/typography_specimen.tscn
│   │   ├── dialogue_box.tscn · fade_overlay.tscn
│   │   └── widgets/{stat_bar.tscn, party_panel.tscn, item_slot.tscn}
│   ├── world/
│   │   ├── map.gd                            # base script for every map
│   │   ├── maps/{village_01.tscn, graveyard_01.tscn, …}
│   │   ├── player/{player.tscn, player_controller.gd, follow_camera.gd,
│   │   │           interaction_probe.gd, encounter_tracker.gd}
│   │   └── components/{interactable.tscn/.gd, npc.tscn/.gd, map_transition.tscn/.gd,
│   │                   spawn_point.gd, encounter_zone.tscn/.gd, boss_trigger.tscn/.gd, chest.tscn/.gd}
│   └── battle/
│       ├── battle_scene.tscn · battle_controller.gd · battle_presenter.gd · debug_battle.tscn
│       ├── fx_player.tscn/.gd           # plays vendor effect SpriteFrames once, frees itself
│       ├── battle_sprite.tscn/.gd
│       ├── backgrounds/{graveyard_bg.tscn (Gimble's), village_outskirts_bg.tscn (tileset composite)}
│       └── ui/{command_menu.tscn, target_selector.tscn, battle_hud.tscn,
│               damage_popup.tscn, battle_message.tscn, results_screen.tscn}
├── scripts/                     # non-scene code (class_name)
│   ├── autoload/{game_state.gd, scene_manager.gd, audio_manager.gd, save_manager.gd, dialogue_manager.gd}
│   ├── audio/{music_manager.gd, sfx_manager.gd, ambient_audio_manager.gd,
│   │          music_track.gd, sfx_set.gd, ambience_profile.gd, ambience_layer.gd}
│   ├── ui/{ui_palette.gd, settings.gd}
│   ├── resources/{stat_block.gd, combatant_visual.gd, character_data.gd, enemy_data.gd, skill_data.gd,
│   │              item_data.gd, equipment_data.gd, status_effect_data.gd, growth_curve.gd, ai_profile.gd,
│   │              encounter_group.gd, encounter_table.gd, boss_encounter.gd, quest_data.gd, drop_entry.gd,
│   │              skill_unlock.gd}
│   ├── rpg/{party.gd, party_member.gd, inventory.gd, quest_log.gd, progression.gd, elements.gd,
│   │        rate_modifier.gd}
│   └── battle/{battle_engine.gd, combatant.gd, active_status.gd, battle_action.gd, battle_event.gd,
│               battle_setup.gd (Resource),
│               battle_result.gd, turn_order.gd, action_resolver.gd, damage_calculator.gd,
│               status_effects.gd, enemy_ai.gd, encounter_roller.gd}
├── tests/
│   ├── test_runner.gd           # `godot --headless -s res://tests/test_runner.gd`
│   ├── test_case.gd             # assert helpers
│   ├── unit/test_*.gd
│   └── smoke/test_scene_smoke.gd
└── tools/
	├── extract_assets.py        # copies needed subsets out of the zips (never writes into assests/)
	├── verify_source_assets.py  # SHA-256 of every zip in assests/ vs. tools/source_assets.sha256
	├── upscale_ui.gd            # `extends SceneTree`, run headless: ×2 nearest copies of dfgui
	└── check.ps1 / check.sh     # import + parse + tests, non-zero exit on failure
```

---

## 6. Core gameplay system designs

### 6.1 Exploration
- **Player:** `CharacterBody2D`, `walk_speed = 260 px/s` (world px at full scale; tunable), 8-direction input normalised. The `AnimatedSprite2D` uses the vendor `knight_spriteframes.tres`, choosing `walk_<DIR>`/`idle_<DIR>` from the last non-zero input vector (45° sectors). The collision shape is a small horizontal `CapsuleShape2D` (rotated 90°, no non-uniform scaling) at the feet (pivot from the JSON), so walls overlap the head correctly with Y-sort.
- **Camera:** `Camera2D` child of the player, `position_smoothing`. Limits come from `Map.camera_bounds` (a `ReferenceRect` in each map).
- **Interaction:** `InteractionProbe` is an Area2D in front of the player that follows the facing direction. On `accept`, it calls `interact(player)` on the nearest `Interactable`. NPCs, signs, chests and graves are all `Interactable`s with an exported `dialogue_id` or a custom signal.
- **Transitions:** `MapTransition` (Area2D) has `target_map: String` (scene path) and `target_spawn: StringName`. `SpawnPoint` (Marker2D) has `spawn_id` and `facing`. Input is blocked during the fade.
- **Map scene template:** `Ground` (Sprite2D regions / TileMapLayer) → `Terrain` (TileMapLayer, vendor TileSet) → `Decals` → `World` (y-sorted: TileMapLayer for pieces, props, NPCs, Player) → `Regions` (EncounterZones) → `Transitions` → `Lights` → `Ambience` (vendor controller) → `CameraBounds`.

### 6.2 Random encounters
- **Region model:** each map has 0..n `EncounterZone` polygons, each with an `EncounterTable`. Towns have none. The player's `EncounterTracker` keeps a stack of overlapping zones and the **innermost / last entered** zone wins, so a "deep woods" zone can sit inside a "woods" zone.
- **Steps:** a "step" is every **64 px of actual travelled distance** (half a tile, measured from `get_real_velocity()`, so pushing against walls doesn't count).
- **Probability per step:** `p = table.base_chance_per_step × Π(GameState.encounter_rate_modifiers) × equipment_mult`. The default is `base_chance_per_step = 0.04`, about one encounter every ~25 steps or ~12 tiles.
- **Grace period:** no roll for `table.grace_steps` (default 6) after map entry, a battle, or closing a dialogue.
- **Group selection (`EncounterRoller`, pure):** filter groups by `required_flag`/`forbidden_flag`, then do a weighted random pick. **Rare** groups are ordinary groups with low weight (e.g. 2 of 100) plus an `is_rare` flag that the presenter uses for a special intro sting.
- **Bosses:** not random. A `BossTrigger` (an Area2D or `Interactable`) checks `required_flags` and that `defeated_flag` is not set. It starts a battle with `can_flee = false` and sets `defeated_flag` on victory.
- **Future modifiers:** `GameState.encounter_rate_modifiers: Dictionary[StringName, RateModifier]` (`mult`, `steps_left`; the tracker decrements and removes expired ones), so items ("Warding Torch ×0.25 for 200 steps"), accessories, story events or difficulty modes can add or remove multipliers without code changes elsewhere.

### 6.3 Battle system

**Flow (round-based):**
```
BattleStart → intro (enemies fade in, "A pack of Wolves emerges!")
loop:
  CommandPhase: for each living, able party member → CommandMenu → (Skill/Magic/Item submenu) → TargetSelector
				(Cancel steps back to the previous member)
  engine.begin_round(party_actions)  # adds EnemyAI.choose(enemy, engine) per enemy; TurnOrder.sort:
									 # agility × rand(0.85..1.15), Defend always first
  ResolvePhase: while engine.has_next_action():
				  events = engine.execute_next()   # skips dead/unable actors, retargets
				  await presenter.play(events)
				  if engine.outcome() != ONGOING: break
  RoundEnd:     engine.end_round() → StatusEffects.tick (bleed/burn dmg, durations) → events → check end
Victory → ResultsScreen (XP, gold, drops, level-ups) → BattleResult
Defeat  → "The party has fallen…" → Game Over
Flee    → success chance from party vs enemy agility; on fail the party loses its round
```

**Commands:** `Attack` · `Skills` (physical techniques, often MP-costing, e.g. Knight *Whirlwind* hits all enemies, *Charged Strike* is a heavy single hit, *Combo* is 3 hits) · `Magic` (spells) · `Items` · `Defend` (halves damage taken this round, acts first) · `Flee` (disabled in boss fights).

**Damage formulas (initial, tunable constants in `DamageCalculator`):**
- Physical: `base = max(1, atk × 0.5 − def × 0.25)`, then × variance `rng.randf_range(0.875, 1.125)`.
- Critical: chance `= 1/32 + luck/512`. Crits ignore defence and deal ×1.5.
- Magic: `base = power + magic × 0.5 − spirit × 0.25`, minimum `power × 0.25`.
- Element: multiplied by `target.affinity(element)`: 2.0 weak, 1.0 normal, 0.5 resist, 0.0 immune. Weak hits show "WEAK!" in crimson.
- Defend ×0.5. Final result rounded and clamped to `[0, 9999]`.
- Healing: `power + magic × 0.4` with ±10% variance.

**Elements:** `PHYSICAL` (none), `FIRE`, `FROST`, `LIGHTNING`, `HOLY`, `SHADOW`. Starting affinities: skeletons are weak to HOLY and resist SHADOW, wolves weak to FIRE, goblins weak to LIGHTNING, the Blade Assassin resists SHADOW and is weak to HOLY.

**Status effects (initial set, chosen to match the Gimble's status icons):**

| Status | Effect | HUD |
|---|---|---|
| Bleed | 5% max HP per round, 3 rounds | `01_bleeding` icon |
| Burn | 6% max HP per round, 2 rounds; FIRE-immune targets are unaffected | `03_burning` icon |
| Curse | ATK and MAG ×0.75, healing received ×0.5, 3 rounds | `05_cursed` icon |
| Blessed (buff) | DEF and SPR ×1.25, +3% HP per round, 3 rounds | `22_blessed` icon |
| Sleep | skip turn, wakes on hit, 2–4 rounds | text tag "SLP" (no icon in sampler) |
| Stun | skip 1 turn | text tag "STN" (no icon in sampler) |

**Enemy AI:** `AIProfile` weighted random over its skills plus "attack", with a target strategy. The boss profile switches to phase 2 at ≤50% HP: the engine emits `PhaseChange`, and the presenter swaps the sprite to *Unmasked* at the same feet pivot (vendor-supported).

**Rewards:** sum of defeated enemies' `xp`/`gold`. Drops roll each `DropEntry.chance`. XP goes to living members only (DQ rule), divided equally. Level-ups apply growth and unlock skills, and appear on the results screen.

**Presentation mapping (`BattleSprite`):**

| Logical anim | Knight (E row) | Wolf / Goblin / Skeleton (W row) | Blade Assassin (W row) | Stand-in if missing |
|---|---|---|---|---|
| idle | `idle_E` | `idle_W` | `idle_W` → `idle_hp50_W` / `idle_hp25_W` | — |
| move (step forward) | `run_E` + tween +120 px | `run_W` + tween −120 px | `run_W` | — |
| attack | `attack_E`, damage shown on `hit_frame` | `attack_W` | `attack3_W` | — |
| skill | vendor move (`whirlwind_E`, `charged_strike_E`, `combo_E`) | `attack2_W` | `attack2/4_W` | — |
| cast | `charged_strike_E` (frames 0–6) + coloured glow + spell FX | `attack2_W` + glow | Form 1: `attack4_W` + crimson glow · Form 2: `attack5_W` (Blood Mist) / `attack6_W` (Bone Lance) | modulate pulse + FX |
| hurt | `hurt_E` + white flash + knockback 12 px | `hurt_W` | `hurt_W` / `stagger_W` | — |
| defend | — | — | — | hold `idle` frame 0, blue-steel tint, shield FX ring, tween back 16 px |
| death | `death_E` (stay on last frame, desaturate) | `death_W` then fade | `death_W` | — |
| victory | — | — | — | Knight `idle_E` + slight raise, camera hold |

### 6.4 Party, progression, inventory, equipment, quests (later phases)
- **Party:** up to **3 active** members, with no reserve bench at first. Members 2–3 are **placeholder Knight recolours** (black and gold variants) with different stats and skills (e.g. "Warden" is tanky, "Hexblade" has spells) until real art exists.
- **XP curve:** `xp_to_next(L) = round(xp_base × L^xp_exponent)` (defaults 12 and 1.6) and a level cap of 30 for chapter 1. Stats gain `stat_gain_per_level` ± 1 of RNG.
- **Inventory:** stacks by `ItemData.id` (max 99), key items in a separate list, and a gold counter.
- **Equipment:** 4 slots (Weapon / Shield / Helm / Accessory), chosen to match the available icons (no body-armour icon in the kits yet). Effective stats = base + level gains + Σ equipment bonuses, computed on demand (never stored).
- **Quests:** `QuestLog` stores `quest_id → stage index` and advances when flags are set (`stage_flags`). Quest UI is a simple list with the current stage text.
- **Shop:** an NPC `Interactable` opens `shop_menu.tscn` with an exported `Array[ItemData]` stock.

### 6.5 UI mockups

**Exploration HUD (minimal; full party panel only in the pause menu)**
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ◈ Ashfall Hamlet                                                  [≡ MENU]   │
│                                                                              │
│                    (top-down village, fog overlay, dusk grade)               │
│                                                                              │
│                                 ▲ "Examine"   ← prompt over interactable      │
│                               [Knight]                                       │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Dialogue box (Gimble's iron 9-slice panel, framed 256 px portrait, Alegreya text)**
```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│  ╔═══════╗ ┌──────────────────────────────────────────────────────────────┐  │
│  ║(round ║ │ Elder Maren                                                   │  │
│  ║ frame)║ │ The bells stopped ringing three nights ago. Since then the    │  │
│  ╚═══════╝ │ dead walk the old road.                                    ▼  │  │
│            └──────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Battle screen (1920×1080)**
```
┌──────────────────────────────────────────────────────────────────────────────┐
│  A pack of Wolves emerges from the mist!                                     │
│                                                                              │
│                                                   [Wolf A] ◄                 │
│         ► [Warden]                                                           │
│     ► [Knight]                                       [Wolf B] ◄    [Wolf C]◄ │
│         ► [Hexblade]              -24                                        │
│                                   WEAK!                                      │
│ ─────────────────────────────────────────────────────────────────────────────│
│ ┌───────────────┐ ┌────────────────────────────────────────────────────────┐ │
│ │ ▸ Attack      │ │ Knight    HP ███████████░░ 112/130   MP ██████░ 18/24  │ │
│ │   Skills      │ │ Warden    HP ███████████████ 160/160 MP ███░░░  9/20   │ │
│ │   Magic       │ │ Hexblade  HP ██████░░░░░░░  58/96    MP ████████ 40/40 │ │
│ │   Items       │ │                                    [🩸bleed] [SLP]     │ │
│ │   Defend      │ └────────────────────────────────────────────────────────┘ │
│ │   Flee        │                                                            │
│ └───────────────┘                                                            │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Results screen**
```
┌────────────────────────────── VICTORY ───────────────────────────────┐
│  Experience  +36        Gold  +14                                    │
│  Found: Wolf Pelt ×1                                                 │
│  Knight reached level 3!  HP +9  ATK +2  AGI +1   Learned: Whirlwind │
│                                                   [ Continue ▸ ]     │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 7. Story concepts (NOT approved — for discussion only)

> These are kept separate from the technical plan. None is canon. The technical plan uses only neutral placeholder names (`village_01`, "Elder", "Knight") until a concept is chosen.

### Concept A — *The Bells of Hollowmere* (undead / faith / guilt)
- **Premise:** For a thousand years the bell-towers of the kingdom of Hollowmere have rung at dusk to keep the dead asleep. One by one the bells fall silent, and the dead rise to walk the old pilgrim roads.
- **World:** A kingdom of chapels and ossuaries, its people half-starved by tithes to the Bell Order. There are necropolis-cities larger than the towns of the living, and grey villages behind palisades.
- **Central conflict:** Someone is deliberately silencing the bells. The Order blames heretics and burns villages to "purify" them.
- **Protagonist:** A disgraced knight of the Bell Order, stripped of rank for refusing to burn a village, now working as a gravewarden on the frontier.
- **Antagonist:** *The Unmasked* (Blade Assassin): a masked killer who murders the bell-ringers and fades between shadows.
- **Twists:** The bells don't keep the dead asleep. They **bind** the souls of the dead to power the Order's miracles. The Unmasked is a former ringer freeing them. The protagonist's own healing "faith magic" draws on those bound souls. The final choice is to restore the bells and save the living from the dead, or break them and lose all holy magic.
- **Locations / enemies:** frontier hamlet, pilgrim road, ossuary crypts, the Bell Cathedral, drowned chapel. Skeletons, ghoul packs, Order zealots, bell-wraiths, corrupted wolves.

### Concept B — *Tithe of the Red Moon* (folk horror / wilderness / pact)
- **Premise:** Every seventh winter a red moon rises over the Thornwald. The valley villages must give one person to the forest, or the wolves come down from the hills. This year the lot falls on the protagonist's sibling.
- **World:** Isolated mountain valleys cut off from a fallen empire. There are goblin warrens in old mines, and roads lined with wolf-skull totems.
- **Central conflict:** The protagonist refuses the tithe and walks into the Thornwald to end the pact. Behind them, the valley breaks into panic and witch-hunts.
- **Protagonist:** A former imperial soldier who came home to the valley to forget the war, and is the last person in the village who still owns armour.
- **Antagonist:** *The Grey Warden*, the lord-protector of the valley, who enforces the tithe and is the only one who knows who wrote the pact.
- **Twists:** The wolves are the descendants of the empire's last legion, cursed for abandoning the valley. Each tithe is a person **chosen to become a wolf**. The Warden paid the first tithe himself. Ending the pact without a replacement unleashes the thing in the forest that the wolves have been holding back. A late companion may be the "lost" tithe of seven winters ago, now half-wolf.
- **Locations / enemies:** Valley village, totem roads, goblin mine, ruined legion fort (castle courtyard), barrow fields. Wolves (dire, white, black variants), goblin scouts, barrow-skeletons, the wolf-mother.

### Concept C — *The Hollow Crown* (succession / political / cursed kingdom)
- **Premise:** The kingdom of Vaelmark has had no living king for 99 years. The crown waits on an empty throne, and by ancient law it passes only to whoever slays its last bearer. Nobody knows who that is.
- **World:** A kingdom ruled by a council of regents. There are abandoned royal fortresses, and a capital half-sunk in its own necropolis because the dead were buried under the streets for a century.
- **Central conflict:** Claimants hunt each other across the realm. The regents secretly pay an assassin to kill every claimant before the 100th year, when the law says the crown will "choose".
- **Protagonist:** A low-born courier who unknowingly carries a royal seal, and is therefore marked as a claimant and hunted.
- **Antagonist:** *The Daywalker* (Blade Assassin phase 2, "Unmasked"), the regents' executioner. Their mask hides a face that matches the old king's portraits.
- **Twists:** The last king never died. He became the necropolis beneath the capital, and "slaying the last bearer" means destroying the city's foundations. The Daywalker is the king's undying heir trying to **prevent** anyone from inheriting the curse. In the finale the protagonist could become the next hollow king.
- **Locations / enemies:** border village, regent fortress (courtyard), claimant war-camps, the sunken capital (necropolis), the throne vault. Rival claimant knights (Knight recolours), goblin mercenaries, crown-bound skeletons, the Daywalker in two phases.

**How the assets fit:** A and C lean hardest on the necropolis and the Blade Assassin. B makes the best use of wolves and goblins and the blood-moon ambience preset, but needs forest tiles we don't have yet.

---

## 8. Development roadmap (overview)

| Phase | Name | Depends on | Size (solo, rough) | Playable output |
|---|---|---|---|---|
| 1 | Foundation and asset pipeline | — | S (≈1 wk) | Project opens in 4.6, tests run |
| 2 | Exploration prototype | 1 | M (≈1–2 wk) | Walk the Knight around the village |
| 3 | Map transitions and interaction | 2 | S–M (≈1 wk) | Village ↔ graveyard, examine objects |
| 4 | Battle core (logic, headless) | 1 | M (≈1–2 wk) | Simulated battles in tests |
| 5 | Battle presentation | 4 | L (≈2–3 wk) | Debug-launched side-view battle |
| 6 | Random encounters | 3, 5 | S–M (≈1 wk) | World → battle → world loop |
| 7 | 🎯 **Milestone 1: vertical slice** | 6 | M (≈1–2 wk) | The slice defined in §8.1 |
| 7A | **Audio setup** (built 2026-11-17; listening check open) | 7 (+ user-supplied audio) | S–M (≈1 wk) | The slice with music, jingles and UI sounds (no ambience/combat SFX: no source) |
| 8 | Party and progression, status effects (built 2026-11-20; playtest open) | 7A | M | 3-member party, levels, statuses |
| 9 | Inventory, equipment, items, shop | 8 | M | Items in field/battle, gear, shop |
| 10 | Dialogue, NPCs, quests, boss (built 2026-11-24; playtest open) | 9 | M–L | Quest chain, two-phase boss |
| 11 | Save/load and Chapter 1 content | 10 | L | Complete first chapter |
| 12 | Polish, audio, optimisation, release build | 11 | M–L | Exported Windows build |

**UI, typography and audio work (threaded through the phases, not a separate phase):**

| Phase | UI / typography | Audio |
|---|---|---|
| 1 | Theme + palette + font variations, typography specimen, title stub | Bus layout, `AudioManager` + 3 managers (skeleton), placeholder tones, asset manifest + licence test |
| 3 | Interaction prompt, simple dialogue box | — |
| 5 | Battle HUD, HP/MP bars, command menu, damage popups | Battle SFX hooks (`SfxSet` on skills/hits), placeholder sounds |
| 6 | — | Music `push`/`pop` exploration ↔ battle, ambience profiles per map |
| 7 | Final main menu, pause menu, **settings menu**, full dialogue box with portraits | `SFXManager`, `UiSounds`, footsteps by surface, settings sliders (the sourcing gate was not met, so the slice shipped silent) |
| 7A | — | **Audio setup:** user sources the slice set (`AUDIO_CATALOG.md`); import pipeline, generated audio resources, combat/level-up/reward hooks, slice audio integrated and mixed |
| 8 | Character status screen, 3-member party HUD | Status-effect SFX |
| 9 | Inventory, equipment, shop screens | Chest, door, loot, buy/sell SFX |
| 10 | Quest journal, map interface, portraits for NPCs | Boss and story music, monster SFX |
| 11 | Save/load interface with thumbnails | Chapter 1 music coverage (town/dungeon/story) |
| 12 | Polish pass against `ART_GUIDELINES.md` checklist | Full SFX library, weather audio, loudness/mix pass, credits from manifest |

Phases 2–3 and Phase 4 are **independent** and could interleave (e.g. logic work when tired of level-building).
Sizes are estimates for a single developer working part-time-to-full-time. They are not commitments.

### 8.1 Milestone 1 (vertical slice) definition
- One playable character (Knight).
- One exploration map, `village_01`, plus a small dangerous outskirts area (`graveyard_01`, necropolis tiles) connected by a transition.
- One NPC interaction (dialogue with a choice that sets a flag).
- Random encounters in the outskirts zone with **3 enemy types** (Wolf, Goblin Scout, Skeleton) in 3–4 groups, including one rare group (Charred Skeleton recolour).
- A complete side-view battle: all commands work (Skills/Magic with 1–2 entries each, Items with a Minor Potion).
- Victory screen with XP, gold and a drop applied to `GameState`; level-up works; defeat shows Game Over.
- Cohesive presentation: themed main menu, pause and settings menus (volume sliders), dialogue box with portrait, Alegreya/Cinzel typography, and the **slice audio set** (or placeholder tones if the sourcing gate isn't met; noted in the review).
- **Not in the slice:** save/load (beyond a debug "restart"), party members 2–3, equipment, shops, quests, boss.

---

## 9. Detailed phase breakdown

Conventions used in tests:
- `GODOT` = path to `Godot_v4.6.x-stable_win64_console.exe`
- **Run all tests:** `"$GODOT" --headless --path . -s res://tests/test_runner.gd`, which exits 0 on success and 1 on any failure.
- **Full check:** `tools/check.ps1`, which runs `--import`, fails on any `SCRIPT ERROR`/`Parse Error` in the output, then runs the tests.

---

## Phase 1: Foundation and asset pipeline

Set up the project on Godot 4.6 with standards, folder layout, the minimal test runner, autoload skeletons and only the needed asset subsets copied in.

**Tasks**
- [x] User installs Godot 4.6.x stable. Open the project and accept the upgrade. Set `config/features` to 4.6 and the renderer to **Forward+** in `project.godot`.
- [x] Initialise git (`git init`). Extend `.gitignore` with `assests/*.zip`, `.godot/`, `*.tmp`, `/export/`. **Ask the user before the first commit.**
- [x] Add `assests/.gdignore` (new empty file) so Godot never imports the 2.6 GB of zips.
- [x] Write `tools/extract_assets.py` (run with `python -I`, reads the zips, writes **copies** only): extract `characters/<name>/sheets/`, `godot/`, `<name>.json` and `LICENSE.txt` for knight, wolf, goblin-scout, skeleton and blade-assassin (+ phase-two), plus `effects/` for the boss. For village, courtyard and necropolis, extract at full size (no `_sizes/64`) the default root palette and `ColourVariations/ash/`, plus `slate` for village and courtyard and `frost` for necropolis. Extract weather `overlays/`, `effects/lightning_*` and `godot/`. From `Gimbles_Dark_Fantasy_Kit_Sampler_Free_v1.0.zip`, extract `ui/2x/`, `ui/ui_index.json`, `item_icons/64px/`, `hud_icons/64px/`, `portraits/framed/256px/`, `portraits/transparent/128px/`, `backgrounds/1920x1080/`, `palette/`, `LICENSE.txt` and `README.txt` → `assets/vendor/gimbles/`. From `All Assets.zip`, extract the 38 `dfgui_*.png` files (not `screenshots/`) → `assets/vendor/dfgui/1x/`. Copy the vendor MIT-0 scripts and shaders (`godot/ambience/`, `godot/weather/`) from the necropolis pack → `addons/sovdigital/`. Skip `frames/`, `_smooth`, `_sizes`, `previews`, `ColourVariations/recolour_masks`, and skip `ColourVariations` except: skeleton `charred`, wolf `black`, knight `black`/`gold`.
- [x] Verify the vendor `SpriteFrames` and `TileSet` `.tres` files load from their new location (relative paths are preserved).
- [x] Import settings: `assets/vendor/gimbles/` and `assets/vendor/dfgui/` use texture filter **Nearest** with mipmaps off. All SovDigital world and character PNGs use **`mipmaps/generate = true`**, needed for clean downscaling at camera zoom 0.75. Apply both through per-folder import defaults and re-import.
- [x] `tools/upscale_ui.gd` (`extends SceneTree`, run with `"$GODOT" --headless --path . -s res://tools/upscale_ui.gd`): for every PNG in `assets/vendor/dfgui/1x/`, `Image.resize(w*2, h*2, Image.INTERPOLATE_NEAREST)` → `assets/vendor/dfgui/2x/`. Called by `tools/check.ps1` when `2x/` is missing.
- [x] `tools/verify_source_assets.py` + `tools/source_assets.sha256`: SHA-256 of every zip in `assests/` recorded at the start of Phase 1, then verified by `check.ps1`.
- [x] Project settings: 1920×1080, `canvas_items`/`expand`, default texture filter linear+mipmaps, input actions (§3), physics layer names, GDScript warnings `untyped_declaration = Error`, `unsafe_*` = Warn, `exclude_addons = true` (the default, which keeps vendor scripts in `addons/` exempt).
- [x] Autoload skeletons with typed signals and empty APIs: `scripts/autoload/game_state.gd`, `scene_manager.gd`, `audio_manager.gd`, `save_manager.gd`, `dialogue_manager.gd`.
- [x] Audio foundation (per `AUDIO_GUIDELINES.md` §5): `default_bus_layout.tres` (Master → Music, Ambience, SFX, UI), `AudioManager` with child `MusicManager`/`SFXManager`/`AmbientAudioManager` (APIs stubbed, pools created), Resources `MusicTrack`, `SfxSet`, `AmbienceProfile`, `AmbienceLayer`.
- [x] ~~`tools/make_placeholder_audio.gd`~~ **Dropped (user decision 2026-11-13: no generated audio or assets).** Audio tests build streams in memory (`AudioStreamWAV` with an empty or silent buffer) instead of writing files. Real audio is provided by the user.
- [x] `docs/asset_manifest.csv` with columns `path, name, creator, source_url, license, commercial_use, attribution, format, usage, original_location, release_blocker`. Add one row per vendor pack folder (SovDigital packs, Gimble's, dfgui with `release_blocker = yes`), fonts and placeholder audio.
- [x] `scenes/boot/main.tscn` with a placeholder title screen (New Game, Quit) and a `fade_overlay.tscn`.
- [-] Typography (per `FONT_CATALOG.md` §4) — **FontVariations, type variations and theme wiring done; waiting for the user to add the font files, then re-run `tools/build_theme.gd`**: user drops Alegreya and Cinzel TTFs + `OFL.txt` into `assets/fonts/`. Create the `FontVariation` resources and the Theme type variations `TitleLabel`, `HeaderLabel`, `NameLabel`, `BodyLabel`, `LoreLabel`, `SmallLabel`, `NumericLabel` (`lnum`/`tnum`), `DamageNumber`. Set `gui/theme/custom` to the main theme.
- [x] `scenes/ui/theme/ui_palette.tres` (`UIPalette` Resource with the `ART_GUIDELINES.md` §3 tokens), used by the Theme and by code-drawn UI (damage colours).
- [x] `scenes/ui/debug/typography_specimen.tscn`: every type variation on Gimble's panels, with a 1080p/720p toggle.
- [x] `scenes/ui/theme/main_theme.tres`: default font = `font_body` (Alegreya 30; falls back to Godot's default font while the files are absent), `PanelContainer` → `StyleBoxTexture` from Gimble's `panel_iron_9slice.png` (2×: 32 px margins, axis stretch **Tile**), tooltip from `panel_iron_tooltip_9slice.png` (16 px margins). `Button` normal/hover/pressed/disabled from the four `button_red_*_9slice.png` files (2×: left/right 16 px, top/bottom 0, Tile). Colours from the kit palette (§3).
- [x] `tests/test_case.gd` (assert_eq, assert_true, assert_almost_eq, assert_null) and `tests/test_runner.gd` (discovers `res://tests/unit/test_*.gd` and `res://tests/smoke/test_*.gd`, runs each `test_*` method, prints a summary, `quit(1 if failures > 0 else 0)`).
- [x] `tools/check.ps1` + `tools/check.sh`.
- [x] `CONTRIBUTING.md` with the coding standards (§10) and `CREDITS.md` (SovDigital; Gimble's Games; Alegreya/OFL).

**Automated verification**
- [x] `tests/unit/test_sanity.gd` passes (the runner itself works: one passing test, plus an inverted check that a failing assert is detected).
- [x] `tests/smoke/test_vendor_resources.gd`: `load()` of knight/wolf/goblin/skeleton/boss SpriteFrames returns non-null and has animations `idle_E`, `idle_W`, `attack_E`, `hurt_W`, `death_W`. Village and necropolis TileSets load.
- [x] `tests/smoke/test_ui_assets.gd`: every piece listed in `ui_index.json` exists in `ui/2x/` at exactly 2× the listed size; `main_theme.tres` loads and its panel StyleBox margins equal 2× the vendor `nine_slice` values. Every file in `dfgui/2x/` is exactly 2× its `1x/` source.
- [x] `tests/smoke/test_all_scripts_parse.gd`: `load()` every `.gd` under `res://scripts`, `res://scenes`, `res://tests` and `res://tools`. Each returns a non-null `GDScript` whose `can_instantiate()` is true. This catches parse errors in scripts that `--import` never compiles.
- [x] `tests/smoke/test_theme_typography.gd`: every type variation listed in `FONT_CATALOG.md` exists in `main_theme.tres`; body size ≥ 28, small size ≥ 22; `NumericLabel` font has `lnum` and `tnum` enabled; all `UIPalette` tokens are non-transparent.
- [x] `tests/unit/test_audio_buses.gd`: buses Master/Music/Ambience/SFX/UI exist with the documented routing; `AudioManager` has the three child managers.
- [x] `tests/smoke/test_asset_manifest.gd`: every file under `res://assets/` and `res://addons/sovdigital/` is covered by a manifest row (by path prefix); no row has an empty licence field; no row has `commercial_use = no`; rows with `release_blocker = yes` are listed in the test output.
- [x] `tools/check.ps1` exits 0 with no parse errors.
- [x] `python -I tools/verify_source_assets.py` exits 0: the `assests/` zip checksums are unchanged. It also runs inside `check.ps1` in every phase.

**Manual verification**
- [ ] The project opens in Godot 4.6 without errors in the Output panel. F5 shows the title screen with Alegreya text (or the default font if the files are not yet present) and red Gimble's buttons on an iron panel. Hover and press change the button art, and the edges stay crisp (no blur) at 1080p. "Quit" closes the game.
- [ ] Run `typography_specimen.tscn` (F6): all styles read comfortably at 1920×1080 fullscreen and at 1280×720 windowed. HP-style numbers don't shift width when changing. The user confirms the Cinzel + Alegreya pairing (or picks alternatives, which updates `FONT_CATALOG.md`).

**Deliverables:** an upgraded, clean project; the asset subset (~a few hundred MB instead of 2.6 GB); the test harness; standards documentation.

---

## Phase 2: Exploration prototype

[Dependencies: **Phase 1**]

Walk the Knight around one atmospheric village map with collision, Y-sorting and a following camera.

**Tasks**
- [x] `scenes/world/map.gd` (`class_name Map extends Node2D`): exports `map_id`, `display_name`, `music: MusicTrack`, `ambience: AmbienceProfile` (audio), `ambience_preset` (visual mood for the vendor controller). Provides `get_spawn(id) -> SpawnPoint` and `get_camera_bounds() -> Rect2`.
- [x] `scenes/world/components/spawn_point.gd` (`class_name SpawnPoint extends Marker2D`, `spawn_id: StringName`, `facing: StringName`). `village_01` gets a `start` spawn.
- [x] `scenes/world/maps/village_01.tscn`: ground block (ash `mud-street`/`village-grass`), terrain TileMapLayer, y-sorted `World` with cottages (incl. damaged/ruined), wall runs, fence, market stall, notice board, oak trees. `CanvasModulate` + vendor ambience controller preset `dusk`, fog overlay. `CameraBounds` ReferenceRect.
  - *As built (2026-11-13):* generated by `tools/build_village_01.gd` (since Phase 3: `tools/map_builders/village_01_builder.gd`, run via `tools/build_maps.gd`) (the layout's source of truth until the map is hand-edited). Ground = vendor grass pattern; streets = terrain set 1 (transparent mud overlay). Terrain set 0 was rejected: it shows a tile grid on the grass and its navigation polygons overlap. Pieces are **prop scenes** (`scenes/world/props/village/*.tscn`: Sprite2D + StaticBody2D footprint from `biome.json`, origin = base) instead of atlas tiles, because the TileSet doesn't record which atlas tile is which piece. Animated/breakable pieces use the vendor scenes. A `Boundary` StaticBody2D keeps the player inside; the south fence leaves a gap for the Phase 3 exit.
  - *Fixes after the first manual test (2026-11-13):* the vendor building footprint only covers the ground band at the bottom of the image, so the Knight walked into house walls from the sides. Each building now also has a `HouseBlock` (footprint width, 192 px up from the footprint top). The walk cycle was sliding: a planted foot moves at ≈125 px/s at the vendor's 20 fps, so walk playback now scales with real ground speed. `walk_speed` went from 260 → 220 px/s so the legs aren't frantic. Idle (breathing) plays at 0.5×. 2D physics interpolation is on, with the camera on physics process, to remove the jitter.
  - *Second round (2026-11-13):* the corner problem was **draw order**: buildings sorted at the bottom of their image (the far edge of the cobble apron), so a Knight on the apron was drawn behind the house. Building prop scenes now have their origin (Y-sort point) at the front wall line (the top of the vendor footprint). `cottage-smoke` is now a generated prop scene too. The vendor `walk_*` cycle mostly moves one leg (it reads as gliding), so field movement uses the vendor `run_*` cycle. Its playback is tied to ground speed (planted foot ≈200 px/s at 24 fps → about 1.1× at 220 px/s).
- [x] `scenes/world/player/player.tscn` + `player_controller.gd`: `CharacterBody2D`, horizontal `CapsuleShape2D` feet collider, `AnimatedSprite2D` with `knight_spriteframes.tres`, `walk_speed`, `input_enabled: bool`. A pure static helper `PlayerController.dir_from_vector(v: Vector2) -> StringName` gives 8-sector mapping (optional `fallback` argument = last direction for a zero vector).
- [x] `follow_camera.gd`: zoom 0.75, smoothing, limits from the map.
- [x] Debug overlay (F3, debug builds only): FPS, player position, current zone. → `scenes/ui/debug/debug_overlay.tscn`, added by `Map` (zone shows `none` until Phase 6).

**Automated verification**
- [x] `test_player_direction.gd`: `dir_from_vector` maps the 8 cardinal/diagonal vectors and boundary angles (22.5° ± ε) correctly; zero vector keeps the last direction.
- [x] `test_scene_smoke.gd`: `village_01.tscn` and `player.tscn` instantiate headless, run 3 frames, and `Map.get_camera_bounds()` has positive area. Also: camera limits = bounds, `start` spawn inside the map, the player is a y-sorted sibling of the props, a cottage footprint stops the player, debug overlay text.
- [x] `tools/check.ps1` exits 0. (Run as `tools/check.sh` from WSL: 29 tests, 0 failures.)

**Manual verification**
- [ ] F6 on `village_01.tscn`:
  1. Move in all 8 directions with keyboard and gamepad; the walk animation matches direction, and idle faces the last direction.
  2. Walk behind a cottage: the Knight is hidden by the roof. Walk in front: the Knight is drawn over it.
  3. Walls, fences and props block movement. No sliding through corners.
  4. The camera never shows outside the map bounds.
  5. Steady ≥ 60 FPS on the development PC.

**Deliverables:** first explorable map and reusable player scene.

---

## Phase 3: Map transitions and interaction

[Dependencies: **Phase 2**]

Two connected maps, fade transitions with correct spawn and facing, and examinable objects.

**Tasks**
- [x] `SceneManager.change_map(map_path: String, spawn_id: StringName)`: fade out (0.35 s; skipped when `instant_transitions` is true for tests), free the old map, instance the new one, place the player at the spawn with its facing, fade in. Input is blocked during the transition. Emits `map_changed`.
  - *As built (2026-11-13):* the map becomes `current_scene` (the title screen is replaced the same way; **New Game** on the title now starts at `village_01`/`start`). `is_transitioning` ignores further requests until the fade-in ends. Placement is `Map.place_player(spawn_id)` (snaps the camera, resets physics interpolation). `GameState.current_map` is set.
- [x] `components/map_transition.tscn/.gd` (Area2D, exports `target_map: String`, `target_spawn: StringName`). Each map gets `SpawnPoint`s for every entry.
  - *As built:* also exports `size`. It calls `change_map` **deferred** (the old map can't be freed inside a physics callback) and only for a player whose input is on. Village: `ToGraveyard` over the south fence gap, spawn `from_graveyard`. Graveyard: `ToVillage` below the gate, spawn `from_village`. Both spawns face away from the gate, ~200 px clear of the trigger.
- [x] `maps/graveyard_01.tscn`: necropolis tiles (ash palette), crypt, graves, gnarled trees, bone pyre (lit, PointLight2D), iron fence, fog + night ambience. An exit back to the village.
  - *As built:* generated by `tools/map_builders/graveyard_01_builder.gd` (props in `scenes/world/props/necropolis/`). The village and graveyard builders now share `tools/map_build_kit.gd` (the village output is unchanged apart from the new exit, spawn and notice-board interactable). Both run through `tools/build_maps.gd`, which loads the builders after the first frame: in `-s` mode, autoload names are unknown while the main script compiles, and the player/components now refer to `DialogueManager`/`SceneManager`. In the ash palette, the path (bone-flags) and the soil overlay are both stone, so the path reads through slab size rather than colour.
- [x] `player/interaction_probe.gd` (Area2D offset toward facing) + `components/interactable.tscn/.gd` (`signal interacted(by: Node)`, export `prompt_text`, `dialogue_id`). Shows an "▲ Examine" prompt label.
  - *As built:* the prompt is a Label on the Interactable (z 50, outlined), shown while the probe focuses it. New helpers: `PlayerController.can_act()` (input on and no dialogue open) and `PlayerController.vector_from_dir()`.
- [x] Minimal `DialogueManager.start(id)` that can show a **single-line** message (full dialogue arrives in Phase 7). `dialogue_box.tscn` using the theme.
  - *As built:* plays a file's lines in order (speaker optional); `set_flag`, `give_item`, `goto` and `choices` are validated but not run until Phase 7. The box swallows `accept` while open, and ignores the press that opened it. Loader and schema: `scripts/dialogue/dialogue_data.gd` (`DialogueData`).
- [x] Examine texts for three graveyard objects (e.g. headstone, sarcophagus, notice board) in `data/dialogue/examine_*.json`.
  - *As built:* `examine_headstone`, `examine_sarcophagus`, `examine_bone_pyre` (graveyard) and `examine_notice_board` (village). The texts are atmospheric only and commit to no story concept.

**Automated verification**
- [x] `test_scene_manager.gd` (with `instant_transitions = true`): `change_map` to `graveyard_01` with spawn `from_village` places the player within 1 px of the spawn marker, with the expected facing; an unknown spawn id falls back to the first spawn and pushes a warning. Also: the old map is freed, `map_changed` fires once, requests during a transition are ignored, and walking into the village exit loads the graveyard.
- [x] `test_dialogue_json.gd`: every file in `data/dialogue/` parses and conforms to the schema (required keys, valid `goto` targets). Also: the §4.7 example is valid; out-of-range/fractional/unknown `goto`, missing parts, id mismatch, unknown keys and unknown `conditions.use` are rejected.
- [x] Extra: `test_map_links.gd` (every exit leads to an existing map and spawn; no spawn lies inside an exit; exits are reachable) and `test_interaction.gd` (facing focuses the headstone, facing away doesn't, interacting opens the box with the first line, blocks movement and a second interaction, and closing restores the prompt).
- [x] `tools/check.ps1` exits 0. (Run as `tools/check.sh` from WSL: 53 tests, 0 failures.)

**Manual verification**
- [ ] Walk village → graveyard → village: fades are smooth, the player appears at the correct gate facing away from it, and there is no double-trigger loop.
- [ ] Face a headstone and press accept: the message box appears with Alegreya text. Accept closes it, and the player cannot move while it is open.

**Deliverables:** world structure and the interaction foundation.

---

## Phase 4: Battle core (logic only, headless)

[Dependencies: **Phase 1**]

The complete rules engine for round-based combat as pure, deterministic, unit-tested code.

**Tasks**
- [x] Resources: `stat_block.gd`, `skill_data.gd`, `skill_unlock.gd`, `status_effect_data.gd`, `combatant_visual.gd` (class only; the visual `.tres` files come in Phase 5, and `visual` may be null in tests), `item_data.gd` (minimal: id, name, icon, battle/field use, target, effect, amount), `enemy_data.gd` (incl. `phase_two`), `character_data.gd`, `ai_profile.gd`, `drop_entry.gd`, `growth_curve.gd`, `elements.gd` (enum + helpers), `battle_setup.gd` (Resource, so it can be `@export`ed), `battle_result.gd`.
  - *As built (2026-11-15):* resources in `scripts/resources/`, `elements.gd` and a new `targeting.gd` (`Targeting.Mode`, shared by skills and items) in `scripts/rpg/`. Additions to §4.7: `SkillData.effect` (DAMAGE/HEAL); `StatusEffectData.duration_turns_max` (Sleep 2–4), `regen_percent`, `healing_received_mult`, `element` (Burn = FIRE, so FIRE-immune targets ignore it) and `tag_text`; `AIProfile.attack_weight`. `BattleSetup` also has `is_rare` and `intro_text`. `BattleResult` carries `xp`, `xp_per_member` (rounded up), `gold`, `drops`, `survivors`, `defeated_enemy_ids` and `rounds`.
- [x] `active_status.gd` (RefCounted: `data: StatusEffectData`, `turns_left: int`).
- [x] `combatant.gd`: wraps data with runtime `hp`, `mp`, `statuses: Array[ActiveStatus]`, `is_defending`, `side`. Has `effective_stat(name)`, `is_alive()`, `can_act()`.
  - *As built:* the side enum is `Combatant.Team` (the field is still `side`): `Side` clashes with Godot's global `Side` enum. Duplicate enemies get letters ("Wolf A", "Wolf B"). Defeat clears statuses.
- [x] `battle_action.gd` (actor, kind ATTACK/SKILL/ITEM/DEFEND/FLEE, skill, item, targets) and `battle_event.gd` (Type enum + payload).
- [x] `damage_calculator.gd`: static `physical()`, `magical()`, `heal()`, `is_critical()`, `element_multiplier()`. RNG passed in.
- [x] `turn_order.gd`: static `sort(actions, rng) -> Array[BattleAction]` (Defend first, then agility × variance).
  - *As built:* priority Flee > Defend > the rest, then agility × 0.85–1.15; ties keep submission order (party before enemies).
- [x] `status_effects.gd`: `apply()`, `tick_round_end() -> Array[BattleEvent]`, `modifies_stat()`, `blocks_action()`.
  - *As built:* durations count down at round end, but a turn-skipping status (Sleep, Stun) applied after its holder acted is not counted that round, so Stun always costs exactly one turn. Magic damage uses the same ±12.5% variance as physical damage (the plan only gave variance for physical).
- [x] `action_resolver.gd`: executes one action → events. Retargets if the target died (DQ rule: pick another living enemy). Spends MP, consumes items via a callback interface (no Inventory dependency yet: `consume_item: Callable`).
  - *As built:* offensive actions retarget to a random living enemy; supportive ones retarget to the most wounded living ally. A multi-hit skill moves on to a new target when its target dies. Physical skill `power` is a percentage of a basic attack. Flee is a party-wide command: it replaces the party's other actions, so a failed escape costs the party its round. Chance = 0.5 + 0.025 × (party − enemy average agility), clamped to 0.1–0.95. It is refused when `can_flee` is false or `is_boss` is true.
- [x] `enemy_ai.gd`: `choose(enemy, engine) -> BattleAction` per `AIProfile`.
- [x] `battle_engine.gd`: the API from §4.6 (`setup`, `begin_round`, `has_next_action`, `execute_next`, `end_round`, `outcome`, `compute_rewards`). When an enemy with `phase_two` crosses `phase_two_at_hp_pct`, it swaps data and emits `PhaseChange` once.
  - *As built:* the engine's round counter is `round_number` (`round` shadows the global function). The second form keeps the current HP ratio and statuses; rewards come from the final form. Engine checks for phase changes after every action and after status ticks.
- [x] Data: `data/enemies/wolf.tres`, `goblin_scout.tres`, `skeleton.tres`, `skeleton_charred.tres`; `data/skills/attack_basic.tres`, `whirlwind.tres`, `charged_strike.tres`, `ember.tres` (fire magic), `minor_heal.tres`; `data/characters/knight.tres`; `data/items/minor_potion.tres` (icon `052_health_potion`); `data/status_effects/bleed.tres`, `burn.tres`, `curse.tres`, `blessed.tres`, `sleep.tres`, `stun.tres`.
  - *As built:* generated by `tools/build_battle_data.gd` (`"$GODOT" --headless --path . -s res://tools/build_battle_data.gd`), the source of truth for the numbers until they are hand-tuned. Re-running it overwrites the files. Knight starts with Whirlwind, Ember and Minor Heal, and learns Charged Strike (20% Stun) at level 3. Ember has a 25% Burn chance. Skeletons are immune to Bleed and Sleep; the Charred Skeleton is also immune to FIRE and Burn. Since Phase 5 the same tool also writes the `CombatantVisual`s and links them.

**Automated verification** (all unit tests, seeded RNG)
- [x] `test_damage_calculator.gd`: physical min 1, variance bounds, crit ignores defence, weakness ×2, resistance ×0.5, immunity 0, Defend ×0.5, clamp 9999, heal formula.
- [x] `test_turn_order.gd`: higher agility goes first with variance disabled; Defend always first; stable tie-break; same seed gives same order.
- [x] `test_status_effects.gd`: bleed ticks 5% and expires after duration; burn does nothing to FIRE-immune targets; curse halves healing received; blessed regen never exceeds max HP; sleep skips the action and is removed on hit; stacking rules (refresh, not stack).
- [x] `test_action_resolver.gd`: retarget on dead target; MP is deducted and an action with insufficient MP is rejected; `ALL_ENEMIES` hits every living enemy; the item callback is invoked.
- [x] `test_enemy_ai.gd`: weights respected over 10,000 seeded picks (±3%); `LOWEST_HP` picks the lowest.
- [x] `test_battle_engine.gd` (integration, fixture `StatBlock`s, no Progression needed): a fixture Knight (HP 120, ATK 30, DEF 20, AGI 12) vs 2 Wolves with auto-attack reaches VICTORY within 20 rounds, rewards = sum of xp/gold, and the event stream contains a `Defeated` event per enemy. Weak Knight vs 3 Skeletons → DEFEAT. Flee success/failure is deterministic per seed. A fixture boss `EnemyData` with `phase_two` crossing 50% HP emits `PhaseChange` exactly once.
- [x] Extra: `test_battle_data.gd` (every data file loads with an id matching its file name; the affinities from §6.3; status icons and tags; the real Knight beats two real Wolves by attacking).
- [x] `tools/check.ps1` exits 0. (Run as `tools/check.sh` from WSL: 124 tests, 0 failures.)

**Deliverables:** a complete, tested combat ruleset with no visuals.

---

## Phase 5: Battle presentation

[Dependencies: **Phase 4**]

A side-view battle scene that drives `BattleEngine` and visualises its events with vendor animations and the Gimble's UI.

**Tasks**
- [x] `CombatantVisual` `.tres` files (class from Phase 4) for knight (E), wolf, goblin, skeleton and charred skeleton (W), with the anim maps from §6.3 and `hit_frame` read from vendor JSON (or set by eye).
  - *As built (2026-11-15):* `data/visuals/*.tres`, generated by `tools/build_battle_data.gd` (feet offset from the vendor JSON pivot). The class gained `move_frames` (the Knight's moves live in separate vendor SpriteFrames; the tool checks each move cell is centred on the base cell so the body never jumps), `hit_frames` per logical animation (Knight moves from the vendor `hit_frames`), `last_frames` (cast = Charged Strike frames 0–6) and `height` (visible height above the feet, measured on the idle sheets: places HP bars, popups and the cursor). Base-attack hit frames were measured as the frame where the sprite reaches furthest (Knight 4, Wolf 8, Goblin 5, Skeleton 3). Whirlwind uses the `whirlwind_ring` sheet (spin with its wind effect). Skeletons have no second attack, so their `skill`/`cast` fall back to `attack`. All battlers at `battle_scale` 1.2.
- [x] `battle/battle_sprite.tscn/.gd`: `AnimatedSprite2D` + FX layer. `play_logical(anim) -> await`, `flash()`, `step_forward()/step_back()` tweens, stand-ins for cast/defend/victory, death handling. Emits `hit_frame_reached`.
  - *As built:* the async API is split into `start_logical(anim)` / `await wait_hit()` / `await wait_finished()`, so the presenter can show damage on the hit frame without racing the signal. There is no separate FX layer yet: the only Phase 5 effects are drawn into the vendor move sheets (`fx_player` arrives with the boss FX, Phase 10). The soft elliptical shadow and the enemy HP bar are part of the sprite (they follow it), not of the background. `instant` mode skips every animation and tween.
- [x] `battle/backgrounds/graveyard_bg.tscn`: Gimble's `08_graveyard.png` (1920×1080, Nearest) + vendor fog overlay + soft elliptical shadow sprites under each battler slot. Slots are placed on the open dirt band (≈ y 650–900).
  - *As built:* generated by `tools/build_battle_backgrounds.gd`. The fog is on CanvasLayer 1 (over the battlers, under the UI). The dirt band in the painting is ≈ y 620–850 and the HUD starts at y 848, so the slots' feet are at y 620–775.
- [ ] **Style check (go/no-go at the end of this phase):** compare `graveyard_bg.tscn` against `graveyard_composite_bg.tscn` (necropolis ground block, iron fences, gnarled tree, headstones, fog; same 3/4 angle as the battlers). The user picks one, and the chosen approach becomes the rule for all regions.
  - *Ready for the user:* both scenes exist (`tools/build_battle_backgrounds.gd`). The composite uses the bone-flag paving as the arena band, ash soil elsewhere, the north wall, two gnarled trees, headstones, grave mounds, an obelisk and lantern posts, a night `CanvasModulate` and the same fog. To compare, set `setup.background` in `debug_battle.tscn` to either scene and press F6. **Waiting for the user's pick.**
- [x] `battle/battle_scene.tscn`: background, `PartySlots` (3 Marker2D, left, staggered), `EnemySlots` (up to 5 Marker2D, right), `UI` CanvasLayer → root `Control` with texture filter Nearest (CanvasLayer itself has no filter property).
  - *As built:* also a fixed `Camera2D` at the screen centre (physics process, for physics interpolation), so battlefield and UI share one coordinate space even after the world camera is detached in Phase 6, and a y-sorted `Battlers` node.
- [x] `scenes/ui/widgets/stat_bar.tscn/.gd`: a `TextureProgressBar` per bar using the **dfgui ×2** bar set (`AtlasTexture` regions from `dfgui_partyhud.png`): gold-capped frame as `texture_over`, and the red (HP), blue (MP) or purple (XP) fill as `texture_progress`. Exports `value`, `max_value` and a `label` drawn in Alegreya ("112/130"). The Gimble's `bar_frame_9slice` + red tiled fill is used for **enemy/boss HP** above battlers, so the two bar styles separate party from enemies.
  - *As built:* the dfgui frame's tube is **opaque**, so it can't be `texture_over`. `StatBar` is a Control with NinePatchRects instead: the frame (290×40, 20 px gold caps), then the fill drawn over the 250 px tube and sized to the value. Atlas regions were measured on the ×2 atlas (frame `116,46 290×40`; fills HP `116,88 250×30`, MP `116,180 118×24`, XP `116,154 118×24`). The MP/XP fills are 24 px tall, so they sit centred instead of being stretched to a non-integer height. One script, `style` = PARTY_HP / PARTY_MP / PARTY_XP / ENEMY_HP; the enemy style tiles Gimble's segmented fill over the empty fill. `set_values(value, max, animate)` slides the fill.
- [x] `battle/ui/battle_hud.tscn`: party rows with name, HP and MP `StatBar`s, and status icons (Gimble's 64 px HUD icons scaled to 32 px, Nearest) or text tags for Sleep/Stun.
- [x] `battle/ui/command_menu.tscn` (Gimble's iron panel, gauntlet cursor): Attack/Skills/Magic/Items/Defend/Flee, each with a dfgui ×2 icon (sword, skill book, wand, pouch, shield; Flee text-only), keyboard and gamepad focus, submenus listing skills with MP cost (greyed if unaffordable), cancel goes back.
  - *As built:* rows are a `MenuList` (`scenes/battle/ui/menu_list.gd`), not Buttons: it reads the project actions itself (`move_*`, `accept`, `cancel` plus `ui_*`), so keyboard and gamepad behave the same and no focus-neighbour setup is needed. The mouse can hover and click. The red Gimble's buttons are not used here: rows are text + icon on the iron panel, which keeps the 52 px dfgui icons at whole-pixel scale. Skills/Items open a second panel with the description of the highlighted entry. Cancel on the first member does nothing; on later members it steps back. The menu reopens on each member's last command.
- [x] `battle/ui/target_selector.tscn`: Gimble's `cursor_gauntlet_16` (2×) pointing at targets, left/right cycles, supports ONE/ALL modes.
  - *As built:* the cursor bobs over the head with the target's name above it. ALL mode shows a cursor on every candidate and still asks for a confirm. Revive items list fallen allies.
- [x] `battle/ui/damage_popup.tscn` (rising number, crit/weak/heal styles) and `battle_message.tscn` (top message line).
- [x] `battle/battle_presenter.gd`: `play(events: Array[BattleEvent]) -> await` maps each event type to sprite and UI actions, with timing constants in one place.
  - *As built:* one action's events play as a unit: the message, the step forward, the attack or move animation, then **all the effects together on the hit frame** (reactions, popups and deaths run concurrently and are awaited together), then the step back. Spells glow in their element colour (healing green) during the cast animation. Because the engine's state is already final when the events arrive, the presenter keeps its own *shown* HP/MP and moves it event by event (multi-hit damage counts down hit by hit), then resyncs at `ROUND_ENDED`. Status ticks play one by one at round end.
- [x] `battle/battle_controller.gd`: async loop (§6.3), collects party commands, queries AI, resolves, presents, ends with `finished(result)`.
  - *As built:* `class_name BattleController` on the scene root, `await start(setup, party, rng, items) -> BattleResult`. Battle items are a `Dictionary[ItemData, int]` passed in (the Inventory arrives in Phase 9); using one goes through the engine's `consume_item` callback. `auto_battle` (party attacks the first living enemy) and `instant` are exports for tests. Choosing Flee ends the command phase at once (the whole party runs, §6.3).
- [x] `battle/ui/results_screen.tscn`: XP, gold, drops, level-ups.
  - *As built:* XP, gold and drops (grouped: "Found: Minor Potion ×2"). Level-ups are added with Progression in Phase 7.
- [x] Debug launcher: `scenes/battle/debug_battle.tscn` with an exported `BattleSetup` to start any fight with F6.
  - *As built:* also exports `party`, `extra_skills` (Charged Strike, so it can be tried at level 1), `party_hp` (1 = check defeat), `items` (3 Minor Potions), `rng_seed`, `auto_battle` and `loop` (restart after each fight).

**Automated verification**
- [x] `test_battle_presenter_mapping.gd`: for every `BattleEvent.Type`, the presenter has a handler (no unhandled types).
- [x] `test_combatant_visuals.gd`: for every `CombatantVisual` in `data/`, every mapped animation name exists in its SpriteFrames (or is in the documented stand-in list).
- [x] `test_battle_scene_smoke.gd`: headless instantiate with a 1-vs-1 setup and an auto-controller (party auto-attacks, presenter in instant mode). The battle reaches VICTORY and emits `finished` with correct rewards within 5,000 processed frames (a frame count, not wall-clock time).
- [x] Extra: the smoke test also drives the real menus in instant mode (Attack round; cancel from the target selector; Whirlwind hits both enemies and the HUD shows the MP drop; an unaffordable skill is greyed and can't be picked; Defend; the first member can't cancel), checks the layout (party left/right facing, enemy HP bars, HUD rows) and a defeat. The mapping test also covers action texts, spell colours, intro text and the drops line. Outside the suite, full real-time battles (not instant) were run headless with `--fixed-fps 60` through every command kind to check that every await resolves.
- [x] `tools/check.ps1` exits 0. (Run as `tools/check.sh` from WSL: 144 tests, 0 failures.)

**Manual verification**
- [ ] F6 `debug_battle.tscn` (Knight vs Wolf + Goblin):
  1. The party is on the left facing right, enemies on the right facing left, and feet sit on the ground line.
  2. Attack: the Knight steps forward, swings, the number pops on the hit frame, the target plays hurt, and the Knight returns.
  3. Skills → Whirlwind hits both enemies; MP drops in the HUD.
  4. Magic → Ember vs Wolf shows "WEAK!" and double damage.
  5. Defend: tint and stance; incoming damage is visibly halved.
  6. Victory → results screen; defeat (set Knight HP to 1 in the debug setup) → defeat message.
  7. All menus work fully with a gamepad.

**Deliverables:** a playable side-view battle (debug-launched).

---

## Phase 6: Random encounters

[Dependencies: **Phase 3**, **Phase 5**]

Region-based random encounters that move the player from the world to battle and back seamlessly.

**Tasks**
- [x] `encounter_group.gd`, `encounter_table.gd`, `boss_encounter.gd` Resources.
  - *As built (2026-11-15):* in `scripts/resources/`. `EncounterGroup` also has `intro_text` and `is_eligible(flags)`; `EncounterTable.music` is a `MusicTrack` (like `BattleSetup.music`), not a raw `AudioStream`. `BossEncounter` has `is_available(flags)` and `make_setup()` (no flee, `is_boss`); its `BossTrigger` is still Phase 10.
- [x] `battle/encounter_roller.gd` (pure): `should_trigger(steps_since_last, table, multiplier, rng) -> bool`, `pick_group(table, flags, rng) -> EncounterGroup`.
  - *As built:* `scripts/battle/encounter_roller.gd`. `steps_since_last` includes the current step, so steps 1…`grace_steps` never roll. Also `make_setup(group, table) -> BattleSetup`.
- [x] `components/encounter_zone.tscn/.gd` (Area2D + CollisionPolygon2D, export `table`).
  - *As built:* also exports `polygon` (copied to the child shape) and has `contains_point()`. Graveyard: one zone `Encounters/GraveyardOutskirts` over the whole walkable ground (crypt wall to fence), added by `tools/map_builders/graveyard_01_builder.gd` via `MapBuildKit.encounter_zone()`. Rebuilding the map re-rolled the random terrain variants (cosmetic only).
- [x] `player/encounter_tracker.gd`: zone stack, distance accumulator (64 px per step), grace steps, emits `encounter_triggered`.
  - *As built:* a child node of `player.tscn` (`PlayerController.encounter_tracker`). Steps only count while `can_act()`. A step that starts a battle drops the rest of that frame's distance. Zones report an exit when the world is detached for a battle and re-report the player when it is re-attached, so an exit is ignored while the feet are still inside the zone outline, and re-entering a zone already on the stack changes nothing (the stack order survives a battle). Grace resets on map entry, after a battle and on `DialogueManager.dialogue_finished`. The `Map` connects `encounter_triggered` and calls `start_battle` deferred.
- [x] `SceneManager.start_battle(setup)` / `end_battle(result)` with world detach/re-attach and a battle intro transition (shatter/fade shader or simple flash + fade).
  - *As built:* two pale flashes (`FadeOverlay.flash`), fade out, map removed from the tree (kept), battle added, fade in while the intro message plays. `start_battle` awaits the battle and calls `end_battle` itself and returns the `BattleResult` (null when ignored: busy or empty setup). The party is `GameState.party` and the items `GameState.battle_items()`; what is left is written back. On return the world camera is made current again and grace restarts. Defeat → a minimal `game_over()`: drop the battle and the map and return to the title (the Game Over screen is Phase 7). Signals now typed: `battle_started(setup)`, `battle_ended(result)`. Test switches: `instant_battles`, `auto_battles`, `battle_rng`. A new fade jumps a running one to its end, so an awaited fade never hangs.
- [x] `scripts/rpg/rate_modifier.gd`, `GameState.encounter_rate_modifiers` + `get_encounter_multiplier()`; `EncounterTracker` decrements `steps_left` and removes expired modifiers.
  - *As built:* the counting is `RateModifier.tick()` / `product()` (static, testable), and `GameState.add_encounter_modifier(id, mult, steps)` / `remove_encounter_modifier` / `tick_encounter_modifiers` wrap them.
- [x] Minimal `GameState.apply_battle_rewards(result)`: gold and item counts (`items: Dictionary[StringName, int]`). XP and levels are added in Phase 7.
  - *As built:* plus `add_item`/`item_count`/`set_item_count` and `items_changed`. Until `Party`/`PartyMember` exist (Phase 7), `GameState.party: Array[Combatant]` holds the Knight (built by `new_game()`/`ensure_party()`), so HP/MP carry from one battle to the next; Defend and statuses are cleared after each battle. A new game starts with no items.
- [x] `data/encounters/graveyard_outskirts.tres`: groups Wolf×2 (w40), Goblin×1 + Wolf×1 (w30), Skeleton×2 (w25), rare Charred Skeleton×1 (w5, `is_rare`).
  - *As built:* generated by `tools/build_encounters.gd` (uses the enemies from `build_battle_data.gd`). Background `graveyard_bg.tscn` until the style check is decided; no battle music yet.
- [x] Debug toggles (debug builds): F4 = encounters on/off, F5 = force encounter.
  - *As built:* handled by the F3 debug overlay, which now also shows the zone id, step counters, on/off state and the rate multiplier.
- [x] `MusicManager.push/pop/play_jingle` implemented. `SceneManager.start_battle` pushes the encounter's battle `MusicTrack`; `end_battle` plays the victory jingle, then `pop()`s back to the map track at its stored position. `Map` exports `music` and `ambience`, and `AmbientAudioManager.set_profile` runs on map change (battle lowers ambience by 12 dB). Placeholder tones are used until real audio exists.
  - *As built:* the victory jingle (`SceneManager.victory_jingle`, null until Phase 7 audio) starts when the results screen opens (new `BattleController.victory` signal), not after it closes; `pop()` stops it if it is still playing. `push(null)` silences the music until `pop()`. `Map._ready` plays its `music` and `ambience`; a re-attached map does not re-run `_ready`, so the pop restores the music. Ambience: `set_profile` keeps layers that share a stream, `set_duck(db)` for battles, one-shots on a seedable `rng` (`advance(delta)`). No placeholder tones (user decision 2026-11-13): tests use in-memory silent `AudioStreamWAV`s, and the game is silent until the user supplies audio.

**Automated verification**
- [x] `test_encounter_roller.gd`: with a seeded RNG over 100k steps, the observed rate is within ±5% (relative) of `base_chance`; grace steps are never violated; group frequencies within ±2 percentage points of their weight share; a modifier with `steps_left = 200` expires after exactly 200 steps; flag-filtered groups are never picked; multiplier 0 means no encounters; an empty eligible list returns null without crashing. Also: ×0.5 halves the rate, `make_setup`, `BossEncounter`, and the graveyard table's contents.
- [x] `test_encounter_tracker.gd`: simulated movement of 640 px = 10 steps; zero distance when blocked by a wall (velocity 0) = 0 steps; overlapping zones → last entered wins and exiting restores the outer one. Also: real walking, the detach-exit rule, grace and F4/F5, modifier ticks, graveyard has a zone and the village none.
- [x] `test_world_battle_roundtrip.gd`: `start_battle` → auto-win → `end_battle` restores the same map instance, player position (±1 px) and an incremented `GameState` gold. The map's music track is current again after `pop()`. Also: HP carries over, a forced graveyard encounter runs, defeat returns to the title with no rewards, busy/empty requests are ignored.
- [x] `test_music_manager.gd` (fades = 0, placeholder streams): exactly one player audible after a crossfade; `push`/`pop` restores track and playback position; `play_jingle` emits `jingle_finished`; playing the same track twice does not restart it.
- [x] `test_ambient_manager.gd`: switching profiles keeps shared layers playing and removes the others; seeded one-shot scheduling respects `oneshot_interval`. Also: ducking.
- [x] `tools/check.ps1` exits 0. (Run as `tools/check.sh` from WSL: 183 tests, 0 failures.) Outside the suite, headless runs at `--fixed-fps 60` with real fades and animations: a world → battle → world round trip (7 rounds, rewards applied, input back), and 40,000 frames of walking in the graveyard: 64 encounters in 2,289 steps (mean gap ≈ 35 steps ≈ 17 tiles, shortest gap 7 = grace respected).

**Manual verification**
- [ ] In `graveyard_01`, walking triggers battles at a reasonable cadence (roughly every 10–20 tiles), never right after entering or after a battle, and never in the village. After victory the player stands exactly where they were.

**Deliverables:** the complete exploration ↔ battle loop.

---

## Phase 7: 🎯 Milestone 1 — vertical slice

[Dependencies: **Phase 6**]

Turn the systems into a short, coherent, playable experience matching §8.1.

**Tasks**
- [x] Full `DialogueManager`: multi-line, speaker name, choices, `set_flag`, `give_item` (stub to GameState gold/item list), conditional entry (`if_flag`/`use`). Typewriter effect with accept-to-skip.
  - *As built (2026-11-17):* the rules live in a node-free `scripts/dialogue/dialogue_runner.gd` (`DialogueRunner.open(id, GameState)`, `advance()`, `choose(i)`), and `DialogueManager.start(id, portrait)` drives it through the box. A line's `set_flag`/`give_item` run when the line is entered; `give_item` is `"<id>"`, `"<id>:<n>"` or `"gold:<n>"` (validated). Conditional entry follows chains (`elder_intro` → `elder_again` → `elder_again_agreed`). `dialogue_finished` reports the id actually played. The first `accept` completes a typing line, the next advances.
- [x] `components/npc.tscn/.gd` (extends Interactable): static NPC sprite (placeholder: Knight `black` recolour standing guard, or a prop-based "mourner at a grave"), faces the player on talk using the 8-dir idle.
  - *As built:* Knight `black` recolour, solid capsule body, exports `facing` (rest) and `portrait`; turns back to its rest facing after the talk. Placed by `MapBuildKit.npc()`.
- [x] NPC "Elder" (placeholder name) in `village_01` with `elder_intro.json`, a choice and a flag.
  - *As built:* "Elder Maren" (Gimble's Witch Hunter portrait as a placeholder) in the square's north-east quarter. `elder_intro` sets `met_elder`; "I'll go." sets `elder_agreed` and gives 2 Minor Potions. Second talk: `elder_again` (asks again) or `elder_again_agreed`.
- [x] Extend `GameState.apply_battle_rewards(result)` with XP to `PartyMember` and level-up via `Progression` (gold and items already exist from Phase 6; the full Inventory comes in Phase 9).
  - *As built:* returns the `LevelUp`s and emits `member_leveled(member, level_up)`; stat gains use `GameState.rng` (seedable). Rewards are still applied only in `end_battle`, after the results screen, so the screen shows `GameState.preview_level_ups(result)` ("Knight reached level 2!", learned skills), passed to the battle as `BattleController.level_up_preview`. The HUD on the results screen still shows the pre-level stats.
- [x] `scenes/ui/pause_menu.tscn` shell, opened with the `menu` action in exploration: Gimble's panel, a tab list (Party / Items / Equipment / Journal appear in later phases), Resume, Quit to Title. The dfgui MENU button in the exploration HUD opens it too.
  - *As built:* added by `Map` (with `scenes/ui/exploration_hud.tscn`); pauses the tree (`SceneManager` and `AudioManager` run while paused). Party tab = a summary (level, HP/MP, XP to next, gold); the other tabs are shown disabled. Also has Settings. Not available during a dialogue, fade or battle.
- [x] Minimal `Party`/`PartyMember` (1 member) and `Progression.xp_to_next()` with `data/growth/knight_growth.tres`.
  - *As built:* `scripts/rpg/{party,party_member,progression,level_up}.gd`. `GameState.party` is now a `Party`; each `PartyMember` keeps one `Combatant` across battles whose `stats` is the member's own level StatBlock (never the .tres). `GrowthCurve` defaults are now 12 / 1.6 (§6.4) and `xp_for_level()` is the cumulative total. The growth file is written by `tools/build_battle_data.gd`.
- [x] `game_over.tscn`: "Return to title", with the `jng_gameover` jingle.
  - *As built:* `scenes/ui/game_over.tscn`; `SceneManager.game_over()` shows it and plays `SceneManager.game_over_jingle` (null until audio exists).
- [x] Final `title_screen.tscn` (per `UI_ASSET_CATALOG.md`): live necropolis-night background with fog, Cinzel title, red buttons (New Game, Settings, Quit), `mus_menu`.
  - *As built:* `scenes/ui/title_screen.tscn` is the main scene (`scenes/boot/main.*` removed). The background is `graveyard_01` in the new `Map.backdrop` mode (no player, music, encounters, HUD or debug overlay) at the `night` preset, under a slowly drifting camera. `TitleScreen.music` is null until `mus_menu` exists. The typography specimen is no longer on the title (run it with F6).
- [x] `scenes/ui/menus/settings_menu.tscn` + `scripts/ui/settings.gd`: Master/Music/SFX/Ambience sliders, fullscreen toggle, text speed. Persisted to `user://settings.cfg`. Slider, checkbox and option styles come from Theme StyleBoxFlat in palette tokens. Reachable from the title and pause menus.
  - *As built:* `Settings` is a static class (no sixth autoload), loaded by `SceneManager._ready()`. Sliders apply at once; closing saves. The SFX slider also drives the UI bus. Text speeds: Slow / Normal / Fast / Instant (30 / 60 / 120 chars/s / whole line). Theme additions in `tools/build_theme.gd` `_widgets()` (slider, check box, option button + popup, tab bar).
- [x] Full `dialogue_box.tscn`: framed 256 px portrait, dfgui name plate, Cinzel speaker name, Alegreya body, continue indicator, choice buttons, typewriter tick SFX (throttled).
  - *As built:* name plate = `dfgui_partyhud` 2x region (116, 2, 264×42) as a NinePatchRect, so it stretches without leaving the 2-px grid. Continue indicator = gauntlet cursor rotated 90° with a 2-step bob. Choices appear once the line has finished typing; the tick plays every 3 characters (plus the SfxSet cooldown).
- [x] `SFXManager` implemented (pools, variants, pitch range, cooldown, footsteps by TileSet `surface`). UI SFX are wired into the Theme-driven widgets through one `UiSounds` helper (focus, confirm, cancel).
  - *As built:* named sets come from `data/audio/sfx_library.tres` (`SfxLibrary`: `ui` and `footsteps`, empty for now). A full world pool steals its oldest voice; a full UI pool reuses its own oldest (UI sounds are never dropped or taken by world sounds). The player emits `footstep` every 110 px; `Map.surface_at()` reads the topmost tile's `surface`.
- [ ] **Slice audio integration** (moved to **Phase 7A**): assign `MusicTrack`/`SfxSet`/`AmbienceProfile` resources for menu, village, graveyard, battle, victory, game over, level up, UI, footsteps, combat hits, three monster sounds, and two ambience beds. Fill in their rows in `AUDIO_CATALOG.md` §E and `docs/asset_manifest.csv`. If the sourcing gate isn't met, keep the placeholders and record that in the milestone review.
  - *Status (2026-11-17):* **sourcing gate not met**, so the slice is silent. The hook-up points are listed in `AUDIO_CATALOG.md` §D ("Sourcing gate status"). Not wired yet: the level-up jingle and combat/monster SFX (the battle presenter has no sound calls).
- [x] Title → New Game → `village_01` spawn, with a short intro text card.
  - *As built:* `SceneManager.start_new_game()` → `scenes/ui/intro_card.tscn` (three lines fade in; `accept` shows all, then Continue) → `enter_world()`. New: `SceneManager.go_to(scene)`; `to_title()` uses it.
- [x] Balance pass: Knight lv1 survives 3–5 fights before needing to rest. A "rest at the well" Interactable fully heals.
  - *As built:* enemy HP ×0.65 and attack ×0.85 (Wolf 29/19, Goblin 25/17, Skeleton 39/22, Charred 52/26). Before the change, the Knight averaged 1.6 fights and died in 38% of runs. `tools/balance_sim.gd` plays sessions with a sensible policy (Minor Heal below 40%, Whirlwind on groups, else Attack; no items) until HP < 30%: mean 4.2 fights, 3% deaths, usually level 3 by then. The well is the Castle Courtyard well (`scenes/world/props/courtyard/well.tscn`) with a `RestPoint`; the bird bath moved to make room.
- [x] Update `CREDITS.md` and `README.md` (how to run, controls, debug keys).

**Automated verification**
- [x] `test_dialogue_runner.gd`: lines advance; choice `goto` jumps correctly; `set_flag` writes GameState; conditional entry selects the alternate dialogue when the flag is set.
- [x] `test_progression.gd`: `xp_to_next` monotonic; multi-level-up from one big reward is handled; with a seeded RNG, each stat gain is within `stat_gain_per_level ± 1`.
- [x] `test_rewards.gd`: victory over Wolf×2 adds expected gold/XP; the drop roll is deterministic per seed. (The rule that a dead member gets no XP is tested in Phase 8 `test_party.gd`.)
- [x] `test_slice_flow.gd` (integration, headless): new game → change_map to graveyard → force encounter → auto-battle win → back in world with rewards applied.
- [x] `test_sfx_manager.gd`: pool never exceeds its size; UI voices are never stolen; cooldown suppresses duplicates within `cooldown_ms`; pitch stays within `pitch_range`; an unknown surface falls back to the stone footstep set.
- [x] `test_settings.gd`: slider values round-trip through `settings.cfg` and are applied to the buses via `linear_to_db`.
- [x] `test_ui_screens_smoke.gd`: title, pause, settings, dialogue box and game-over scenes instantiate headless with the main theme and have at least one focusable control.
- [x] `test_asset_manifest.gd` still passes, so every added audio file has a complete licence row.
- [x] Extra: `test_npc_dialogue.gd` (walk to the Elder and the well with real physics, typewriter → choices → flag → different second talk, the well heals), `test_footsteps.gd` (surfaces under the feet, stride cadence), `test_balance.gd` (3–5 fights before resting).
- [x] `tools/check.ps1` exits 0. (Run as `tools/check.sh` from WSL: 231 tests, 0 failures.) Outside the suite: windowed captures of every new screen, and a real-time run (no instant mode) of village → Elder → graveyard → two battles with a level-up on the results screen → a forced defeat → Game Over.

**Manual verification**
- [ ] Full slice playthrough from the title screen:
  1. Start a new game, read the intro, and appear in the village at dusk.
  2. Talk to the Elder, pick a choice, and get the different response on a second talk.
  3. Walk to the graveyard; random battles occur; fight Wolves, Goblin and Skeletons using every command.
  4. Gain XP and gold and see a level-up on the results screen.
  5. Rest at the well to heal.
  6. Lose a fight on purpose and see Game Over → Title.
  7. No errors in the debugger Output during the whole run.
- [ ] Presentation check: every screen uses the same panels, cursor and fonts. Nothing looks out of place against the `ART_GUIDELINES.md` checklist. (The audio half of this check moved to Phase 7A.)

**Deliverables:** **Milestone 1**, a playable vertical slice and the reference for all further work. **Stop here for a user review/playtest before Phase 7A.**

---

## Phase 7A: Audio setup

[Dependencies: **Phase 7**] (the integration tasks also depend on the user supplying the slice audio set)

*Added 2026-11-17 at the user's request, so audio comes before Phase 8. It is named 7A so that Phases 8–12, which code comments and docs already refer to, keep their numbers.* Milestone 1 shipped silent because the audio sourcing gate was not met (see Phase 7). This phase builds what is still missing between "the managers exist" and "the game has sound": a sourcing and import pipeline, the sound hooks that were never wired (level-up, combat, monsters, rewards), and the slice audio itself. Afterwards, adding a sound anywhere in later phases is data work only.

**Step 0a: audio asset audit, then implementation (run first)**
- [x] Follow the audit brief in `AUDIO_CATALOG.md` ("Audit brief", Phases 1–5): inspect every accessible audio file and pack, then write `docs/AUDIO_ASSET_CATALOG.md` (catalog with fit ratings), `docs/AUDIO_REQUIREMENTS.md` (what exists and what is missing per category) and `docs/AUDIO_STYLE_GUIDE.md` (audio identity), and recommend packs only for real gaps. Research and documentation only: no game code changes, downloads, purchases or edits to original files.
  - *As built (2026-11-17):* only `assests/audio_sources/` holds audio (no art pack ships sound). Measured with Python + the ImageMagick-bundled `ffmpeg.exe` 4.2.3 (EBU R128 loudness, `smpl` loop seams, spectra, pulse); the assistant cannot listen, so mood ratings are provisional (listening checklist in the catalog). Findings: the three `_Loop` string drones loop cleanly and fit the direction; the six `Tracks wav` pieces need loop edits; Kenney UI (CC0) works pitched down and quieter; **all world SFX, ambience, a battle track, folk village music and the jingles are missing**. **Both music packs have no licence file and could not be traced online (release blocker until the user records them).** Recommended sources R1–R7 and the proposed slice library are in `docs/AUDIO_REQUIREMENTS.md`. Encoding can use that `ffmpeg.exe` (libvorbis, loudnorm).
- [x] Present the audit's final output (existing assets, strongest candidates, missing categories, recommended packs, proposed slice library) and get the user's approval.
  - *As built (2026-11-17):* presented; the user added the two missing licence PDFs to the zips and approved with one rule: **use only the supplied packs, download nothing else**.
- [x] After approval, implement the audio (brief Phase 6): source the approved library (Step 0), then complete the pipeline, hook and integration tasks below with it.
  - *As built (2026-11-17):* done with the supplied packs (see below). Gaps without a source stay silent.

**Step 0: sourcing (user)**
- [x] Obtain the slice set in `AUDIO_CATALOG.md` §C, guided by the library the audit proposed (music: `mus_menu`, `mus_town_hamlet`, `mus_dungeon_graveyard`, `mus_battle`, `jng_victory`, `jng_gameover`, `jng_levelup`; SFX: UI, footsteps stone/grass/mud, combat swing/hit/crit/miss, magic cast/fire/heal, three monster cries, reward gold/item, level up; ambience: village and graveyard beds). Choose sources under the licence rules in `AUDIO_CATALOG.md` §A. Prefer one or two coherent packs over many single files (R4c). The assistant does not download audio.
  - *As built (2026-11-17):* the user supplied three packs (Dreamgarden *Dark Fantasy Ambient Strings*, AlkaKrab *Tracks wav*, Kenney *Interface Sounds*) and no more. Not sourced: footsteps, combat/magic/monster SFX, ambience beds, a real battle track, folk village music. Q8 settled (user-supplied packs); Q15 stays no.
- [x] Put each original download (zip plus its licence or EULA) untouched in `assests/audio_sources/`.
  - *Done 2026-11-17* (see the verify task below). Q8 and Q15 are decided at this step (sources; whether AI-generated SFX are acceptable).

**Tasks: pipeline (can start before the audio arrives)**
- [x] `tools/verify_source_assets.py` also covers `assests/audio_sources/` (`--record` after each addition), so `check.sh` fails if an original changes.
  - *As built (2026-11-17):* it scans every subfolder of `assests/`. Three packs are in `audio_sources/`: `Dark Fantasy Ambient Strings.zip` (6 WAV), `Tracks wav.zip` (6 WAV) and `kenney_interface-sounds.zip` (100 OGG, CC0). **The first two contain no licence file**, so their source and licence still need recording. Eight art packs kept for later phases are in `assests/later/` (Footsoldier, Mounted Knight, Kangal, Haunted Effects, Barbarian Camp, Dwarven Hill House, Elven Home, Orc Hunter's Lodge). They are checksummed but not extracted yet.
- [x] `tools/import_audio.py` (run with `python -I`, copies only, like `extract_assets.py`): reads a mapping table (`tools/audio_sources.csv`: source zip, path inside it, target ID) and writes the renamed copies to `assets/audio/{music,ambience,sfx/<category>}/` following the naming in `AUDIO_GUIDELINES.md` §4. It refuses MP3 and unknown extensions, and reports any target ID in the slice list that has no source yet.
  - *As built (2026-11-17):* reads `tools/audio_sources.csv` (target, zip, member, cut, `loop` = `smpl`/`whole`/`no`, crossfade, fades, `gain` = `lufs:`/`db:`), opens the zips in place, cuts/crossfades WAV in Python, then measures loudness (EBU R128) and encodes with ffmpeg (the ImageMagick-bundled `ffmpeg.exe` works from WSL). `--if-missing` is run by `check.sh`/`check.ps1`. Because the repository is **public** and two licences forbid redistribution, `assets/audio/**/*.ogg|wav` are git-ignored and rebuilt locally (the `.import` files are committed, so UIDs stay stable). Godot imported `.csv` files as translations, so `tools/audio_sources.csv` and `docs/asset_manifest.csv` now use the `keep` importer (stray `.translation` files removed).
- [x] Import settings: Ogg music and ambience loop (`loop = true`, `loop_offset` where a track has an intro); WAV SFX are not looped. Written into the `.import` files by the build tool below (or a documented editor preset), so they don't depend on clicks in the editor.
  - *As built (2026-11-17):* `import_audio.py` writes `loop`/`loop_offset` into each Ogg's `.import` (the `smpl` loop start; Godot keeps `[params]` on reimport). Jingles `loop=false`. SFX WAV use the default import (no loop).
- [x] `tools/build_audio.gd` (headless, the source of truth like `build_battle_data.gd`): generates `data/audio/music/*.tres` (`MusicTrack`), `data/audio/sfx/*.tres` (`SfxSet`, variants grouped by `_01.._nn` suffix), `data/audio/ambience/*.tres` (`AmbienceProfile` + layers and crow/bell one-shots) and fills `data/audio/sfx_library.tres` (`ui`, `footsteps`). Per-ID volume, pitch range and cooldown live in a table inside the tool. An ID whose file is missing is skipped (no placeholder tones, 2026-11-13 decision), so the tool can run at any time.
  - *As built (2026-11-17):* 7 MusicTracks (`data/audio/music/`), 10 SfxSets (`data/audio/sfx/`), `sfx_library.tres` (`ui`: focus, confirm, cancel, tick, open, denied, reward_gold, reward_item, levelup, rest; `footsteps` and the new `battle` dictionary empty until files exist).
- [x] Manifest: one `docs/asset_manifest.csv` row per audio source (`test_asset_manifest.gd` already requires one for every file under `assets/audio/`), and the matching rows in `AUDIO_CATALOG.md` §E. `CREDITS.md` gets the exact attribution line for every CC BY source.
  - *As built (2026-11-17):* 8 rows; §E filled; `CREDITS.md` lists all three (no CC BY source, so no mandatory credit line).

**Tasks: wire the missing hooks (can start before the audio arrives)**
- [x] Battle sounds as data, mirroring the FX design (`FxSpec`):
  - *As built (2026-11-17):* fields added (in an *Sounds* inspector group on `CombatantVisual`). Shared sets live in the new `SfxLibrary.battle` (`crit`, `miss`, `defend`, `flee`). All empty for now (no source).
  - `CombatantVisual`: `attack_sfx` (swing), `hit_sfx` (taken when struck: blood or bone), `cry_sfx` (on spawn and phase change) and `death_sfx`.
  - `SkillData` and `ItemData`: `cast_sfx` (on the cast animation) and `impact_sfx` (with `impact_fx`).
  - Shared sets in `data/audio/sfx/`: `combat_crit`, `combat_miss`, `combat_defend`, `battle_flee`.
- [x] `BattlePresenter`: `static func choose_sfx(action, event, target_visual) -> SfxSet` (the same rules as `choose_fx`: the skill or item first, then the target's `hit_sfx` for physical blows, nothing on status ticks; crit and miss override). Sounds play on the hit frame through `AudioManager.sfx.play_at`, positioned at the target. Like `fx_count`, an `sfx_count` is incremented even in instant mode, and nothing plays in instant mode.
  - *As built (2026-11-17):* a miss (0 damage or immune) and a crit override only when the shared set exists. Swing = the skill's `cast_sfx` else the actor's `attack_sfx` at the step forward; spells at the glow; items as used; cries on intro and phase change; death on defeat; defend; flee. No combat event is a "miss" in the engine yet, so 0-damage/immune stands in.
- [x] Level-up: `SceneManager.level_up_jingle` plays when the results screen shows a level-up (after the victory jingle), and `progress_levelup` plays on the "reached level N" line. Reward sounds `reward_gold` / `reward_item` play on the results screen lines.
  - *As built (2026-11-17):* `SceneManager.JINGLE_PATHS` loads the three jingles; the level-up jingle waits for `jingle_finished` of the victory jingle (or plays alone if there is none), so it is heard only if the results screen is still open after the 7 s victory jingle. Results screen: gold → item → level-up accents 0.3 s apart.
- [x] Field sounds: `sfx_ui_open` when the pause menu opens, `progress_rest` at the well, and a positional crackle loop on the graveyard bone pyre (`AudioStreamPlayer2D` on the `Ambience` bus with a max distance, as allowed by `AUDIO_GUIDELINES.md` §5).
  - *As built (2026-11-17):* `open` on the pause menu, `rest` at the RestPoint. **The pyre crackle is not added** (no fire loop among the supplied packs).
- [x] `Ambience` bus low-pass while the pause menu is open (`AUDIO_GUIDELINES.md` §5 bus layout).
  - *As built (2026-11-17):* `AudioManager` adds a disabled 900 Hz low-pass to the Ambience bus; `set_ambience_muffled()` from the pause menu (open, close, quit).

**Tasks: integrate the slice set (once Step 0 is done)**
- [x] Assign everything listed in `AUDIO_CATALOG.md` §D "Sourcing gate status": `TitleScreen.music`, `Map.music` / `Map.ambience` in `tools/map_builders/*` (rebuild the maps), `EncounterTable.music` in `tools/build_encounters.gd`, `SceneManager` jingles, the `sfx_library` sets, and the new battle sets in `tools/build_battle_data.gd`.
  - *As built (2026-11-17):* title, village, graveyard (scenes patched directly to avoid a terrain re-roll; builders updated too), battle (encounter table regenerated), jingles, UI/field sets. Not assigned (no source): ambience, footsteps, battle sets.
- [ ] Mix pass for the slice: normalise to the `AUDIO_GUIDELINES.md` §4 targets before import (music ≈ −18 LUFS, ambience ≈ −24 LUFS, SFX peaks ≤ −1 dBTP), then balance `volume_db` per set by ear. Tune the battle duck (`set_duck`) and jingle duck.
  - *Status (2026-11-17):* loudness done in the pipeline (music −18 LUFS, battle −16, jingles −18; measured after encoding); Kenney sets start at −10 to −20 dB, pitched 10–20 % down. **Balancing by ear is still open** (needs listening).
- [x] Update `AUDIO_CATALOG.md` (gate status → met, the hook table → as built), `AUDIO_GUIDELINES.md` §5 ("implemented"), `README.md` and `CREDITS.md`.
  - *As built (2026-11-17):* gate "partly met", hook table as built; `AUDIO_GUIDELINES.md` §5 implemented + pipeline; README, CREDITS, `docs/AUDIO_*`.

**Automated verification**
- [x] `test_battle_audio.gd`: the `choose_sfx` rules (attack → target `hit_sfx`; Ember → its `impact_sfx`; a crit uses `combat_crit`; a miss uses `combat_miss`; a status tick → null; a null action → null); an instant auto-battle has `sfx_count > 0`; the cast sound is chosen for a spell.
- [x] `test_level_up_audio.gd`: a reward that levels the Knight starts `level_up_jingle` after the victory jingle; a reward without a level-up doesn't.
- [x] `test_audio_data.gd`: every `.tres` in `data/audio/` loads; every `SfxSet` has ≥ 1 stream, and frequent sets (footsteps, hits, UI focus) have ≥ 3 variants or a pitch range of at least ±5%; every music and ambience stream loops and every jingle doesn't; every file under `assets/audio/` is referenced by some resource (no orphans).
- [x] `test_audio_coverage.gd` (slice subset, extended to the full game in Phase 12): every hook in the "Sourcing gate status" table points to a non-null stream. It is skipped with a printed notice while `assets/audio/` is empty, so the suite stays green before Step 0.
- [x] Existing audio tests still pass (`test_music_manager`, `test_sfx_manager`, `test_ambient_manager`, `test_audio_buses`, `test_settings`, `test_asset_manifest`).
- [x] `tools/check.sh` exits 0.
  - *As built (2026-11-17):* 252 tests, 0 failures. Outside the suite: a real-time headless session (graveyard music → pause muffles ambience → battle music → victory jingle → level-up → map music back) and a title-screen boot with no errors. Headless test runs report the Ogg playbacks of stopped streams as "still in use" at exit (the dummy audio driver never mixes, so they are never released; not seen in a plain boot).

**Manual verification** (the audio half of the Phase 7 check, which moves here)
- [ ] With headphones, from the title screen:
  1. The menu, village, graveyard and battle each have their own music. Battle music starts on encounter. After victory the jingle plays (and the level-up jingle when one happens), and the exploration track resumes where it left off.
  2. Footsteps change between stone, grass and mud. Wind and crows play in the graveyard, the village has its own ambience, and the pyre crackles louder as you approach it.
  3. In battle, swings, hits, crits, misses, Ember, Minor Heal, the potion and each monster's cry are audible and land on the hit frame. Burn and Bleed ticks are silent.
  4. Settings sliders change Music, SFX and Ambience independently and immediately, and persist after a restart. Ambience is muffled while paused.
  5. No clipping, no audible loop seams, and the music never masks UI feedback.

**Playtest feedback (2026-11-17) and fixes**
- *"The menu clicks are odd for the theme"*: the Kenney copies are darkened at import (`filters` column in `tools/audio_sources.csv`: pitch 55–80 %, low-pass 1.2–2.5 kHz, room echo); focus now uses micro-clicks. **Listen again.**
- *"The village music starts very loud"* and *"village → graveyard cuts in the middle"*: `MusicTrack.fade_in/fade_out` were never used (every change was a 1 s fade) and fades moved the dB value from −80, so they were heard as a near-cut. Now fades are linear in amplitude, `play()`/`stop()` default to the tracks' own fades, `SceneManager.change_map` fades the old track out (2.5 s) with the screen when the next map's music differs (`scene_music()` reads it from the PackedScene), and the map fades its track in (4 s). The village track is also 3 dB lower. New tests in `test_music_manager.gd` and `test_audio_coverage.gd`.

**Deliverables:** the vertical slice with its full audio set, and an audio pipeline (sources → `assets/audio/` → generated resources → hooks) that later phases reuse. If Step 0 is not done, the pipeline and hooks are still delivered and tested, and the integration tasks wait for the files.

---

## Phase 8: Party and character progression, status effects in play

[Dependencies: **Phase 7A**]

**Tasks**
- [x] `Party` with up to 3 active members, `PartyMember` (data, level, xp, hp/mp, learned skills).
  - *As built (2026-11-20):* `Party` gains `remove`, `is_full`, `member_by_id`, `has_character`, `living_members`; members keep their slot when they fall, so a revived one acts in its old place. `PartyMember.create(character, start_level, rng)` levels a recruit up to `start_level` (rolled gains, skills learned, then full HP/MP). `GameState.recruit(character, flag)` adds a member at the leader's level, sets the flag and emits `member_joined`; it refuses duplicates and a full party.
- [x] Two placeholder members: `data/characters/warden.tres` (Knight black recolour, tank, Provoke/Guard skills) and `hexblade.tres` (Knight gold recolour, Ember/Frost/Spark + Minor Heal).
  - *As built:* written by `tools/build_battle_data.gd` with their own growth files and battle visuals (`data/visuals/warden|hexblade.tres`; the recolours have only the base sheets, so skills and spells use `attack2`). **Warden** (HP 150, DEF 28): Provoke, Guard, Blessing, Purify; Benediction at level 4. **Hexblade** (MP 36, MAG 28): Ember, Frost, Spark (all foes, LIGHTNING), Minor Heal; Hex (SHADOW, may Curse) at level 3. New `SkillData.Effect` values: `STATUS` (applies `inflicts`), `CURE` (removes `cures`) and `GUARD`; new `SkillData.priority` (Provoke and Guard act first, like Defend). Provoke applies the new **Taunt** status (`draws_attacks`, tag "TNT", 2 rounds): enemies aim single-target actions at the holder, both when choosing (EnemyAI) and when the action resolves, so a Provoke used first that round already counts. Guard: the Warden defends, and single-target blows aimed at the chosen ally hit the Warden instead (`COVERED` event) until round end; area attacks are not covered. New effects: frost impact, spark impact, shadow impact, holy light.
- [x] Skill unlocks per level (`SkillUnlock {level, skill}`), shown on the results screen.
  - *As built:* already worked from Phase 7 ("X learned Y!" lines); now covered by tests, including recruits that join above level 1.
- [x] Status effects inflicted by enemies (Goblin "Serrated Stab" → Bleed, Wolf "Rend" → Bleed, Skeleton "Grave Chill" → Curse, boss "Blood Mist" → Bleed on all), Blessed via a Warden skill, status icons in the HUD, cures via skill/item.
  - *As built:* each enemy uses its status attack once for every 5 plain attacks; Bleed lands 25% of the time, Curse 30% (`ENEMY_BLEED_CHANCE`, `ENEMY_CURSE_CHANCE`). `blood_mist.tres` exists but no enemy uses it until the boss (Phase 10). Blessed: Warden's Blessing (one ally) and Benediction (all). Cures: Warden's Purify (Bleed, Burn, Curse) and the new **Holy Water** item (cures Curse; Gimble's `058_holy_water` icon; dropped by skeletons, 2 given by the Hexblade). A support skill that changes nothing shows "No effect". Balance: the solo Knight now averages about 3.7 fights before resting with 6% deaths (was 4.2 and 3%); the simulated player heals at 50% HP while Bleeding. Status-effect SFX: none (no source in the supplied packs).
- [x] Battle HUD and command flow for 3 members (cancel steps back between members).
  - *As built:* the Phase 5 HUD and command flow already handled several members; checked with three (HUD rows, battle slots, cancel stepping back). Stances (Provoke, Guard) glow in place without a swing.
- [x] `scenes/ui/menus/status_page.tscn` (pause menu "Party" tab): stats in `NumericLabel`, level, XP `StatBar` (dfgui purple), element resistances as coloured text tags, active statuses, and framed Gimble's portraits (Knight portrait for the Knight; Witch Hunter and Witch portraits as placeholders for the Warden and Hexblade).
  - *As built:* `StatusPage` replaces the Phase 7 text summary (the pause panel is now 1500 px wide). One button per member; the XP bar shows progress through the current level. Resistances read the combatant's affinities (empty until Phase 9 equipment, so "None"). Portraits are `CharacterData.portrait`.
- [x] Party recruitment trigger: an event `Interactable` that adds a member and sets a flag.
  - *As built:* `scenes/world/components/recruit_npc.tscn/.gd` (`RecruitNpc` extends `Npc`): takes its sprite and portrait from the character, joins through `GameState.recruit()` after its dialogue if `join_if_flag` was set by the player's choice, fades out, and is gone on later visits. The **Warden** waits by the road south of the village square (`warden_meet.json`), the **Hexblade** at the crypt in the graveyard (`hexblade_meet.json`). Both maps were patched directly (no terrain re-roll), and `MapBuildKit.recruit()` puts them in the builders too.

**Automated verification**
- [x] `test_party.gd`: add/remove, max 3, dead member excluded from XP and turn order, revive restores ordering. (Also: recruiting at the leader's level, duplicates and a full party refused.)
- [x] `test_skill_unlocks.gd`: learning at the exact level, multi-level skips learn all intermediate skills once. (Also: no duplicate of a starting skill, recruits above level 1, the results-screen lines.)
- [x] `test_battle_engine_party.gd`: 3-member seeded battle; status inflicted and cured; all-party wipe = DEFEAT. (Also: Holy Water, Blessing/Benediction, Provoke, Guard and its limits.)
- [x] Extra: `test_party_battle_smoke.gd` (3 battlers and HUD rows, cancel steps back, Guard and Purify through the real menus, status badges) and `test_recruitment.gd` (accept/decline, flags, NPC gone on return, Holy Water gift, Party tab).
- [x] `tools/check.ps1` exits 0. (Run as `tools/check.sh` from WSL: 289 tests, 0 failures.) Outside the suite: windowed captures of the Party tab and a 3-member battle.

**Manual verification**
- [ ] Recruit both members, fight with 3, inflict and cure Bleed and Curse, apply Blessed, and check the Party page shows correct stats after level-ups.

---

## Phase 9: Inventory, equipment, items, shop

[Dependencies: **Phase 8**]

**Tasks**
- [x] `Inventory` (stacks, key items, `add/remove/count/has`, signals).
  - *As built (2026-11-20):* `scripts/rpg/inventory.gd` (RefCounted in `GameState.inventory`): stacks by id capped at 99 (`add` returns how many fit), key items in their own list (one each), and **the gold** (§6.4; `GameState.gold` reads and writes it). Picking up an item whose effect is `GOLD` (Gold Coins, 25 each) adds gold instead. Signals `changed` and `gold_changed`, relayed as `GameState.items_changed` / `gold_changed`. The Phase 6–8 `GameState.items` dictionary and `battle_items()`/`sync_battle_items()` are gone; `item_count`/`add_item` remain as thin wrappers (dialogue `give_item`).
- [x] `equipment_data.gd` and `CharacterData.allowed_equipment`. Item and equipment files that match the Gimble's icons: Minor Potion (health potion), Mana Potion, Holy Water (cures Curse; HOLY damage vs undead), Soul Gem (revive), Warding Torch (encounter rate ×0.25 for 200 steps), Gold Coins (pickup); Worn Longsword, Battle Axe, Silver Stake (dagger, +HOLY), Iron Helm, Kite Shield, and an accessory with a dfgui icon (goblet: "Pilgrim's Chalice", SHADOW resist).
  - *As built:* new items and gear come from `tools/build_items.gd` (run after `build_battle_data.gd`); `data/equipment/` holds the gear. `ItemData` gains `is_key_item`, `element`, `foe_damage` (an ally item that can also be thrown at a foe), `ward_mult`, and the effects `WARD`, `GOLD`, `NONE`. Holy Water: cures Curse on an ally, or 15 HOLY damage on a foe (30 on skeletons); battle-only, since statuses end with the battle. Mana Potion 15 MP (30 g), Soul Gem revives with 50 HP (120 g), Warding Torch 60 g. Gear: Worn Longsword ATK +6 (60 g, village chest), Battle Axe ATK +12 AGI −2 (180 g), Silver Stake ATK +3 AGI +2 with HOLY attacks (150 g), Iron Helm HP +10 DEF +3 (80 g), Kite Shield DEF +6 SPR +2 (100 g), Pilgrim's Chalice SPR +3, Shadow ×0.5 (140 g). The Minor Potion keeps its SovDigital HD icon (Phase 7). Also a key item, the **Skull Key** (Gimble's `081_skull_key`), not placed yet (Phase 10). The Hexblade can't use shields (`allowed_equipment`). No starting gear, so the slice balance (`test_balance.gd`) is unchanged.
- [x] Equip/unequip on `PartyMember`, effective stats computed on demand, category restrictions.
  - *As built:* gear lives in `Combatant.equipment` (slot → item). `Combatant.stat()` = level stats + Σ gear bonuses, read by `effective_stat`, `max_hp/max_mp` and the HP/MP clamps; `affinity()` multiplies the gear's `resist`; `attack_element()` gives plain attacks the weapon's element. `PartyMember.equip_from(inventory, item)` / `unequip_to(inventory, slot)` move gear between the bag and the slot (HP/MP clamp when a bonus leaves); `stats_with(slot, item)` previews without changing anything. `EquipmentData.encounter_rate_mult` joins `GameState.get_encounter_multiplier()`.
- [x] Battle "Items" submenu wired to `Inventory` via the `consume_item` callable.
  - *As built:* `BattleController.start(..., bag)` takes the Inventory (SceneManager passes `GameState.inventory`); the menu lists `Inventory.battle_items()` and the engine callback removes from it, so nothing is copied back after the battle. An item with `foe_damage` offers the living enemies as targets after the allies.
- [x] `scenes/ui/menus/inventory_page.tscn` (field use, targets, category tabs, scrollable grid of Gimble's slots) and `equipment_page.tscn` (4 slots, stat-diff preview ▲ `heal` / ▼ `blood`).
  - *As built:* the pause menu's Items and Equipment tabs are enabled (the tab bar now takes focus; Journal stays disabled). Items page: Items / Equipment / Key Items buttons, an 8-column grid of `ItemSlot`s (new widget, theme variation `SlotButton`: Gimble's slot ×2, `slot_selected` on focus, count in the corner via `SlotCountLabel`), name/description, and a member list for targeted items (members it would not help are disabled; `FieldItems` refuses an item that does nothing, so it is not wasted). Equipment page: member buttons, the four slots as `ItemRow`s, a choice list (wearable gear + Remove), and the eight stats with ▲ (`heal`) / ▼ (`blood_bright`) previews on focus. `cancel` steps back from a target or gear choice before closing the menu.
- [x] SFX: chest open/locked, door, gold and item pickup, buy/sell, equip.
  - *As built:* new library names `buy`/`sell` (the gold sound), `equip` (new `sfx_ui_equip`: Kenney `switch_002`, darkened like the other UI sounds; **listen**), `chest_open`, `chest_locked`, `door`. No source for chests and doors: their sets stay silent; a locked chest falls back to `denied` (`SFXManager.play_ui_named(sound, fallback)`), loot plays `reward_item`/`reward_gold`. `MapTransition.sound` can play `door` (no door exists yet).
- [x] `chest.tscn` (Interactable, opened flag persisted in `GameState.flags`).
  - *As built:* `scenes/world/components/chest.tscn/.gd`: `item` × `count` and/or `gold`, `opened_flag`, optional `required_key` (a key item kept, not consumed). Shows "Found …" through the new `DialogueManager.say(lines)`. Placeholder art: the castle-courtyard crate (`intact` shut, `broken` opened; no chest sprite in the kits). Placed: village (Worn Longsword, between the east cottages), graveyard (Soul Gem by the obelisk; 2 Gold Coins = 50 gold by the burial cart). Maps patched directly, and `MapBuildKit.chest()` puts them in the builders.
- [x] `shop_menu.tscn` + merchant NPC (buy/sell at 50%).
  - *As built:* `Shop` (pure rules: `buy`, `sell`, `sell_price` = half, rounded down; key items and price-0 items can't be sold) and `scenes/ui/shop_menu.tscn` (Buy / Sell / Leave, item rows with prices, pauses the game). `ShopNpc` (`shop_npc.tscn`) opens it after its greeting. **Merchant Oswin** stands at the village market stall (`merchant_greeting.json`, then `merchant_again.json`), selling the consumables and all gear except the Worn Longsword. Placeholder look: Knight black recolour.
- [x] Gimble's item icons via `ItemData.icon` (64 px), shown in Gimble's 36 px slots (2× = 72 px, `slot_selected` for focus).

**Automated verification**
- [x] `test_inventory.gd`: stack cap 99, remove below zero rejected, key items cannot be sold. (Also: Gold Coins, gold limits, battle items, GameState delegation.)
- [x] `test_equipment.gd`: bonuses applied/removed, invalid category rejected, element resist feeds `DamageCalculator`. (Also: swaps, HP clamp, preview, Silver Stake HOLY attacks, gear encounter multiplier.)
- [x] `test_shop.gd`: buy with insufficient gold rejected; sell price rounding. (Also: full stack, sell more than held, key items.)
- [x] `test_encounter_modifier_item.gd`: using a Warding Torch adds a ×0.25 modifier active for exactly 200 steps. (The EncounterTracker now rolls before ticking, so the 200th step's roll is still warded.)
- [x] Extra: `test_field_items.gd`, `test_battle_items.gd` (Holy Water on a skeleton and on an ally, Soul Gem, battle spending from the Inventory), `test_inventory_menus.gd` (tabs, Items page use, Equipment page equip/preview/cancel, Hexblade shield slot) and `test_chest_and_shop.gd` (chest once and still open after a map round trip, graveyard chests, locked chest, merchant → shop, buy/sell).
- [x] `tools/check.ps1` exits 0. (Run as `tools/check.sh` from WSL: 345 tests, 0 failures.) Outside the suite: windowed captures of the chests, the merchant, the Items and Equipment tabs and the shop.

**Manual verification**
- [ ] Buy a potion, use it in the field and in battle, equip a sword and see ATK change in menu and damage, open a chest once (it stays open after leaving and returning to the map).
- [ ] Listen to the new equip sound.

---

## Phase 10: Dialogue, NPCs, quests, boss

[Dependencies: **Phase 9**]

**Tasks**
- [x] `QuestData` + `QuestLog` (start, advance via `stage_flags`, complete) + `scenes/ui/menus/journal_page.tscn` (active/completed lists, `LoreLabel` stage text; parchment-style page if a parchment asset has been sourced, otherwise the dark panel).
  - *As built (2026-11-24):* `QuestData` (`data/quests/<id>.tres`, written by `tools/build_quests.gd`) holds ordered `QuestStage`s; a stage is done when **all** its `flags` are set (the three graves are one stage, shown as "Graves searched: 2/3"), and a `turn_in` stage sends the player back to the giver. `QuestLog` (`GameState.quests`) stores quest id → stage index, moves on in `GameState.set_flag` (before `flag_changed`, so listeners see the new stage), never goes back, and signals start / stage / completion once each (relayed as `GameState.quests_changed(quest)`); `to_dict()` is ready for Phase 11. Journal tab: Active / Completed buttons, the `51_quest` icon, title, giver, summary, current stage (`LoreLabel`), stages done (✓). No parchment asset yet: dark panel. The exploration HUD shows "New quest / Journal updated / Quest complete" for 3 s.
- [x] `scenes/ui/menus/map_page.tscn`: a sepia-graded capture of each visited map (rendered once via `SubViewport`, cached in `user://`), dfgui map icons for the player, exits, quest targets and save points.
  - *As built:* `MapAtlas` renders a map once on its first visit (a `SubViewport` sharing the map's `World2D`, the player hidden; the HUD, pause menu and fog are CanvasLayers and stay out) to `user://map_cache/<map_id>_v1.png`, and writes its name, bounds and markers as JSON next to it on every visit (`GameState.visited_maps` lists the maps). The page grades the picture with `sepia.gdshader` (palette `bg_abyss` → `parchment`) and draws the dfgui icons: party (you, current map only), flag (exits), shrine (rest points; save points join in Phase 11), "?" (current quest targets, via `QuestLog.is_target`) and crypt (the boss door while it is the target). A headless run has no renderer, so tests see the markers on a plain panel. Map tab added to the pause menu (Party, Items, Equipment, Journal, Map).
- [x] Audio: `mus_boss_assassin`, `mus_story_*` cues triggered from dialogue (`"music": "<id>"` key), monster vocal SFX for the boss.
  - *As built:* from the packs already supplied (no downloads): `mus_boss_assassin` = AlkaKrab *Shadowforge Convergence* (loop edit 4–97 s, −16 LUFS; the audit's "mid-boss" track, the real boss theme is still a commission candidate), `mus_story_dread` = *Dread March* (0–106 s), `mus_story_sorrow` = Dreamgarden *ForgottenSouls_Loop* (the title theme returning, as `docs/AUDIO_REQUIREMENTS.md` §9 proposed). **Picked by measurement and title, not by ear: listen.** A line's `music` cue is pushed over the map music and popped when the dialogue closes (`"stop"` silences instead). Used at the crypt door (dread), the Elder's report and Brenna's last talk (sorrow). The BossEncounter falls back to `mus_battle` if the boss track is not built. **Monster vocal SFX: no source** in the supplied packs; the boss's `cry_sfx`/`death_sfx` hooks stay empty.
- [x] Dialogue extensions: `start_quest`, `require_item`, `take_item`, `portrait` key (Gimble's framed 256 px portraits; Vampire Lord / Werewolf / Skeleton Warrior available for story characters). Quest-giver NPCs show the Gimble's `51_quest` icon above their head, and locked doors show `43_locked`.
  - *As built:* `require_item` ("<id>[:n]" or "gold:n") skips its line for `else_goto` (default: the end) when the party lacks it; `take_item` removes; `start_quest` starts `data/quests/<id>.tres`; `portrait` is a framed portrait file name (e.g. `43_vampire_lord`) shown for that line instead of the NPC's; all four are validated (unknown quest, portrait or track = error). Icons float over any `Interactable` (`set_icon`): `51_quest` over an NPC whose `quest` it gives (`quest_stage` −1) while the quest is not started or waits at a `turn_in` stage; `43_locked` over the sealed crypt door and over chests that need a key. `Interactable` gained `quest` / `quest_stage` / `quest_done_flag` (quest targets for the map page). `Npc.sprite_frames` gives a villager its own look.
- [x] 3–5 village NPCs (placeholders) with flag-dependent dialogue.
  - *As built:* three new villagers, each with lines for before the quest, during it and after the boss: **Gravedigger Hollis** by the bench (names the three graves), **Sister Ilse** by the well (advises Holy Water), **Widow Brenna** by the damaged cottage (her husband vanished; the sorrow cue after the boss). With the Elder and Merchant Oswin that is five. Placeholder looks: the Knight and its gold recolour, no portraits (risk R5). The Elder now starts the quest when the player agrees and pays out on the report (300 gold, a Soul Gem).
- [x] `boss_trigger.tscn/.gd` + `data/bosses/blade_assassin.tres` (phase two = Unmasked), entrance animation, `idle_hp50/25` swaps, stagger window after big attacks, no flee, boss music hook.
  - *As built:* `tools/build_boss.gd` writes the boss (run after `build_battle_data.gd` and `build_audio.gd`). **BossTrigger** (the crypt door in `graveyard_01`): sealed with `43_locked` until the three grave flags are set, then plays `crypt_door_open` (the Blade Assassin taunts, Vampire Lord portrait, dread cue) and starts the fight (deferred, no flee). The win is recorded by `SceneManager.end_battle` through the new `BattleSetup.victory_flag` (with the rewards), so a lost fight never resumes a freed map; after that only `crypt_door_silent` plays. **Boss:** form one *Blade Assassin* (HP 520) → at 50% form two *Unmasked Daywalker* (HP 560, same name in battle, HP ratio kept); weak to Holy, resists Shadow, immune to Sleep and Stun; acts **twice a round** (new `EnemyData.actions_per_round`). Moves: Blade Slash (attack3), Blink Strike (attack), Phase Rush and Whirlwind (form one), Blood Mist (Bleed on all) and Bone Lance (form two). **Stagger window:** Phase Rush, Whirlwind and Bone Lance leave it *Staggered* (`SkillData.user_inflicts`): Defense and Spirit halved at once, it keeps any action left this round and loses the whole next round (new `StatusEffectData.starts_next_round`), looping the vendor `stagger` animation (`StatusEffectData.rest_anim`). **Injured idles** are per visual (`CombatantVisual.injured_idles`): form one ends at half HP, so it shows `idle_hp50` at 75% and `idle_hp25` at 62.5% (its own half and quarter); form two has none. **Entrance:** the free pack has no `entrance` animation, so the boss fades in inside its blink-arrival effect. Hit frames and heights are measured on the W row of the sheets. The red-glow "enraged" sheets were not extracted (≈45 MB, risk R11). **Balance** (`tools/boss_sim.gd`, no items or gear, sensible play): a level 4 party wins about 73% in ≈11 rounds, level 3 about 30%, level 2 almost never; potions, Holy Water (Holy weakness), the Worn Longsword and the crypt crate's Pilgrim's Chalice (Shadow ×0.5 against Blood Mist) tip it further.
- [x] Boss FX: blink arrival, phase trail, blood mist, bone lance via our own `scenes/battle/fx_player.tscn` (reads the vendor effect SpriteFrames and JSON; the vendor `Fx` autoload is not registered, so we keep 5 autoloads). The bestiary/boss intro card uses the dfgui runic portrait frame.
  - *As built:* no separate `fx_player.tscn`: the Phase 5 `BattleFx` already plays one-shot effects. The boss pack ships its effects as sheets + JSON only, so `build_boss.gd` cuts them into `data/fx/frames/*_spriteframes.tres` and wraps them in FxSpecs: blink arrival (`CombatantVisual.entrance_fx`, played in the battle intro), the second form's blink arrival (`phase_fx`, on the phase change), phase trail (`SkillData.user_fx` on Phase Rush, both forms), blood mist and bone lance (`impact_fx`). Still 5 autoloads. **Not built:** a bestiary / boss intro card (nothing in the game shows one yet; the battle intro line introduces the boss).
- [x] Example quest: "Silence in the graveyard": talk → investigate 3 graves → boss → report back.
  - *As built:* Elder Maren gives it. The graves (searchable only once she asked): the widow's stone by the path (the old `examine_headstone`), the old soldier's grave in the west field (`Grave12`) and the fresh mound in the east field (`Grave23`, which also gives the **Skull Key**, opening the new locked crate by the crypt: a Pilgrim's Chalice). The Hexblade, if recruited, explains the sealed door. Then the crypt door fight, then the report (turn-in) to the Elder. Maps patched directly; `MapBuildKit.quest_target()` / `boss_trigger()` and `npc(..., frames_path)` put everything in the builders too.

**Automated verification**
- [x] `test_quest_log.gd`: stage advance by flag, no regression, completion emits a signal once. (Also: several flags per stage, flags set early, givers and targets, GameState start/advance/new game.)
- [x] `test_boss_trigger.gd`: does not fire without required flags; fires once; sets `defeated_flag` on victory; never fires again. (Also: a defeat sets nothing and ends in Game Over.)
- [x] `test_boss_battle.gd`: seeded boss fight hits phase change once; enraged/injured idle selection by HP threshold. (Also: stagger timing and Defense, two actions a round, boss rules, the sprite's stagger pose, and the balance band from `tools/boss_sim.gd`.)
- [x] Extra: `test_dialogue_extensions.gd` (the five new keys, validation, portrait and music cue) and `test_quest_flow.gd` (the quest end to end with icons, journal, map markers and the HUD notice; graves before the quest; the villagers' lines).
- [x] `tools/check.ps1` exits 0. (Run as `tools/check.sh` from WSL: 381 tests, 0 failures.) Outside the suite: windowed captures of the villagers, the sealed crypt door, the Journal and Map tabs (sepia picture) and the boss fight in both forms. Also fixed on the way: Game Over now clears the music push stack (a boss defeat left the map track waiting), and `test_recruitment` waits for the Warden's fade by a generous frame bound instead of 60 frames.

**Manual verification**
- [ ] Complete the example quest end to end, including the two-phase boss and the reward from the quest giver.
- [ ] Listen to `mus_boss_assassin`, `mus_story_dread` and `mus_story_sorrow` (and their loop seams).
- [ ] Look at the map page's sepia pictures in a windowed run (the capture needs a renderer).

---

## Phase 11: Save/load and Chapter 1 content

[Dependencies: **Phase 10**]

**Tasks**
- [ ] `GameState.to_dict()/from_dict()` covering party, inventory, gold, flags, quests, map + position, play time, encounter modifiers.
- [ ] `SaveManager`: 3 slots, `user://saves/slot_N.json`, `"version": 1`, migration hook, atomic write (write `.tmp`, then rename), corrupt-file handling.
- [ ] Save points (shrine/bell `Interactable`) + title screen "Continue"/"Load".
- [ ] `scenes/ui/menus/save_load_menu.tscn`: 3 slot panels with a thumbnail (viewport capture downscaled to 320×180, stored next to the save), location name, play time, level and gold (`66_gold` icon), and an overwrite confirmation dialog.
- [ ] Chapter 1 music coverage per region (town, dungeon, story cues), with licence rows completed.
- [ ] Story selection (one of §7 or a new one) and **Chapter 1 script** approved by the user **before** content production.
- [ ] Chapter 1 maps from available kits (village, castle courtyard, necropolis interiors-as-exteriors) and region encounter tables with palette-variant enemy tiers.
- [ ] Battle backgrounds per region, following the approach chosen at the Phase 5 style check (graveyard = Gimble's; haunted forest available for a forest region; others composite or sourced).
- [ ] Balancing spreadsheet (`docs/balance.csv`) and a seeded headless "simulate 1000 battles" tool for win-rate checks.

**Automated verification**
- [ ] `test_save_roundtrip.gd`: `from_dict(to_dict(state))` equals the original for a populated state.
- [ ] `test_save_corrupt.gd`: truncated/invalid JSON → `load_slot()` returns an error, never crashes, and leaves the slot listing intact.
- [ ] `test_save_migration.gd`: a version-0 fixture migrates to v1.
- [ ] `test_balance_sim.gd`: for each region at the target party level listed in `docs/balance.csv` (e.g. graveyard outskirts lv 2), seeded 1,000-battle win rate ≥ 90% against regular groups.
- [ ] `tools/check.ps1` exits 0.

**Manual verification**
- [ ] Save in the graveyard, quit, Continue: same position, party, items, quest stage and opened chests.
- [ ] Play Chapter 1 start to finish without debug keys.

---

## Phase 12: Polish, audio, optimisation, release build

[Dependencies: **Phase 11**] (audio tasks build on the Phase 7A pipeline and depend on the user supplying audio)

**Tasks**
- [ ] Full SFX library coverage for every category in `AUDIO_GUIDELINES.md` §3 (magic per element, all enemies, progression, weather), with ≥ 3 variants for frequent sounds.
- [ ] Mix pass: loudness targets (music ≈ −18 LUFS, ambience ≈ −24 LUFS, SFX peaks ≤ −1 dBTP), loop seams checked, battle ducking tuned.
- [ ] Settings additions: battle speed (presenter time scale), key rebinding (optional).
- [ ] Weather/ambience per map (rain in the graveyard with rain audio layer + thunder synced to lightning FX, blood-moon event), wind sway on trees.
- [ ] UI polish pass against the `ART_GUIDELINES.md` §8 checklist for every screen. Missing UI pieces from `UI_ASSET_CATALOG.md` §4 are replaced if they've been sourced.
- [ ] Credits screen generated from `docs/asset_manifest.csv` (every attribution line, OFL notice for fonts).
- [ ] Battle juice: screen shake on crits, hit-stop, element FX (lightning from the weather pack for LIGHTNING spells).
- [ ] Performance: VRAM audit (remove unused vendor animations from SpriteFrames), texture compression settings (VRAM compressed with mipmaps for world, lossless for UI), max 16 lights per canvas item respected, profiler pass.
- [ ] Install the matching Godot 4.6 export templates; Windows export preset; `CREDITS.md` in-game credits screen (SovDigital, Gimble's Games, Alegreya OFL, audio sources).
- [ ] Final licence check of every shipped asset.

**Automated verification**
- [ ] `test_asset_manifest.gd` passes with **zero** `release_blocker = yes` rows (release gate: dfgui licence confirmed or replaced).
- [ ] `test_credits.gd`: every manifest row whose `attribution` is not "none" appears in the credits screen text.
- [ ] `test_audio_coverage.gd`: every `MusicTrack`/`SfxSet` referenced from `data/` and map scenes points to a non-placeholder stream.
- [ ] Export runs headless: `"$GODOT" --headless --path . --export-release "Windows Desktop" export/game.exe` exits 0.
- [ ] `tools/check.ps1` exits 0.

**Manual verification**
- [ ] The exported `.exe` runs on a second Windows PC: Chapter 1 is playable, ≥ 60 FPS, load times under 3 s per map, all audio audible and adjustable.

---

## 10. Code quality and development standards

**Language and typing**
- Godot 4.6, GDScript only. **Static typing everywhere**: typed vars, params, returns, `Array[T]`, `Dictionary[K, V]`. The `untyped_declaration` warning is treated as an error.
- `class_name` only for types used across files (Resources, logic classes). Scene scripts used in one place don't need it.

**Naming**
- Files and folders: `snake_case` (`battle_engine.gd`, `village_01.tscn`).
- Classes: `PascalCase`. Functions/vars: `snake_case`. Constants/enum values: `UPPER_SNAKE`. Private members: `_leading_underscore`.
- Signals are past-tense verbs (`battle_ended`, `interacted`). Requests are method calls, not signals.
- Node names in scenes: `PascalCase` (`EnemySlots`, `CommandMenu`).
- Data ids: `snake_case` StringNames matching the filename (`wolf`, `minor_heal`).

**Structure**
- One responsibility per script. **A soft limit of ~300 lines** is a trigger to split.
- Scene scripts handle presentation and input; rules live in `scripts/`.
- `@onready var x: T = %UniqueName` for scene-internal references (no long `$A/B/C` paths).
- Dependencies are injected via `@export` or `setup()` methods, not `get_node("/root/...")`. Autoloads are referenced by name only from scene scripts, never from pure logic classes.
- Resources loaded from disk are **read-only at runtime**; runtime copies are RefCounted wrappers. Use `duplicate(true)` only when truly needed.
- Signals connect in code inside `_ready()` (visible in diffs) unless the connection is purely intra-scene UI.
- No `await` in pure logic. Async lives only in controllers/presenters.

**Documentation**
- `##` doc comments on every `class_name`, public method and exported property.
- Each folder with non-obvious conventions gets a short `README.md`.
- Every gameplay constant has a name and a comment (no magic numbers in formulas).

**Testing**
- Every pure-logic class has a `tests/unit/test_<name>.gd`.
- Every new scene type gets a smoke test (instantiates headless).
- Seeded RNG in all tests. No wall-clock timing in tests.
- `tools/check.ps1` must pass before every commit.

**Dependencies**
- No third-party addons without explicit approval. Vendor MIT-0 scripts (ambience/weather) are allowed but stay in `addons/sovdigital/` unmodified. If we need changes, we wrap or copy them into `scripts/` with attribution.

**Version control**
- Small commits per task, using imperative messages (`Add EncounterRoller with weighted group selection`).
- Large binaries: source zips are never committed. Copied assets are committed (consider Git LFS if the repository goes to a remote).

---

## 11. Risks, technical challenges, missing assets

| # | Risk / gap | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| R1 | Godot 4.1 → 4.6 upgrade | Blocks Phase 1 | Low (project is empty) | Fresh 4.6 install; verify vendor `.tres` load in a smoke test |
| R2 | Gimble's kit is a **sampler**: one bar colour, 15 item icons, 4 status icons, 2 backgrounds | Repeated icons, missing status art | Certain | dfgui supplies the MP/XP bar colours and extra icons; text tags for missing statuses. The full packs use the same filenames (drop-in upgrade, user's decision to buy) |
| R3 | Pixel UI/backgrounds + HD painted sprites mismatch | Visual inconsistency, most visible in battle | Medium | 2× integer UI, Alegreya text, shared muted palette, fog and shadows in battle; go/no-go style check in Phase 5; review again at Milestone 1 |
| R2b | **`dfgui` (All Assets.zip) licence is unknown**: no LICENSE, README or author | Could block a public release | Medium | Used only for complements (bars, icons, frames) referenced by the Theme and widgets. Replaceable by the full Gimble's packs. Confirm the source before release |
| R3b | Gimble's README states its icons, portraits and backgrounds were **AI-assisted** | Store disclosure (e.g. Steam's AI-content survey), possible player perception | Certain if released | Record it in `CREDITS.md`. Answer store disclosures accurately. Replacing those assets later is a user decision |
| R4 | **No audio at all** | Slice and game feel flat | Certain (the slice shipped silent) | Audio architecture from Phases 1/6/7; **Phase 7A** (audio setup) is the next step and starts with the user sourcing the slice set from `AUDIO_CATALOG.md`; commission the main theme if budget allows |
| R4b | Audio licences vary per file (CC BY-NC, ND, unclear provenance) | Legal risk at release | Medium | Acceptance rules in `AUDIO_CATALOG.md` §A; manifest test blocks missing or non-commercial licences |
| R4c | Mixed audio sources sound inconsistent | Breaks immersion | Medium | Direction and loudness standards in `AUDIO_GUIDELINES.md`; mix pass in Phase 12; prefer few large coherent sources (one music composer/collection) |
| R17b | Cinzel is capitals-only | Long names/menus feel shouty | Low | Use only for short labels/titles; body text stays Alegreya (`FONT_CATALOG.md`) |
| R5 | **No NPC/villager sprites** | Towns feel empty; story NPCs lack identity | Certain | Placeholders (recoloured knights, prop NPCs); acquire a matching SovDigital NPC pack later (**not downloaded**) |
| R6 | **Only one hero sprite** | Party identity weak | Certain | Knight recolours as placeholders; data model is visual-agnostic, so art can be swapped |
| R7 | **No forest/cave/dungeon tiles** | Limits Chapter 1 locations and Story B | Certain | Chapter 1 uses village/courtyard/necropolis; source more kits before Chapter 2 |
| R8 | Missing cast/defend/victory poses | Battle reads less clearly | Certain | Procedural stand-ins (§6.3) |
| R9 | Only 2 battle backgrounds (graveyard, haunted forest) | Other regions lack backgrounds | Certain | Composite scenes from tilesets + fog/grade, or the full Gimble's background pack |
| R10 | Top-down camera angle in side-view battle | Mild perspective oddness | Medium | Background at the same angle; slight vertical stagger of slots |
| R11 | VRAM/memory from HD sheets (e.g. boss 547×422 × 12f × 8 rows per anim) | Load hitches, VRAM use | Medium | Copy only needed animations; strip unused animations from SpriteFrames; VRAM compression |
| R12 | Asset import time (thousands of PNGs) | Slow iteration | High if whole packs are imported | `.gdignore` on zips; subset extraction; no `frames/` folders |
| R13 | Scope creep (RPGs are huge) | Project never finishes | High | Milestone gate at Phase 7; "Not doing" list; one chapter at a time |
| R14 | Save format churn as systems grow | Broken saves | Medium | Saves only from Phase 11; versioned with migrations |
| R15 | Vendor licence: "not transferable", "no redistribution as stand-alone assets", "no ML datasets" | Legal | Low | Private repository or exclude raw assets; credits; never use the art for AI training |
| R16 | Vendor scripts have no `class_name` and may change in pack updates | Maintenance | Low | Pin copied versions; never edit in place |
| R17 | Alegreya not yet in the workspace | Theme incomplete | Low | Theme falls back to the default font; drop in the TTFs later |
| R18 | 16-lights-per-canvas-item limit (vendor note) | Lighting artefacts in big maps | Medium | Split ground into chunks as the vendor examples do |

**Missing-asset shopping list (for the user to source; nothing will be downloaded by me):**
1. Music: village, dangerous area, battle, boss, victory jingle, game over, title.
2. SFX: UI move/confirm/cancel, sword hits, crit, magic (fire/frost/lightning/holy/shadow), monster cries, footsteps (stone/grass/mud), level up.
3. NPC sprites (villagers, merchant, elder, priest) in matching HD style, 8-dir or at least 4-dir idle.
4. 2–3 additional hero characters (mage/priest, rogue/archer) in matching style.
5. Forest and cave/dungeon tilesets in the same SovDigital line.
6. Optional: the full Gimble's packs (more item/status icons, portraits, backgrounds, bar colours). Filenames match the sampler, so they are a drop-in upgrade.
7. Source and licence of the `dfgui` kit (`All Assets.zip`).
8. Icons for Sleep/Stun and elemental spells (frost, lightning, holy, shadow), if the full packs don't cover them.
9. A world chest sprite (shut and open) in the HD style; chests use the courtyard supply crate until then (Phase 9).
10. SFX: chest open, chest locked, wooden door / iron gate (Phase 9 hooks are built and silent).
11. Alegreya font files + `OFL.txt`.
12. Boss audio (Phase 10 hooks are built): a boss theme in the music direction (the interim is *Shadowforge Convergence*), and Blade Assassin vocalisations (breath, laugh, cry, death) for its `cry_sfx` / `death_sfx`.
13. A worn parchment page (9-slice) for the Journal (dark panel until then), and villager / story portraits (the new villagers have none).

---

## 12. Questions requiring approval

Each item has a **default** that the plan already assumes, so the plan stays actionable. Confirm or override.

| # | Question | Default assumed in this plan |
|---|---|---|
| Q1 | Round-based (DQ) or individual-turn (CTB) battles? | **Round-based** |
| Q2 | Max active party size? | **3** |
| Q3 | Include **Flee** as a command (not in your list)? | **Yes**, disabled vs bosses |
| Q4 | Test framework: own minimal runner vs GUT addon? | **Own runner** (no dependency) |
| Q5 | Dialogue format: JSON vs Resources vs Dialogic addon? | **JSON** |
| Q6 | Defeat consequence: Game Over → title/load vs DQ-style "revive at church, lose half gold"? | **Game Over → Load / Title** (DQ-style can be added in Phase 11) |
| Q7 | UI scale: Gimble's 2× files plus dfgui ×2, or ×4 for larger menus? | **2×**, re-evaluated after Phase 1's title screen |
| Q13 | Where is the `dfgui` kit (`All Assets.zip`) from, and what is its licence? | Used now; **release blocked** until confirmed (R2b) |
| Q8 | Audio sourcing: you obtain the slice set (free sources per `AUDIO_CATALOG.md`, paid packs, or a commission)? | **You source the slice set at the start of Phase 7A** (Step 0); the game stays silent until then |
| Q14 | Typography: adopt Cinzel for titles/names alongside Alegreya; skip Press Start 2P? | **Yes / skip**, confirmed after the Phase 1 specimen scene |
| Q15 | AI-generated SFX (ElevenLabs via the available skill) acceptable as a source? | **No** by default (store disclosure; consistency); revisit if gaps remain |
| Q9 | Which story concept (A/B/C/other)? | **Decide before Phase 11**; nothing story-specific before then |
| Q10 | Git: initialise a repo now (Phase 1) and keep it local/private? | **Yes, local**; remote/LFS later |
| Q11 | Exploration camera zoom 0.75 (~20×11 tiles visible): closer or wider? | **0.75**, tuned in Phase 2 |
| Q12 | Use the vendor MIT-0 ambience/weather scripts as-is? | **Yes** |

---

## What we are NOT doing (now)
- No overworld/world map, vehicles, day-night gameplay cycle, crafting, fishing or mining (even though dfgui ships icons for them).
- No equipment visuals on sprites (paper-doll).
- No localisation, achievements, mobile/console ports or controller rumble.
- No procedural generation.
- No modifications to anything inside `assests/`.
- No downloads of new assets, fonts or addons by the assistant.

## References
- `ASSET_ANALYSIS.md`: full asset inventory and classifications.
- `ART_GUIDELINES.md`, `UI_ASSET_CATALOG.md`, `FONT_CATALOG.md`, `AUDIO_GUIDELINES.md`, `AUDIO_CATALOG.md`: UI, typography and audio direction.
- Vendor docs inside the zips: `README.txt` (characters: frame sizes, pivots, directions), `village/README.txt`, necropolis `README.txt` (Godot 4.6 TileSet usage, Y-sort, physics layers), `godot/ambience/README_AMBIENCE.txt`, `godot/weather/README_WEATHER.txt`, `WeatherEffectsFree/godot/fx_spawn/README_GODOT.txt`.
