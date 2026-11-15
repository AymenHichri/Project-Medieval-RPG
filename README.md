# The First Heresy

**The First Heresy** is a dark fantasy 2D JRPG built in **Godot 4** with **GDScript**. It follows the structure of classic JRPGs: towns, dangerous regions, random encounters and turn-based battles. That structure carries a world of cosmic horror, body horror and fragmented history, where what people believe about the past is not always what happened.

The game is in early development. This README describes the intended direction and the current state of the project, and keeps the two clearly apart.

---

## Contents

- [About the Game](#about-the-game)
- [Story and Setting](#story-and-setting)
- [Key Features](#key-features)
- [Visual and Audio Direction](#visual-and-audio-direction)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Development Status](#development-status)
- [Assets and Credits](#assets-and-credits)
- [Development Notes](#development-notes)
- [License](#license)

---

## About the Game

| | |
|---|---|
| **Genre** | Dark fantasy JRPG · cosmic horror · body horror |
| **Exploration** | Top-down 2D (three-quarter view), free 8-direction movement |
| **Combat** | Classic turn-based, round-based battles with side-view presentation |
| **Encounters** | Random encounters in dangerous regions; towns are safe |
| **Party** | Multiple playable characters, each with their own motivations and secrets (planned) |
| **Platform** | PC (Windows first) |

The player explores villages, graveyards and ruins, examining what remains and piecing together a history that has been deliberately erased. Danger comes from random encounters in the wild and from the world itself.

Battles use a round-based system. You choose commands for every party member, then all combatants act in order of speed. The party stands on the left and enemies on the right, in a side-view layout inspired by classic JRPGs.

The planned party is not a group of loyal heroes. Each companion has their own reasons for travelling, things they will not say, and goals that may eventually conflict with the others'.

The story is told through the environment rather than through long cutscenes: inscriptions, documents, item descriptions and conversations with people who may be mistaken, or lying.

## Story and Setting

> The premise below is a working concept. Story details are still in development and may change.

The world is a medieval kingdom built on the remains of an older civilisation.

Long ago, humanity rose against its gods and killed them. That conflict is remembered, where it is remembered at all, as the **War of the Divine**. Free of the gods, humanity founded new kingdoms and over the centuries removed them from its histories, its temples and its language.

But the world never recovered from their deaths. Their influence remains in the land, in its creatures and in the laws that hold existence together.

Now, centuries later, something is changing. Ancient places are waking. People are disappearing, not only from their homes but from records and memory. Living bodies are beginning to change in ways that should not be possible.

What really happened when the gods died, and what humanity chose to forget, is buried somewhere beneath the kingdom.

### Narrative pillars

- **Fragmented lore.** History is told through ruins, inscriptions, documents, item descriptions and NPC dialogue, not through exposition.
- **Unreliable accounts.** Sources contradict each other, and the official record cannot be trusted.
- **Morally complicated people.** Companions and NPCs have their own agendas, and few choices are clean.
- **Discovery over explanation.** Understanding is earned by exploring and paying attention.
- **Contrast.** Moments of warmth, kindness and beauty make the horror around them hit harder.

## Key Features

### Implemented

These systems exist in the repository and are covered by automated tests. Most of them are still at prototype level and use placeholder content.

| Area | What exists |
|---|---|
| **Exploration** | Free 8-direction movement for the Knight with direction-aware idle and walk animations, a following camera with per-map bounds, and Y-sorted maps |
| **Maps** | Two maps: `village_01` (a village) and `graveyard_01` (a necropolis outskirts area), connected by fade transitions and spawn points |
| **Interaction** | An interaction probe and examinable objects (headstone, sarcophagus, bone pyre, notice board) showing text in a dialogue box |
| **Random encounters** | Encounter zones with step-based rolls, a grace period after entering a map or finishing a battle, and weighted enemy groups including a rare group |
| **Battle logic** | A deterministic, node-free rules engine: turn order, physical and magic damage, critical hits, elemental affinities, Defend, Flee, enemy AI, rewards, and two-phase enemy support |
| **Battle presentation** | Side-view battle scene with command menu, target selection, HP/MP bars, damage popups, battle messages and a results screen |
| **World ↔ battle loop** | Walking into an encounter starts a battle and returns the player to the same position afterwards |
| **Content data** | One playable character (Knight); four enemies (Wolf, Goblin Scout, Skeleton, Charred Skeleton); five skills (Attack, Charged Strike, Whirlwind, Ember, Minor Heal); one item (Minor Potion); six status effects (Bleed, Burn, Curse, Blessed, Sleep, Stun) |
| **UI foundation** | A generated theme and colour palette, a placeholder title screen and a typography specimen scene |
| **Audio architecture** | An `AudioManager` with music, sound-effect and ambience managers (no audio assets yet) |
| **Atmosphere** | Vendor ambience and weather shaders used in the existing maps |
| **Tooling** | Asset extraction, map and data builders, a licence manifest check, and a headless test runner |

### Planned / in development

Nothing in this list is finished.

- **Vertical slice (Milestone 1):** an NPC conversation with a choice, levelling, game over, a pause menu, a settings menu, the final title screen and a dialogue box with portraits.
- **Party:** up to three active members with their own stats, skills, motivations and secrets.
- **Progression:** experience curves, level-ups and skill unlocks.
- **Inventory and equipment:** items in the field and in battle, four equipment slots and shops.
- **Dialogue and quests:** full branching dialogue, NPCs, a quest journal and story flags.
- **Boss encounters:** scripted, non-random battles including a two-phase boss.
- **Save and load:** save slots (the `SaveManager` is currently a stub).
- **Chapter 1:** the first complete chapter of the story.
- **Audio:** music, sound effects and ambience beds.
- **Release:** polish, optimisation and an exported Windows build.

## Visual and Audio Direction

### Visual style

The world is a **dark medieval fantasy**: grounded, serious and restrained. Colours are desaturated earth, slate, bone and rust. Scenes are cool and dim, and warmth comes only from fire, lamps and gold. Magic is rare and subtle.

The project deliberately uses **two art layers**:

| Layer | Style | Rendering |
|---|---|---|
| **World** (maps, characters, enemies, effects) | HD painted sprites seen from a ~30° top-down camera | Linear filtering with mipmaps |
| **Interface** (UI, icons, portraits, battle backgrounds) | Hard-edged pixel art | Nearest filtering, integer scaling only |

Maps are graded with dusk, fog, night and blood-moon presets so that every area shares the same oppressive mood.

### UI and typography

The interface uses dark iron panels, crimson buttons, parchment-coloured text and a gauntlet cursor. All colours come from one semantic palette, and all styling comes from a single generated Godot theme.

Planned typography:

- **Cinzel** for titles, headings and names.
- **Alegreya** for body text, dialogue and numbers.

Both fonts are chosen but not yet added to the project, so the game currently uses Godot's default font.

### Music and sound

The world should sound *old, cold and hollow, with sparse warmth and dread that builds slowly*. The intended palette is orchestral and chamber fantasy with medieval instruments: hurdy-gurdy, nyckelharpa, viola da gamba, lute, church bells, low choirs, drones and silence. Battle music is the energy peak; exploration music sits quietly under the ambience. Chiptune, bright fanfares and comedic stingers are out of scope.

No music or sound effects have been added yet. See [`AUDIO_GUIDELINES.md`](AUDIO_GUIDELINES.md) and [`AUDIO_CATALOG.md`](AUDIO_CATALOG.md).

## Technology Stack

| Component | Details |
|---|---|
| **Engine** | Godot **4.7.2** (stable), Forward+ renderer |
| **Language** | GDScript with strict static typing (untyped declarations are errors) |
| **Resolution** | 1920×1080 base viewport, `canvas_items` stretch, `expand` aspect |
| **Data** | Godot `.tres` Resources for game content; JSON for dialogue |
| **Testing** | A custom headless test runner (`tests/test_runner.gd`) with unit and smoke tests |
| **Tooling** | GDScript build tools run headless; Python 3 scripts for asset extraction and checks; Bash (WSL) and PowerShell check scripts |
| **Addons** | SovDigital ambience and weather scripts and shaders (MIT-0), kept unmodified in `addons/sovdigital/` |
| **Version control** | Git; the original asset archives are excluded |

**Autoloads:** `GameState`, `AudioManager`, `SaveManager`, `DialogueManager`, `SceneManager`.

**Input:** keyboard and gamepad. Move with WASD, the arrow keys, the D-pad or the left stick. Accept with Enter, Space or E (pad A). Cancel with Esc or Backspace (pad B). Open the menu with Tab or M (pad Start).

## Project Structure

```
.
├── addons/sovdigital/   Vendor ambience and weather scripts and shaders (MIT-0, unmodified)
├── assests/             Original downloaded asset archives (not committed, never modified, ignored by Godot)
├── assets/
│   ├── fonts/           Font folders (Alegreya, Cinzel), files pending
│   └── vendor/          Asset copies extracted from the archives: sovdigital/, gimbles/, dfgui/
├── data/                Game content as Resources and JSON
│   ├── characters/  enemies/  skills/  items/  status_effects/
│   ├── encounters/      Encounter tables
│   ├── dialogue/        Dialogue JSON
│   └── visuals/         Battle visuals for each combatant
├── docs/                asset_manifest.csv: licence record for every external file
├── scenes/
│   ├── boot/            Entry scene (placeholder title screen)
│   ├── world/           Map base, maps, player, props and world components
│   ├── battle/          Battle scene, presenter, sprites, backgrounds and battle UI
│   └── ui/              Theme, palette, dialogue box, fade overlay, widgets and debug scenes
├── scripts/
│   ├── autoload/        The five global singletons
│   ├── battle/          Pure battle rules (no nodes, deterministic, seeded RNG)
│   ├── resources/       Data Resource class definitions
│   ├── rpg/             Shared RPG helpers (elements, targeting, rate modifiers)
│   ├── audio/           Music, SFX and ambience managers
│   ├── dialogue/        Dialogue data model
│   └── ui/              UI palette
├── tests/
│   ├── unit/            Logic tests
│   └── smoke/           Scene, asset and integration tests
└── tools/               Build scripts, asset pipeline and project checks
```

> The original archive folder really is named `assests/`. It is kept separate from `assets/` on purpose and should not be renamed.

Several files are **generated** and should not be edited by hand. The maps and props are generated by `tools/map_builders/`, and the theme by `tools/build_theme.gd`. Folder-specific notes are in `scenes/world/README.md`, `scenes/battle/README.md` and `scripts/battle/README.md`.

### Design documents

| Document | Content |
|---|---|
| [`PROJECT_PLAN.md`](PROJECT_PLAN.md) | Architecture, system designs, roadmap and phase breakdown |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Coding standards, tools and test commands |
| [`ART_GUIDELINES.md`](ART_GUIDELINES.md) | Visual pillars, art layers, palette and UI styling |
| [`UI_ASSET_CATALOG.md`](UI_ASSET_CATALOG.md) | UI asset inventory and gaps |
| [`FONT_CATALOG.md`](FONT_CATALOG.md) | Typography evaluation |
| [`AUDIO_GUIDELINES.md`](AUDIO_GUIDELINES.md) / [`AUDIO_CATALOG.md`](AUDIO_CATALOG.md) | Audio direction, architecture and sourcing |
| [`ASSET_ANALYSIS.md`](ASSET_ANALYSIS.md) | Full inventory of the downloaded asset packs |
| [`CREDITS.md`](CREDITS.md) | Asset credits |

## Getting Started

### Prerequisites

- **Godot 4.7.2 stable** (standard build, not .NET). Use the console build to run the headless tools and tests.
- **Python 3** for the asset pipeline and the source-checksum step of the full check.
- **Git**.

### Open and run

1. Clone or copy the repository.
2. Open Godot, choose **Import**, and select `project.godot` in the repository root.
3. Wait for the first import to finish. It can take a while because of the HD sprite sheets.
4. Press **F5** to run the game. It starts at the placeholder title screen; **New Game** opens `village_01`.

Individual scenes can be run directly with **F6**. Useful ones:

| Scene | Purpose |
|---|---|
| `scenes/world/maps/village_01.tscn` | The village map |
| `scenes/world/maps/graveyard_01.tscn` | The graveyard outskirts, with random encounters |
| `scenes/battle/debug_battle.tscn` | A standalone test battle |
| `scenes/ui/debug/typography_specimen.tscn` | Typography and theme preview |

### Debug keys (exploration, debug builds)

| Key | Action |
|---|---|
| F3 | Toggle the debug overlay |
| F4 | Turn random encounters on or off |
| F5 | Force an encounter in the current zone |

### Checks and tests

Run the full check from the project root before every commit. Set `GODOT` to your Godot console executable:

```bash
# WSL / Linux
GODOT=/path/to/Godot_v4.7.2-stable_console tools/check.sh

# Windows PowerShell
$env:GODOT = "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"; .\tools\check.ps1
```

To run a subset of tests:

```bash
godot --headless --path . -s res://tests/test_runner.gd -- --filter=<name>
```

> The first step of the full check verifies the original asset archives in `assests/` against `tools/source_assets.sha256`. Those archives are not in the repository, so on a fresh clone without them this step will report a failure even though the project itself runs.

Other tools (asset extraction, theme rebuild, map rebuild, project settings) are listed in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Development Status

**Stage: pre-alpha, working toward the first vertical slice.**

The technical foundation is in place. Exploration, map transitions, the battle engine, battle presentation and random encounters all work, and the full world → battle → world loop runs. There is no story content yet, no audio, and only one playable character. Placeholder screens and data are still in use.

### Roadmap

From [`PROJECT_PLAN.md`](PROJECT_PLAN.md). Phase sizes are rough estimates, not commitments.

| Phase | Name | Status |
|---|---|---|
| 1 | Foundation and asset pipeline | Done (some manual review items open) |
| 2 | Exploration prototype | Done (manual review open) |
| 3 | Map transitions and interaction | Done (manual review open) |
| 4 | Battle core (logic, headless) | Done |
| 5 | Battle presentation | Done (battle background style decision open) |
| 6 | Random encounters | Done (manual review open) |
| 7 | **Milestone 1: vertical slice** | Next |
| 8 | Party, progression, status effects in play | Planned |
| 9 | Inventory, equipment, items, shop | Planned |
| 10 | Dialogue, NPCs, quests, boss | Planned |
| 11 | Save/load and Chapter 1 content | Planned |
| 12 | Polish, audio, optimisation, release build | Planned |

### Known gaps

- No music or sound effects yet.
- The Alegreya and Cinzel font files have not been added.
- Only one hero sprite (the Knight). Other party members will use placeholder recolours until matching art is found.
- No NPC sprites, and no forest, cave or dungeon tilesets.
- The `dfgui` UI kit has an unknown source and licence. This blocks a public release until it is resolved.

## Assets and Credits

The full and current list is in [`CREDITS.md`](CREDITS.md), and the licence of every external file is recorded in [`docs/asset_manifest.csv`](docs/asset_manifest.csv).

| Asset | Creator | Licence |
|---|---|---|
| Knight, Wolf, Skeleton, Goblin Scout, Blade Assassin; Medieval Village, Castle Courtyard and Necropolis tilesets; Weather Effects | [SovDigital](https://sovdigital.itch.io) | SovDigital free licence (`LICENSE.txt` in each pack folder) |
| Ambience and weather scripts and shaders | [SovDigital](https://sovdigital.itch.io) | MIT-0 |
| Dark Fantasy Kit Sampler (UI, icons, portraits, battle backgrounds) | "Art by Gimble's Games", [gimblesgames.itch.io](https://gimblesgames.itch.io) | Gimble's free licence (`assets/vendor/gimbles/LICENSE.txt`). The vendor states this art was made with AI-assisted generation |
| `dfgui` UI kit (bars, icons, frames) | **Unknown** | **Unknown: to be confirmed before release** |
| Alegreya (planned) | Juan Pablo del Peral, Huerta Tipográfica | SIL Open Font License 1.1 |
| Cinzel (planned) | Natanael Gama | SIL Open Font License 1.1 |
| Engine | [Godot Engine](https://godotengine.org) | MIT |

The vendor art licences allow use in commercial games but **forbid redistributing the graphics as stand-alone assets** and using them to train machine-learning models. The graphics in this repository are only licensed for use in this project.

## Development Notes

This is a **solo-developed project**. Outside contributions are not being accepted at this time.

[`CONTRIBUTING.md`](CONTRIBUTING.md) contains the project's internal development standards, including:

- Static typing everywhere, and one responsibility per script.
- Battle rules stay as pure, deterministic logic, separate from presentation.
- Exactly five autoloads.
- All UI styling comes from the generated theme and palette.
- Nothing in `assests/` is ever modified, and every external file needs a row in the asset manifest.
- No generated art or audio.
- `tools/check.sh` / `tools/check.ps1` must pass before every commit.

## License

The project licence has not been specified yet.

Until it is, all rights are reserved by the author. Third-party assets in this repository remain under their own licences, listed above.
