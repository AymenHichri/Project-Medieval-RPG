# Art Guidelines — Dark Fantasy JRPG

_Status: draft v1 (2026-11-13). Companion to `PROJECT_PLAN.md` §3, `UI_ASSET_CATALOG.md`, `FONT_CATALOG.md`._

The goal is **one cohesive dark medieval fantasy experience**: serious, mysterious and restrained. Every asset added to the project is checked against this document.

---

## 1. Pillars

1. **Grounded, not cartoonish.** Worn materials, believable proportions, muted saturation. No anime styling, no candy colours.
2. **Darkness with warm islands.** Scenes are cool and dim. Warmth comes only from fire, lamps and gold accents.
3. **Restrained magic.** Magical effects are rare, small and meaningful: thin glows and embers, never rainbow particle storms.
4. **Readable first.** Mood never beats legibility: UI text, HP bars and targets must read instantly.

## 2. Two art layers (deliberate mix)

| Layer | Style | Sources | Filtering | Scaling rule |
|---|---|---|---|---|
| **World layer** (maps, characters, enemies, world FX) | HD painted / pre-rendered sprites, ~30° top-down camera | SovDigital packs | **Linear + mipmaps** | Any scale ≤ 1.0 (camera zoom 0.75). **Never upscale** above 1.2 |
| **Interface layer** (UI, icons, portraits, battle backgrounds) | Hard-edged pixel art | Gimble's kit (primary), dfgui kit (complements) | **Nearest**, no mipmaps | **Integer scale only.** The project standard is **2 screen px per art px** |

Rules:
- Pixel art **never** appears inside the world layer (no pixel props on painted maps), and painted art never appears inside UI panels. The only crossover is **battle backgrounds** (pixel), which sit behind painted battlers. This is reviewed at the Phase 5 style check.
- Pixel assets are never rotated, never scaled by non-integer factors, and never blurred.
- When a new kit is considered, it must match either the world layer's style (HD painted, 128 px grid, humanoid ≈158 px) or the interface layer's style (pixel, 32 px icon grid, dark palette).

## 3. Colour palette (semantic)

All values are taken from the Gimble's kit palette (`palette/dark_fantasy_kit_icons_80.hex`), so UI colours match the pixel art exactly. They are defined once in `scenes/ui/theme/ui_palette.tres` (a `UIPalette` Resource) and in `main_theme.tres`. **No hex codes in individual scenes.**

| Token | Hex | Use |
|---|---|---|
| `bg_abyss` | `#120F14` | Screen fades, behind-menu dim (at 70% alpha) |
| `panel_slate` | `#191A23` | Panel interiors, dialogue background |
| `panel_iron` | `#393333` | Secondary panels, disabled slots |
| `iron_edge` | `#4B4B51` | Thin borders, separators |
| `wood_dark` | `#3C2D28` | Wood accents, scroll handles |
| `wood` | `#643E2E` | Tabs, aged-wood elements |
| `parchment` | `#D5C8B3` | **Primary text**, journal pages (as text colour on dark) |
| `parchment_light` | `#ECE8DF` | Highlighted / selected text |
| `parchment_dim` | `#9C958E` | Secondary text, disabled labels |
| `gold` | `#DCAE4F` | Titles, focus highlight, gold amounts |
| `gold_muted` | `#A47B4F` | Character names, ornament lines |
| `bronze` | `#99693E` | Frames, inactive tabs |
| `blood` | `#8C2821` | HP fill, danger, enemy names |
| `blood_bright` | `#BB322C` | Critical hits, "WEAK!" text |
| `blood_dark` | `#5D201D` | Button pressed, damage flash bg |
| `mana` | `#4277A9` | MP fill, mana numbers |
| `arcane` | `#723D96` | XP fill, magic highlights |
| `curse` | `#5C3266` | Curse status, shadow element |
| `heal` | `#819F57` | Healing numbers, positive stat diff |
| `ember` | `#E56425` | Fire element, burning status |

Contrast: `parchment` on `panel_slate` ≈ 10:1, which comfortably passes WCAG AA for body text. Never put `parchment_dim` on `panel_iron` for essential information.

## 4. UI styling rules

