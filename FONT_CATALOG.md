# Font Catalog

_Status: draft v1 (2026-11-13). No font files are in the workspace yet. The user supplies them; the assistant does not download fonts. Items marked **(verify)** must be checked against the downloaded files' metadata and `OFL.txt` before adoption._

## 1. Candidates

| | **Cinzel** | **Alegreya** | **Press Start 2P** |
|---|---|---|---|
| Intended role | Titles, headings, character names, damage numbers | Dialogue, descriptions, lore, numbers | Optional tiny pixel-art details |
| Status | **Recommended** | **Chosen by user** | **Not recommended** (optional, see §3) |
| Creator | Natanael Gama | Juan Pablo del Peral (Huerta Tipográfica) | CodeMan38 (Cody Boisclair) |
| Source URL | https://fonts.google.com/specimen/Cinzel | https://fonts.google.com/specimen/Alegreya | https://fonts.google.com/specimen/Press+Start+2P |
| Licence | SIL Open Font License 1.1 | SIL Open Font License 1.1 | SIL Open Font License 1.1 |
| Commercial use | Yes | Yes | Yes |
| Attribution | Not required in-game. **Must ship `OFL.txt`** with the game | Same | Same |
| Embedding | Allowed (OFL permits bundling in software). Must not be sold on its own. A modified font may not use a Reserved Font Name **(verify RFN in OFL.txt)** | Same | Same |
| Format | TTF (static) or variable TTF | TTF (static + italics) or variable TTF | TTF |
| Styles | Weights 400–900 (variable). **Capitals only by design**: lowercase letters render as small caps | Weights 400–900 + italics. Companion families Alegreya SC and Alegreya Sans | Single weight, 8×8 pixel grid |
| Language coverage | Latin + Latin Extended **(verify)**. No Cyrillic/Greek | Latin, Latin Ext, Cyrillic, Greek, Vietnamese **(verify)** | Latin, Latin Ext, Cyrillic, Greek **(verify)** |
| Figures | Lining | Old-style by default. Lining/tabular via OpenType `lnum`/`tnum` **(verify the features exist)** | Monospaced |

**Godot note:** Godot does not subset fonts by default, so the shipped file is unmodified. That keeps us clear of the OFL "modified version" rules.

## 2. Readability at 1920×1080 (PC, ~60 cm viewing distance)

Plan the evaluation with a specimen scene (Phase 1: `scenes/debug/typography_specimen.tscn`) that shows every style on Gimble's panels, at 1920×1080 fullscreen and 1280×720 windowed. Starting values:

| Style | Font | Size | Line spacing | Notes |
|---|---|---|---|---|
| Title | Cinzel Bold | 96–128 | — | MSDF rendering for smooth scaling and animation |
| Heading | Cinzel SemiBold | 48 | 1.1 | |
| Name / menu item | Cinzel Regular | 32 | 1.1 | All-caps look: keep labels short (≤ 18 characters) |
| Body / dialogue | Alegreya Regular | 30 | 1.3 | Dialogue box ≤ 60 characters per line, 3 lines visible |
| Lore / flavour | Alegreya Italic | 28 | 1.3 | |
| Numbers | Alegreya Medium + `lnum`,`tnum` | 26–28 | — | Tabular figures stop HP digits from jittering |
| Small / tooltip | Alegreya Regular | 24 (min 22) | 1.25 | Never below 22 px |
| Damage numbers | Cinzel Black + 6 px outline | 48 / 64 | — | |

**Acceptance:** dialogue and descriptions are readable without leaning in at 1280×720 windowed. Numbers stay aligned while HP changes. No letter collisions in Cinzel names (check Cinzel's "W", "M", "Q" at 32 px).

## 3. Assessment of Press Start 2P

- **Pros:** genuine pixel font that matches the pixel UI grid (render at 16 or 24 px with antialiasing off).
- **Cons:** strongly associated with arcade and chiptune games, which the brief explicitly avoids. Its pixel grid differs from Gimble's art at 2× scale unless rendered at 16 px exactly. Poor readability for anything longer than a label. Adding a third typeface goes against the two-faces-per-screen rule.
- **Recommendation:** **do not adopt** for the vertical slice. If a pixel detail font is ever wanted (e.g. tiny labels on pixel badges), evaluate it alone in the specimen scene first.

## 4. Godot integration plan (implemented in Phase 1)

```
assets/fonts/
  cinzel/   Cinzel-VariableFont_wght.ttf (or static weights) + OFL.txt
  alegreya/ Alegreya-Regular.ttf, -Medium, -Bold, -Italic (or variable) + OFL.txt
scenes/ui/theme/
  fonts/
	font_title.tres      FontVariation  (Cinzel, weight 700)
	font_heading.tres    FontVariation  (Cinzel, weight 600)
	font_name.tres       FontVariation  (Cinzel, weight 400)
	font_body.tres       FontVariation  (Alegreya Regular)
	font_body_italic.tres
	font_numeric.tres    FontVariation  (Alegreya Medium, opentype_features {lnum:1, tnum:1})
  main_theme.tres        default_font = font_body, default_font_size = 30
						 type variations: TitleLabel, HeaderLabel, NameLabel, BodyLabel,
						 LoreLabel, SmallLabel, NumericLabel, DamageNumber
```
- **Import:** antialiasing *Grayscale*, hinting *Light*, subpixel positioning *Auto*, mipmaps off. Cinzel title uses *MSDF* (`multichannel_signed_distance_field = true`).
- **Fallback:** while the files are absent, the Theme falls back to Godot's default font, so nothing breaks.
- **Project setting:** `gui/theme/custom = res://scenes/ui/theme/main_theme.tres`, so every Control inherits the theme.
- `RichTextLabel` gets `normal_font`, `italics_font`, `bold_font` and `mono_font` (numeric) from the Theme, which enables inline emphasis in dialogue (`[i]…[/i]`).

## 5. Licence records (fill in when files are added)

| Name | Creator | Source URL | Licence | Commercial | Attribution | Format | Intended usage | Files in project | Date added |
|---|---|---|---|---|---|---|---|---|---|
| Alegreya | Juan Pablo del Peral / Huerta Tipográfica | https://fonts.google.com/specimen/Alegreya | OFL 1.1 | Yes | Ship OFL.txt | TTF | Body, dialogue, numbers | — | — |
| Cinzel | Natanael Gama | https://fonts.google.com/specimen/Cinzel | OFL 1.1 | Yes | Ship OFL.txt | TTF | Titles, headings, names | — | — |
