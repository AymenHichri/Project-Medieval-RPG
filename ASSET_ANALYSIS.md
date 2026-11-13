# Asset Analysis — Dark Fantasy JRPG (Godot 4)

_Date: 2026-11-13 · Method: read-only inspection of the zip archives in `assests/` (Python `zipfile`, no extraction into the workspace). Sample frames were extracted to a temporary scratch folder outside the project for visual review. No asset was modified, moved, renamed or deleted._

---

## 1. Workspace state

| Item | Finding |
|---|---|
| Project root | `C:\Users\AymenH\Desktop\RPG` — empty Godot project (`project.godot`, `icon.svg`, `.godot/`) |
| `project.godot` | `config/features = ("4.1", "Mobile")`, renderer `mobile` |
| Installed editor | **Godot 4.1.2-stable** (`.godot/editor/project_metadata.cfg` → `Godot_v4.1.2-stable_win64.exe`) |
| Asset folder | `assests/` (sic, typo kept — not renamed) — 9 zip archives, **2.6 GB compressed**, ~23,000 PNGs (8 SovDigital packs + `All Assets.zip` dfgui UI kit) · plus `Gimbles_Dark_Fantasy_Kit_Sampler_Free_v1.0.zip` (0.9 MB), for **10 zips** in total |
| `assests/characters/Hero/` | **Empty folder** |
| Git | Not a git repository (`.gitignore` / `.gitattributes` exist from the Godot template) |
| Scripts / scenes | None yet |

## 2. Pack inventory

All packs are by **SovDigital (Sova Digital)**, free editions.

