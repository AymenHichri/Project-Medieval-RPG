# Artwork Concepts — THE FIRST HERESY

_Stage 3 of the artwork brief · 2026-11-15 · Depends on `ART_STYLE_ANALYSIS.md`._

> **Direction decided: Option B, painted HD in the SovDigital style.** The compositions below still apply. Ignore the pixel-specific numbers (native canvas sizes, px heights, the 80-colour palette check). Rendering rules, final sizes (cover 1440×2160, others 1920×1080) and generator prompts are in `IMAGE_GENERATION_PROMPTS.md`, which supersedes this file wherever the two differ.

Output folder (once approved): `artwork/concept/`. Each piece is delivered as the native-resolution PNG plus a ×6 nearest export. No production asset is touched.

Shared rules for all five pieces: palette, outline, shading and figure scale follow `ART_STYLE_ANALYSIS.md` §6. Every piece uses the same three-value-band structure as the Gimble's backgrounds: a dark foreground frame, a lit midground subject, and a desaturated far silhouette. Crimson and gold stay rare.

---

## 1. Cover: `the_first_heresy_cover.png` (240×360 → 1440×2160)

- **Cathedral (centre, lower 2/3).** Build it from the SovDigital crypt vocabulary scaled up: massive rounded ash-grey blocks (`#2a2a2a`–`#5d5d5d`), crenellated parapets, a skull keystone over a round-arched door. Add gothic extensions in the same stone: two asymmetric towers (one with a broken spire), a dark rose window, and a row of relief niches with headless saints in place of the crypt's sleeping beasts. A gargoyle plinth stands on each buttress.
- **Entity (upper 1/2, behind).** Not a creature with a face. It is a vast vertical shape in the clouds, a dark mass slightly darker than the night sky (`#120F14` on `#191A23`), revealed only by its edges:
  - a ring of many pale, half-closed lids around the eclipse;
  - long hanging forms that could be fingers, roots or a ribcage descending into the fog behind the towers.
  - The eclipse is its pupil: a black disc with a thin `#DCAE4F` corona, slightly off-centre and looking down at the cathedral.
- **Fog band** behind the cathedral base, made of 2–3 flat bands of `#393333`/`#4b4b51` with a sparse noise edge. It separates the building from the entity.
- **Scale cue.** One 10 px figure on the approach road holds a lantern, the only warm light (`#E56425` → `#DCAE4F`, 2–3 px). The rose window glows faint crimson `#5D201D`, as if lit from inside.
- **Foreground frame**: an iron spear fence and headstone silhouettes in near-black.
- **Title (separate file)**: `the_first_heresy_logo.png` on a transparent background. "THE FIRST HERESY" is set in pixel-built capitals derived from Cinzel (the project's title font), in bone `#D5C8B3` with a 1 px `#120F14` outline. A thin `#8C2821` rule is broken in the middle by a small eclipse sigil. A 2× vector-font variant can follow later for store pages.

## 2. Party: `the_first_heresy_party.png` (320×180)

- **Setting.** Night camp inside a ruined crypt (the SovDigital ruined-barracks vocabulary). A single small bone-pyre fire is the only warm light. Five figures, each 34–40 px tall, sit or stand **apart from each other**, angled away rather than facing the viewer.
- **The five archetypes**, all in SovDigital costume language (plate, leather, tabards, hoods):
  - **Cautious:** half-standing at the edge of the light, looking out into the dark, hand on a sheathed blade.
  - **Hardened:** seated, cleaning a notched sword; dented knight plate in the `black` colourway look, eyes on the others.
  - **Untrustworthy:** in shadow beyond the fire with only the face lit from below; hooded, holding something wrapped in cloth.
  - **Exhausted:** slumped against a pillar, helmet off, eyes closed but gripping a mace.
  - **Unnatural:** sitting closest to the fire but casting a wrong shadow; one bandaged arm with a faint `#5C3266` tint seeping through.
- **Composition.** The fire is left of centre, and the figures spread along the floor band like the battle layout, so the piece also previews the game's scale. Empty space between the characters carries the distrust.

## 3. Battle: `the_first_heresy_battle.png` (320×180)

- **Backdrop.** An underground sanctuary in the Gimble's layer structure: the top half holds a nave of SovDigital-style pillars receding into darkness, collapsed pews and a headless altar statue. The bottom 45 % is a flat flagstone floor band (bone-flags texture language).
- **Party (left).** Three or four figures in E-facing profile, at the 3/4 battle angle the game uses, about 36 px tall and on the same baseline. There is no UI of any kind.
- **Enemy (right), "the Congregant".** About 90 px tall: several human bodies fused into one upright mass, wearing a single shared priest's cassock. Arms emerge at the wrong heights and hold censers. The one head is too high and has no face, only a smooth pale surface with a vertical seam. Its rendering follows the Blade Assassin: dark cloth, a ragged silhouette edge, and one crimson accent (the censers' glow `#BB322C`).
- **Light.** Cold shafts fall from a broken ceiling onto the empty middle ground, so the space between the party and the enemy is the brightest area.

## 4. Exploration: `the_first_heresy_exploration.png` (320×180)

- **Viewpoint.** This piece breaks from the side view to match the world layer: the **top-down 3/4 camera** of the SovDigital tiles. It shows a full screen of a "level" built from the existing pieces:
  - `ash` cottages, intact and ruined;
  - a mud street with flagstone patches;
  - an iron fence, headstones, a gnarled tree, a lantern post;
  - an obelisk;
  - a large abandoned chapel at the top, extended from the crypt-barracks vocabulary.
- **Disturbing details**:
  - a handcart abandoned mid-street with its contents spilled;
  - every door marked with the same chalk eclipse sigil;
  - the statues in the square have all been turned to face the chapel;
  - a trail of drag marks leads inside.
- **Adventurer.** About 14 px tall, carrying a lantern; it is the only warm light. Fog overlay bands sit at the screen edges.
- **Alternative (higher fidelity).** Compose this piece directly from the real SovDigital tiles in Godot, using the `ash` palette, the dusk/fog grade and a screenshot. That would show genuine in-game assets rather than an interpretation.

## 5. The Dead Gods: `the_first_heresy_dead_gods.png` (320×180)

- **Space.** A cavern so large that its far wall is a flat silhouette band. A carved stair descends from the lower left, with a tiny explorer (8 px) on it for scale.
- **Remains.** The divine body fills the right two thirds and is fused into the architecture:
  - an immense ribcage, each rib a gothic flying buttress (the same masonry blocks as the cathedral);
  - between the ribs, sagging organic membranes in `#5D201D`/`#643E2E`;
  - a "face" made of a cathedral facade, its rose window a dead eye;
  - stalactites that are also fingers;
  - small shrines and candles left by later worshippers, now cold.
- **Ambiguity.** One rib-buttress shows a recent crack with a faint `#DCAE4F` seep, as if it still bleeds light, which is the hint that it is not fully dead.
- **Palette.** This is the coldest piece: stone `#2a2a2a`–`#7d7f83`, bone `#bcbaaf`, with crimson and gold only in the wound.

---

## Consistency checks before each delivery

- [ ] Uses only the Gimble's 80-colour palette (verified by script).
- [ ] Exact native resolution; the export is an integer ×6 nearest upscale.
- [ ] No anti-aliased or semi-transparent pixels (`measure.js`: semiAlpha 0 %).
- [ ] Figure heights match the table in `ART_STYLE_ANALYSIS.md` §6.
- [ ] Shown side by side with `05_pixel_battle_backgrounds.png` and the approved cover. If it looks like a different game, it is rejected.