**Materials:** dark iron (Gimble's iron panel), aged wood (dfgui wood tones, `wood` tokens), worn parchment (**missing asset**, see `UI_ASSET_CATALOG.md`), and muted gold, bronze and dark red accents.

- **Panels:** Gimble's `panel_iron_9slice` (2×, 32 px margins, **Tile** middle) for all major windows. The tooltip variant is for small popups. One panel style per screen hierarchy level: never nest more than two panel levels.
- **Buttons:** Gimble's red 9-slice (normal, hover, pressed, disabled). Text in `parchment` and Cinzel 30. Focused buttons also show the gauntlet cursor at the left.
- **Focus and selection:** keyboard/gamepad focus is always visible. Use the gauntlet cursor (2×) plus `gold` text. Never rely on colour alone.
- **Bars:** party bars use the dfgui gold-capped bars (HP red, MP blue, XP purple). Enemy HP uses the Gimble's iron bar frame with red fill. Numbers sit right-aligned inside or beside the bar, in lining numerals.
- **Icons:** 64 px (Gimble's) or 52 px (dfgui ×2) in menus; 32 px (Gimble's 1× ×1) only for status icons in the HUD, where there's no room. Both are integer scales.
- **Portraits:** Gimble's framed 256 px in dialogue, 128 px in menus and the party HUD.
- **Ornament:** one decorative element per panel at most (a gold rule under a title, or a corner mark). No glow on text, and no drop shadows except a 2 px `bg_abyss` outline on world-space text (damage numbers, prompts).
- **Spacing grid:** multiples of **8 px** (4 px for tight icon padding). Screen-edge safe margin: 48 px.
- **Motion:** menus open with a 120 ms fade + 8 px slide, focus changes are instant (no lag), and damage numbers rise 40 px over 600 ms. Use no bouncy easing: `TRANS_QUAD`/`TRANS_SINE`, `EASE_OUT` only.
- **Screen dimming:** modal menus dim the game to `bg_abyss` at 70%.

## 5. Typography (summary; full detail in `FONT_CATALOG.md`)

| Role | Font | Size @1080p | Colour |
|---|---|---|---|
| Game title / logo text | Cinzel Bold (or Cinzel Decorative) | 96–128 | `gold` |
| Screen headings | Cinzel SemiBold | 48 | `gold` |
| Character / speaker names, menu items | Cinzel Regular | 30–34 | `gold_muted` / `parchment` |
| Dialogue, descriptions, lore | Alegreya Regular | 30 | `parchment` |
| Lore quotes, flavour text | Alegreya Italic | 28 | `parchment_dim` |
| Numbers (HP/MP, prices, stats) | Alegreya Medium with `lnum` + `tnum` | 26–28 | context token |
| Damage numbers | Cinzel Black, 6 px `bg_abyss` outline | 48 (crit 64) | white / `heal` / `blood_bright` |
| Small print, tooltips | Alegreya Regular | 24 (minimum 22) | `parchment_dim` |

Use no more than **two typefaces on one screen**. All fonts come from the Theme. No scene overrides `font` or `font_size` except through Theme type variations.

## 6. World art rules

- Palettes: necropolis `ash`/`frost`, village and courtyard `ash`/`slate`. The default bright village palette is only for rare "safe haven" moments.
- Every map has a mood grade (vendor `map_grade` shader or ambience preset). Default exploration preset: **dusk**. Dangerous areas use **night** or **fog**. The **blood moon** preset is reserved for story peaks.
- Lights: warm `PointLight2D` only on real sources (fire, lantern, window). Maximum 16 lights per canvas item, so split large ground pieces.
- Characters: one scale (1.0) everywhere in the world, and Y-sorted on a single `World` node.

## 7. Battle presentation rules

- Background: the Gimble's side-view backgrounds where available, otherwise tileset composites. Always add a fog layer and elliptical shadows under battlers.
- Battlers: party on E-facing rows (left side), enemies on W-facing rows (right side), feet on a common ground band.
- Element colours: Fire `ember`, Frost `mana`, Lightning `parchment_light`, Holy `gold`, Shadow `curse`.

## 8. Consistency checklist (for every new asset or screen)

- [ ] Matches its layer's style (§2) and scaling/filter rule.
- [ ] Colours come from §3 tokens only.
- [ ] Fonts are set via Theme type variations only.
- [ ] Legible at 1920×1080 **and** at 1280×720 windowed.
- [ ] Full keyboard and gamepad navigation with a visible focus.
- [ ] Licence recorded in the relevant catalog and in `docs/asset_manifest.csv`.