| Archive | Content | Frame / tile size | Notes |
|---|---|---|---|
| `KnightFreeSampler_v2.2.9.zip` | **Knight** — idle 12f, walk 12f, run 12f, attack 6f, attack2 6f, hurt 6f, death 6f · extra moves: combo 17f, charged_strike 14f, dash_strike 12f, jump_slam 11f, whirlwind 11f (+ ring) · steel weapon trails + hit sparks | 232×246 (moves up to 536×346) | 8 dirs; 5 colour variants (black, blue, gold, green, red); `_smooth` 2× frame clips; 128 px copies |
| `WolfFree_v2.0.5.zip` | **Wolf** — idle, walk, run, attack ×3, attack_presenter, hurt, death (11–12f each) | 244×220 | 8 dirs; 4 variants (black, arctic, brown, red) |
| `SkeletonFree_v1.2.6.zip` | **Skeleton** warrior — idle 6f, walk, run, attack, hurt, death + projectile effect | 226×222 | 8 dirs; 4 variants (ivory, charred, ash, jade) |
| `free-goblin-scout-goblinscoutfree-v2-0-2.zip` | **Goblin Scout** — idle, walk, run, attack ×3, hurt, death (12f each) | 214×210 | 8 dirs; 4 scarf variants |
| `BladeAssassinBossFree_v1.3.1.zip` | **Blade Assassin boss** — 2 forms. Form 1: idle 4f, idle_hp50, idle_hp25, walk, run, attack ×4, stagger, hurt, death; enraged (red-glow) copy. Form 2 "Unmasked": attack ×6, idle/hurt/death 12f + 4 effects (blink, phase trail, blood mist, bone lance) | 415×361 / 547×422 | 8 dirs; 3 variants (azure, venom, violet); recolour masks |
| `free-goblin-scout-castle-courtyard-free.zip` | **Castle Courtyard** tileset (flagstones, rutted road, curtain walls, well, barrels, weapon rack, brazier, crate) **+ bundled Medieval Village** tileset (grass, mud street, thatched cottage in 8 facings + damaged/ruined/construction states, fences, wall, market stall, notice board, oak tree, apple cart) | 128 px grid (+ `_sizes/64`) | 4 palettes each (amber, slate, moss, ash); Godot 4.6 TileSet, Tiled files, example scenes, MIT-0 ambience/weather scripts |
| `free-top-down-asset-pack-necropolis-free.zip` | **Necropolis** tileset — bone-flag and ash-soil grounds, skull walls, crypt barracks (8 facings + ruined), graves, gargoyle, obelisk, lantern post, gnarled dead tree, bone pyre (animated), sarcophagus & bone pile (breakable) | 128 px grid (+ `_sizes/64`) | 4 palettes (frost, crimson, moss, ash); Godot 4.6 TileSet; MIT-0 ambience controller (day/dusk/night/storm/fog/**blood moon**) |
| `WeatherEffectsFree_v1.1.0.zip` | Rain/snow/fog/cloud-shadow overlays (1024 px seamless), lightning strike (+forked, ground hit), rain splash, wind gust, splash crown, wade step | 192–672 px effects | MIT-0 `Fx` spawn autoload helper (requires Godot ≥ 4.3) |

### UI strategy (user decision): combine both UI kits
- **Primary: Gimble's Dark Fantasy Kit Sampler** (see below). Used for panels, buttons, cursors, slots, item and status icons, portraits and battle backgrounds, with its vendor 2× files.
- **Complement: dfgui (`All Assets.zip`).** Used for the pieces Gimble's lacks: blue/purple bar fills, command-menu icons, round portrait frames, MENU button and map icons. It is generated as **×2** nearest copies so both kits share the same 2 screen-px per art-px grid.
- Full per-component mapping: `UI_ASSET_CATALOG.md`.

### UI pack — Gimble's Dark Fantasy Kit Sampler (Free) v1.0 (added 2026-11-13, 0.9 MB)
- **Licence (`LICENSE.txt`, Gimble's Games 2026):** free for personal **and commercial** projects; modify, recolour, resize and combine; ship inside the game. **Not allowed:** redistribution as assets, AI/ML training or datasets, claiming as own work or trademark, NFTs. Credit is appreciated ("Art by Gimble's Games").
- **Contents:** 15 item icons and 10 status/HUD icons (32/64/128 px), 6 portraits (Knight, Witch Hunter, Witch, Vampire Lord, Skeleton Warrior, Werewolf; framed and transparent, 64/128/256 px), 2 **side-view** battle backgrounds (Haunted Forest, Graveyard; 320×180 native up to 1920×1080), 13 UI pieces at 1× and 2× (iron panel and tooltip 9-slice, red button in 4 states, bar frame and red fill, 36 px slots, gauntlet and sword cursors), palettes (`.gpl`/`.hex`), and `ui_index.json` with 9-slice margins and hotspots.
- **Assessment:** hard-edged pixel art with no semi-transparent pixels. Desaturated iron, crimson and bone tones that are an excellent fit for the dark-medieval UI direction. The portraits are gritty and realistic (not anime). The battle backgrounds are eye-level side views, which suits side-view combat. Their pixel style versus the HD painted battlers is checked at the Phase 5 style check.
- **Disclosure:** its README states that the icons, portraits and backgrounds were made with **AI-assisted generation**, then cleaned up. This is relevant for store disclosures.
- **Classification:** ✅ Ready: panels, buttons, cursors, slots, icons, portraits, backgrounds. ⚙ Config: 9-slice margins from `ui_index.json`, with the middle set to **tile**. 🛠 Gap: there is only a red bar fill, which dfgui covers.

### UI pack — `All Assets.zip` (dfgui; added 2026-11-13, 43 PNGs, 0.26 MB)

| File(s) | Size (px) | Content |
|---|---|---|
| `dfgui_icon-*.png` ×25 | 26×26 | axe, cauldron, chat bubble, chest, clock, anvil, hammer, crown, fish, food, goblet, helmet, info, monster book, pickaxe, pouch, red book, settings, shield, shirt, shovel, skill book, sword, wand, wardrobe |
| `dfgui_button-{bag,empty,info,settings}.png` | 26×26 | square slot buttons (bag / empty / info / cog) |
| `dfgui_smallbutton.png` | 30×30 | plain dark square button (brown) |
| `dfgui_menubutton{,-hovered,-pressed}.png` | 69×18 | hex-ended button, 3 states — **text "MENU" is baked into the art** |
| `dfgui_partyhud.png` | 216×103 | atlas: square portrait slot, name plate with ornament, two empty bar frames (1 and 2 segments), red / purple / blue bar fills |
| `dfgui_foodbar.png` | 125×15 | green bar fill |
| `dfgui_portraitframe.png` / `dfgui_portraitframe2.png` | 63×60 / 116×116 | round gold-and-gem frame / large runic ring frame |
| `dfgui_mapicons.png` | 147×172 | atlas of 11 map markers (village, crypt, shrine, cave/mine, ship, dog, party, "?", house, flag, scroll map) |
| `screenshots/0[1-5]_*.png` | 305×200 / 960×540 | vendor preview composites (reference only) |

**Assessment.** This is **true hard-edged pixel art** at 1× scale, with a dark slate, gold and crimson palette that fits the dark-medieval tone well. It conflicts with the brief's "HD" world art. Pixel-art UI over HD painted worlds is a common and accepted combination, but only when the UI is scaled by a **whole-number factor** with **nearest** filtering. Combined with Gimble's (which ships 2× files), dfgui is used at **×2**: 52 px icons, a 138×36 menu button and 432×206 party-HUD pieces.

- **Godot limitation:** `NinePatchRect`, `StyleBoxTexture` and `TextureProgressBar` draw borders at the texture's native size and have no pixel-scale option. Using 1× textures in a 1080p UI would make the frames tiny. The fix is a headless tool script (`tools/upscale_ui.gd`) that writes **×2 nearest-neighbour copies** into `res://assets/vendor/dfgui/2x/` and leaves the originals untouched.
- **Licence: UNKNOWN.** The zip has no LICENSE or README and no author name. The source must be confirmed before anything ships.

**Classification**
- ✅ Ready to use (after ×2): the 25 icons. Sword, shield, helmet, shirt, wand, pouch, goblet, food, skill book, red book and monster book map directly to item, equipment, skill and bestiary categories. Also the bar fills and frames (HP = red, MP = blue, XP/ATB = purple or green) and both portrait frames.
- ⚙ Usable with configuration: `dfgui_partyhud.png` and `dfgui_mapicons.png` are atlases and need `AtlasTexture` regions. Bars need `TextureProgressBar` with an under/over/progress setup. `dfgui_smallbutton` and the party-HUD portrait slot can be 9-sliced into **generic window panels** (dialogue box, command menu).
- 🛠 Requires adaptation: `dfgui_menubutton*` has baked "MENU" text. Use it only for an actual Menu button, or paint out the text on a copy to make a generic labelled button.
- ❌ Not present: a dedicated large window/dialogue frame, cursor or selection arrow, scrollbars, checkbox/slider, and element or status-effect icons (fire, frost, poison, …).

### Font — Alegreya (user decision)
- **Chosen UI/dialogue font: Alegreya.** It is a calligraphic old-style serif that fits the dark medieval tone, and it is licensed under **SIL Open Font License 1.1**, which allows embedding and commercial use as long as the OFL text ships alongside it.
- **Status: not yet in the workspace.** The user will place the TTF files (e.g. `Alegreya-Regular.ttf`, `-Bold`, `-Italic`, optionally `AlegreyaSC-*` for headings) and `OFL.txt` into the project. I will not download them.
- It is a vector font, so it renders smoothly next to the 2× pixel UI. Cinzel is recommended for titles and names (see `FONT_CATALOG.md`). Expect this deliberate mix: pixel frames with crisp serif text. The vendor's pixel-font "MENU" lettering is the only bitmap text and will look different from it.

### Common technical format (all character packs)
- **8 directions**, sheet rows `S, SE, E, NE, N, NW, W, SW`; one PNG per animation, columns = frames.
- Per-character JSON: frame size, **feet pivot** (e.g. Knight 116,206), fps, loop flags.
- Ready **Godot 4 `SpriteFrames` .tres** (`<anim>_<dir>` naming), relative paths.
- Each frame also as individual PNG (`frames/<anim>/<DIR>/NNN.png`) — not needed in-engine.
- `_sizes/128/` = 128 px cell-height copies.

### Common technical format (environment packs)
- **Three-quarter top-down camera (~30°)**, square grid, **128 px tiles** (exact 50 % copy in `_sizes/64`).
- Humanoid ≈ 158 px tall at full size (1.23 tiles); vendor states character sheets at 50 % match `_sizes/64`.
- Ground = seamless 1024 px blocks; terrain = 16-tile corner autotiles; large pieces (buildings, walls) are separate sprites placed on a Y-sorted layer.
- Godot TileSet with physics layer `world_solid`, `water`, navigation, occlusion; custom data `surface`, `breakable`, `hazard`.
- Texture filter recommended: **linear with mipmaps** (not nearest).

## 3. Visual assessment

**Art style.** The art is high-resolution, painterly / pre-rendered, with anti-aliased edges and soft shading. It is **not classic hard-edged pixel art.** It is closer to the "HD 2D sprite" look (Diablo II / modern ARPG pre-render) than to Octopath- or Dragon Quest-style pixel art. Palette and mood are earthy, desaturated and grounded, which suits **dark medieval fantasy**. There is nothing anime-like or cartoonish. The necropolis and ash/slate palettes are the strongest match for the target atmosphere. The village (bright grass, daisies, striped market awning) reads as the "cozy" end of the range, but its `ash`/`slate`/`moss` palette variants and the MIT-0 ambience grading (dusk/fog/blood moon) can darken it.

> ⚠ The brief says "HD pixel art". These assets are **HD painted sprites**. They should not be filtered with `nearest`, and mixing them with true pixel art later would clash. **Decided:** the user adopted the HD painted style for the world (PROJECT_PLAN decision D2). Pixel art is used only for the interface layer (`ART_GUIDELINES.md` §2).

**Exploration vs. side-view battle.** I reviewed sample frames directly:
- Every character is drawn for a **top-down 3/4 camera** (≈30° elevation), in 8 directions.
- The **E / W rows are near-profile views seen slightly from above**: knight, wolf, goblin, skeleton and boss all read clearly as "facing left/right". The **SE / SW rows give a 3/4 battle pose** like Octopath or later Final Fantasy titles.
- So the sprites are **not true side-view battle art**, but using the **W row for enemies and the E row for the party** (or SE/SW for a slight 3/4 stage) gives a convincing side-view battle with no redrawing. The elevated camera angle is a mild stylistic inconsistency, not a blocker. A battle background drawn or composed at the same angle hides it.
- Feet pivots are consistent per character, so battle lineup alignment is straightforward.

**Animation coverage vs. battle needs.**

| Battle need | Knight | Wolf | Skeleton | Goblin | Blade Assassin |
|---|---|---|---|---|---|
| Idle | ✅ | ✅ | ✅ | ✅ | ✅ (+ hp50/hp25 variants) |
| Attack | ✅ ×2 + 5 moves | ✅ ×3 | ✅ | ✅ ×3 | ✅ ×4 (+6 in form 2) |
| Hurt / damage | ✅ | ✅ | ✅ | ✅ | ✅ + stagger |
| Death | ✅ | ✅ | ✅ | ✅ | ✅ |
| Advance / retreat | walk/run ✅ | ✅ | ✅ | ✅ | ✅ |
| **Cast / magic** | ❌ (charged_strike can stand in) | n/a | ❌ (projectile FX only) | ❌ | ✅-ish (blood mist / bone lance) |
| **Defend / guard** | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Victory pose** | ❌ | — | — | — | — |

Missing cast and defend poses can be faked cheaply with a tinted flash, a held first attack frame and an FX overlay, or a "brace" tween.

## 4. Compatibility classification

### ✅ Ready to use
- **Knight**: exploration player character (8-dir walk/run/idle, SpriteFrames .tres).
- **Wolf, Goblin Scout, Skeleton**: exploration-ready if we later want visible roaming enemies or NPC ambience.
- **Necropolis, Castle Courtyard, Village environment art**: as PNG art (grounds, walls, buildings, props).
- **Weather overlays & FX PNGs**: rain, fog, lightning (lightning works directly as a "Thunder" spell effect).
- **Boss FX**: blink, blood mist, bone lance (usable as boss skill VFX).
- **Licences**: commercial use allowed (see §6).

### ⚙ Usable with configuration
- **All characters in battle**: use the E row (party) and W row (enemies), or SE/SW. Needs a small `BattleSprite` wrapper that maps logical animations (`idle/attack/hurt/death/cast`) to `<anim>_<dir>` names, and scale tuning.
- **Colour variants**: wolf/goblin/skeleton palette swaps → cheap enemy tiers (e.g. "Ash Skeleton", "Charred Skeleton"), plus the recolour-mask shader for more.
- **Blade Assassin**: two-phase boss (phase 2 swap at the same feet pivot, built into the pack).
- **Godot TileSets (.tres)**: authored for **Godot 4.6** (`TileMapLayer`, terrain sets). They need the **project upgraded to Godot ≥ 4.3 (recommend 4.6.x)**. They will not load correctly in the installed 4.1.2.
- **MIT-0 scripts** (ambience controller, world weather, Fx spawner): useful, but third-party code; adopt selectively, and they also need ≥ 4.3.
- **Scale**: full-size characters on `_sizes/64` maps need 0.5× scale (vendor-documented).

### 🛠 Requires adaptation
- **Village palette**: too bright by default; use `ash`/`slate` variants plus a CanvasModulate/grade to fit the dark tone.
- **Cast / defend / victory poses**: need procedural stand-ins (tween, flash, FX) or new art.
- **Battle backgrounds**: none exist. Must be composed from tileset pieces (ground block + walls + props + fog overlay, rendered behind the battle stage) or sourced later.
- **Knight as the only humanoid hero**: party members 2–3 (the party cap is 3) need recolours (the 5 knight variants) as placeholders, then real art.

### ❌ Not suitable / not present
- **Audio**: no music and no SFX at all.
- **UI**: now **largely covered** by Gimble's + dfgui. Still missing: parchment page, slider/checkbox/scrollbar/tab pieces, and element plus Sleep/Stun icons (see `UI_ASSET_CATALOG.md` §4).
- **Inventory / item / skill icons**: 25 generic icons are present. There is **no** per-item variety (one sword icon for every sword) and no potions or spell elements.
- **Portraits / dialogue busts**: none.
- **NPC townsfolk**: none (no villagers, merchants or priests).
- **Forest, cave and dungeon-interior tilesets**: none. There are single trees only (oak, gnarled), no forest floor or cliff tiles, and no interiors.
- **World/overworld map art**: none.
- **Frame-by-frame PNG folders and per-frame GIF previews**: redundant for the engine. Do not import them, to avoid ~20k needless imports.

## 5. Import strategy (recommendation; nothing done yet)

Importing whole packs into `res://` would trigger tens of thousands of texture imports, slow the editor, and add GBs to the repo. Recommended approach:
1. Keep the zips untouched in `assests/` and add `assests/.gdignore` so Godot skips that folder. The `.gdignore` is a new file; existing files stay untouched.
2. Copy only the needed subsets into `res://assets/vendor/sovdigital/<pack>/…`, preserving each pack's relative folder layout so the `.tres` relative paths keep working: `sheets/`, `godot/`, character JSON, `LICENSE.txt`. Use no `frames/` and no `_smooth` at first. Copy only the colour variants actually used: knight `black`/`gold` (placeholder party), wolf `black`, skeleton `charred` (enemy tiers), plus the environment palettes root + `ash` (+ `slate` for village/courtyard, `frost` for necropolis). The exact list is in PROJECT_PLAN Phase 1.
4. Copy Gimble's `ui/2x`, icons, portraits, backgrounds and palette into `res://assets/vendor/gimbles/`, and the dfgui PNGs into `res://assets/vendor/dfgui/1x/` (×2 copies generated).
3. Exclude `assests/*.zip` from version control (`.gitignore`).

## 6. Licensing summary

All art packs use the same **SovDigital free licence**:
- ✅ Personal **and commercial** games, any platform. Modify, recolour, resize, combine. Ship inside the game. Share with collaborators.
- ❌ No redistribution as stand-alone assets (so a public repo containing the raw assets is a grey area; **keep the repo private** or exclude assets). No claiming as own art. **No ML training datasets.** No NFTs.
- Credit is appreciated but not required. Recommended credit: _"Art by SovDigital (sovdigital.itch.io)"_.
- The licence is "granted to the purchaser … not transferable".
- Helper scripts/shaders (`fx_spawn`, `ambience`, `weather`): **MIT-0**, free to use and change, no credit needed.
- **Gimble's Dark Fantasy Kit Sampler: free licence, commercial use allowed.** No redistribution, no AI/ML training, no NFTs. Credit is optional. Its art is AI-assisted (disclose on stores).
- **`All Assets.zip` (dfgui UI kit): licence UNKNOWN.** There is no licence file. The source and terms must be confirmed before any public build.
- **Alegreya font: SIL OFL 1.1.** Embedding and commercial use are allowed. Ship `OFL.txt` and do not sell the font by itself.

## 7. Gap list (what the vertical slice still needs)

| Need | Status | Stop-gap for the slice |
|---|---|---|
| Hero (exploration + battle) | ✅ Knight | — |
| 2nd–4th party members | ❌ | Knight colour variants (black/gold) as placeholder party |
| 3–4 enemy types | ✅ wolf, goblin, skeleton (+variants), boss | — |
| Village map | ⚙ village + courtyard | ash/slate palette |
| Dangerous outdoor area | ⚙ necropolis / graveyard | — |
| Forest / cave / dungeon | ❌ | Postpone; use necropolis for slice |
| NPC sprite | ❌ | Knight recolour or a static prop (notice board / gravestone "spirit") |
| Battle backgrounds | ❌ | Composite from tileset pieces + fog |
| UI skin | ✅ Gimble's (primary) + dfgui (complements, licence unconfirmed) | Gimble's 2× files + dfgui ×2 copies + Godot Theme |
| Battle backgrounds | ⚙ Gimble's Graveyard + Haunted Forest | Tileset composites for other regions |
| Portraits | ✅ 6 Gimble's portraits | NPCs without a matching portrait get none |
| Font | ⏳ Alegreya chosen (OFL) — files not yet in workspace | Godot default font until the TTF files are added |
| Item / skill icons | ⚙ 25 generic icons | Category icon per item type |
| Element / status icons | ❌ | Coloured text tags ("FIRE", "PSN") |
| Music / SFX | ❌ | Silent slice or user-supplied audio |
| Portraits | ❌ | Not needed for slice |
