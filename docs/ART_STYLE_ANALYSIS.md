# Art Style Analysis — THE FIRST HERESY

_Date: 2026-11-15 · Stage 1–2 of the artwork brief · Method: direct pixel inspection of the imported assets in `assets/vendor/` (the copies the game actually loads), measured with a small script and reviewed visually through contact sheets. No source asset was modified._

Visual reference sheets: [`docs/art_reference/`](art_reference/). They are internal working documents that contain crops of licensed assets, so they must not be published or redistributed.

---

## 0. Summary (read this first)

**The project does not have one visual style. It has two, and they are technically opposite.**

| | **World layer: SovDigital** | **Interface layer: Gimble's (+ dfgui)** |
|---|---|---|
| Used for | Player, enemies, every map tile, building and prop | Battle backgrounds, portraits, UI, icons |
| Technique | **HD pre-rendered / painted sprites.** Not pixel art. | **True hard-edged pixel art** |
| Unique colours per image | 67,000–173,000 | 19–63 (from a fixed 80-colour palette) |
| Anti-aliased / semi-transparent pixels | Yes (12–32 % of visible pixels on props; sprite sheets fully soft-edged) | 0 % |
| Neighbouring pixels identical | 0.1–5 % (continuous gradients) | 60–94 % (flat clusters, upscaled ×2 / ×6) |
| Native resolution | Humanoid ≈ 158 px tall, 128 px tile grid | Backgrounds **320×180** shown ×6; portraits 64 px shown ×4 |
| Outlines | None, soft dark rim from the render | Dark selective outline, 1 native px |
| Camera | Top-down three-quarter view (~30°) | Eye-level side view (backgrounds); bust (portraits) |
| Share of in-game screen | **Most of every screen** (all exploration, all battlers) | UI chrome, plus the backdrop behind battles |

Reference counts in scenes and data: SovDigital `village` 24, `necropolis` 22, `knight` 5, `weather` 8 · Gimble's `ui` 11, `hud_icons` 4, `backgrounds` 1.

**Consequence for this brief.** The brief asks for *"HD pixel art"* that matches the actual assets. The assets used most often are **not pixel art**. The project's own decision D2 (`PROJECT_PLAN.md`) already states: *"HD painted 2D sprites … not hard-edged pixel art. Pixel art is allowed only for UI."* The only pixel art that could serve as an illustration reference is Gimble's (two battle backgrounds and six portraits).

So "match the existing assets" and "HD pixel art" point to **different reference sets**. That choice belongs to the user and has to be made before any artwork is produced (see §6).

---

## 1. Asset directories inspected

| Directory | Pack | Layer | Inspected |
|---|---|---|---|
| `assets/vendor/sovdigital/knight` | Knight (5 colourways) | World / battle | idle, attack · E, SE rows · default + black |
| `…/skeleton`, `…/wolf`, `…/goblin_scout` | Enemies | World / battle | idle W row, charred variant |
| `…/blade_assassin` | Boss, 2 phases | Battle | idle W row, both phases |
| `…/necropolis` | Necropolis tileset | World | buildings (default/ash/frost/ruined), 12 setpieces, walls, grounds |
| `…/village` | Village tileset | World | cottage (default/ash/ruined slate), grounds |
| `…/castle_courtyard` | Courtyard tileset | World | curtain wall, well, flagstones |
| `…/weather` | Fog/rain overlays | World FX | referenced, not illustrated |
| `assets/vendor/gimbles` | Dark Fantasy Kit Sampler | Interface | both backgrounds, 6 portraits, panels, buttons, icons, palettes |
| `assets/vendor/dfgui` | dfgui UI kit | Interface | party HUD, map icons, portrait frames |
| `assests/*.zip` | Original downloads | — | **Not touched.** Imported copies are identical subsets (see `ASSET_ANALYSIS.md`) |

There is no existing cover, key art or splash image in the project.

---

## 2. World layer: SovDigital (dominant)

Sheets: `01_world_characters_enemies.png`, `02_world_sprite_closeup.png`, `03_world_buildings.png`, `04_world_props_grounds.png`.

**Rendering.** The sprites are pre-rendered or painted with continuous soft gradients, specular highlights on metal, and baked ambient occlusion. Under 3.5× nearest zoom (sheet 02) there are no pixel clusters, no dithering and no hand-placed pixels. It reads as "HD 2D" (Diablo II, or a modern ARPG pre-render).

**Proportions.** The figures are stylised and stocky, about **3.5 heads tall**, with oversized hands, weapons and helmets for readability from the top-down camera. They are grounded and not anime. The wolf is naturalistic.

**Outline.** There is no drawn outline. Silhouettes separate by value: a dark rim against lit planes.

**Lighting.** Light is a single warm key from the upper left/front with cool, dark ambient. Tops of walls and stones catch the light, and fronts fall into shadow. Metal has strong white speculars. Every building sits on its own dirt "island" base.

**Texture density.** Texture is high and chunky. Stones are big rounded blocks with edge wear, moss flecks and cracks. Wood shows plank grain. Thatch is clumped. The tiled grounds are noisy photo-like textures. At the 128 px tile grid, a wall block is about 25–35 px.

**Architecture vocabulary.** Massive rectangular masonry, crenellations, round-arched doors with iron ring pulls, skull keystones, carved relief niches (sleeping beasts), obelisks with banded metal, a gargoyle on a gothic-arched plinth, iron spear fences, lantern gibbets, half-timbered cottages and ruined states.
**Missing:** pointed gothic arches at scale, spires, rose windows, a cathedral or church. These would have to be extrapolated from the crypt, gargoyle plinth and obelisk.

**Palette (measured, ash/default variants).** The world is near-neutral greys with a faint olive or brown bias:
`#080808 #191919 #2a2a2a #3b3b3b #4c4c4c #5d5d5d` (stone values) · `#3b3b2a #4c4c3b` (moss-grey) · `#3b2a2a #5d4c4c` (warm stone) · `#3b2a19 #4c3b2a #6e4c2a` (leather/wood) · `#c3904c` (straw/gold highlight).
Saturation is low throughout. Red appears only on the Blade Assassin (blood-red blades and cloth glow).

**Animation.** Pre-rendered frame sequences run at 12 fps, 6–17 frames, in 8 directions. Motion is weighty and readable.

**Enemies.** The skeleton (gold bone, rusted blade), wolf, goblin and Blade Assassin (black, with crimson glow) are "classic fantasy" creatures. **None show body horror or cosmic horror.** The darkest silhouette language in the pack is the Assassin's tattered cloak with red glow. Any original creature (battle enemy, dead god) has to be extrapolated from this rendering rather than copied.

---

## 3. Interface layer: Gimble's + dfgui (pixel art)

Sheets: `05_pixel_battle_backgrounds.png`, `06_pixel_portraits_ui.png`.

**Battle backgrounds** (`08_graveyard`, `04_haunted_forest`):
- Native **320×180**, shown at ×6 (1920×1080). Each image has 60–70 colours.
- Eye-level side view with a large flat floor band for battlers (bottom ~45 %) and the scenery in the top half.
- Shading uses clustered flat colour with light, irregular noise. It is not ordered dithering. Shapes have soft clusters, stones have rim highlights, and trees are dark silhouettes.
- Depth comes from value layers: near is dark, mid is lit, far is a desaturated silhouette. The forest is almost monochrome cold green-grey.
- Lighting comes from the moon or ambient, cool and blue-teal, with rare warm ember specks.

**Portraits** (knight, witch hunter, witch, vampire lord, skeleton warrior, werewolf):
- Native 64 px, shown at 256. Each has 19–38 colours.
- They are realistic and gritty, older and weathered faces, **not anime**. A single light comes from the upper left. Faces sit on a dark plum-black background `#232023`.

**UI**: rusted iron 9-slice panels, crimson buttons, gold-trimmed bars, and a runic gold ring frame (dfgui). The icons are small, crisp and lightly outlined.

**Palette**: Gimble's ships an 80-colour palette (`dark_fantasy_kit_icons_80.hex`), already tokenised in `ART_GUIDELINES.md` §3. The key tones are:
- abyss `#120F14`
- slate `#191A23`
- iron `#393333` and `#4B4B51`
- blood `#8C2821`, bright `#BB322C`, dark `#5D201D`
- gold `#DCAE4F`, muted `#A47B4F`
- bone and parchment `#D5C8B3` and `#ECE8DF`
- curse purple `#5C3266`

**Disclosure.** The Gimble's README says its art is AI-assisted and cleaned up afterwards.

---

## 4. Which assets belong together

| Group | Members | Coherent? |
|---|---|---|
| A. SovDigital world | knight, skeleton, wolf, goblin, assassin, necropolis, village, courtyard, weather | **Yes.** One renderer, one camera, one scale (128 px grid). Necropolis `ash`/`frost` and village/courtyard `ash`/`slate` are the darkest. |
| B. Gimble's pixel | backgrounds, portraits, panels, buttons, icons | **Yes.** One palette, one technique |
| C. dfgui pixel | bars, icons, frames, map icons | Mostly compatible with B (same dark slate/gold). Map icons are brighter and cuter, so they are the weakest match. |

**A vs B/C in one frame** (sheet `07_battle_style_clash.png`, an approximation of the current battle scene at `battle_scale 1.2`): painted battlers stand on a ×6 chunky-pixel floor. The pixel size differs by about 6× and the edge treatment differs completely. The project plan already lists this as risk **R3**.

## 5. Assets that should NOT be visual references

- **Village default (bright) palette.** Thatch, daisies and green grass read as cosy and would contradict the oppressive tone. Use the `ash`/`slate` variants only.
- **dfgui map icons and the dfgui party-HUD fills.** Saturated, glossy and toy-like.
- **Goblin Scout.** A generic fantasy creature with a comedic read. It is fine in the game but carries no tone.
- **Knight `gold` colourway.** Too heroic and paladin-like for a "necessity, not friendship" party.
- **The `Haunted Forest` moon composition.** Use its value structure, but avoid its "big full moon" cliché for key art. The brief wants an eclipse or an unnatural phenomenon.

---

## 6. The decision needed before Stage 4

> **DECIDED (2026-11-15): Option B, painted HD in the SovDigital style.** Images are produced with an external image generator using the kit in `IMAGE_GENERATION_PROMPTS.md` and `docs/art_reference/generator/`. The Option A rules below are kept for the record only.

### Option A: Pixel-art illustrations in the Gimble's language (recommended for key art)
- The reference set is Gimble's backgrounds and portraits. They supply palette, pixel density (320×180 per 16:9 frame), shading and outline rules. SovDigital supplies only **content**: architecture vocabulary, armour designs, proportions, monster rendering ideas.
- This matches the brief's wording ("HD pixel art", "intentional pixel-art rendering") and matches the battle backgrounds, which are the closest thing the project has to an illustration.
- Trade-off: the art will not look like the exploration screens, which are painted.

### Option B: Painted HD illustrations in the SovDigital language
- The reference set is SovDigital: soft rendered stone, warm key light, chunky masonry, stocky figures.
- This matches what players see most of the time. It contradicts the brief's "pixel art" wording and contradicts the battle backgrounds and portraits.

### Option C: Unify the game first
- Replace either the battle backgrounds and portraits (with painted ones) or the world art (with pixel art), so the game has one style. Then make the key art match that style.
- This is the cleanest long-term answer, but it is a production decision that goes well beyond the artwork task.

**Recommended direction for the five illustrations under Option A** (also used in `ARTWORK_CONCEPTS.md`):

| Rule | Value |
|---|---|
| Native canvas | 16:9 → **320×180**; cover 2:3 → **240×360**. Export ×6 nearest (1920×1080 / 1440×2160) |
| Palette | Gimble's 80-colour `.hex` only. No colours outside it |
| Outlines | 1 native px dark selective outline on foreground figures; none on background silhouettes |
| Shading | 3–5 value steps per material, flat clusters, sparse noise; no gradients, no ordered dithering except in fog/sky bands |
| Light | Cool ambient (`#191A23`→`#4C5670`), one warm or eerie key. Crimson `#8C2821` and gold `#DCAE4F` are each kept to under 5 % of the frame |
| Figures | Proportions from SovDigital: stocky, about 3.5 heads. Humans are 28–40 px tall in battle and party scenes and 10–14 px in landscapes |
| Architecture | SovDigital masonry vocabulary (big rounded blocks, crenellations, skull keystones, relief niches, gargoyle, obelisk), extended into gothic forms |
| Forbidden | Painterly gradients, photoreal light, anime faces, a pixelation filter applied over a painting, any non-integer scaling |

---

## 7. Tooling limitation (must be disclosed)

This session has **no image-generation model**. I can only produce images by writing code that places pixels, or by compositing the existing asset files.

- **Option B (painted HD)** cannot be produced convincingly this way. I would not attempt it.
- **Option A (pixel art)** can be produced by hand-authoring pixels in code at 320×180. Expect results below the Gimble's backgrounds: geometric architecture is feasible, but organic forms (the entity, faces, body horror) will look procedural or simplified.
- **Exploration** and **battle** compositions could alternatively be **kit-bashed from the real assets**: SovDigital tiles and battlers on a Gimble's background, graded with fog. That is truthful to the game but limited to the creatures and buildings that exist. Licence note: such composites are promotional use of the game's own content, but SovDigital forbids redistributing the assets themselves, so do not publish raw sprites.

Following the brief's own instruction, no artwork has been generated until the direction and the production method are confirmed.

---

## Appendix: reproducing the sheets

The scripts are in `docs/art_reference/tools/` and need Node with `sharp`.

- `measure.js` prints colour count, alpha and neighbour statistics.
- `sheet.js` builds a labelled contact sheet.
- `palette.js` extracts dominant colours.
- `battlemock.js` builds the battle-composition mock.
