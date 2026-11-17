Free Spell Effects - Energy Burst & Shadow Orb  -  version 1.0.4

2 free HD spell effects for top-down games: an energy burst and a shadow orb, as PNG strips, single frames and Godot 4 SpriteFrames.

- energy burst: effect (6 frames)
- shadow orb: effect (6 frames)

Each effect folder has horizontal PNG strips, single frames, a JSON with frame size, frame count, FPS and pivot, and a Godot 4 SpriteFrames file (godot/).

SMOOTH CLIPS
  Every idle, walk, run, attack and hurt animation (and every effect) also comes as <animation>_smooth: the same animation with twice the frames, played at twice the fps (same frame size, feet pivot and row order). Sheets, single frames, 128 px copies, colour variations and recolour masks included; Godot 4 SpriteFrames in godot/<name>_smooth_spriteframes.tres (animations <animation>_smooth_<direction>); the JSON lists them. Effects: <clip>_smooth sheets next to the originals, listed in each effect JSON.

ADDED IN 1.0.4
A frost spell cast and impact from the Elemental Spell Kits, with colour variations (ColourVariations/<colour>/frost/). These added effects come without _smooth copies: their frames are the full animation.
- frost (from Elemental Spell Kits): cast (6 frames), impact (8 frames)
  colour variations of frost (from Elemental Spell Kits): cyan, violet, silver

GODOT SPAWN HELPER
godot/fx_spawn/ holds Fx, a small autoload that spawns any effect in one line (Fx.spawn("frost", "impact", position)) and frees one-shots by itself; fx_gallery.tscn shows every effect in the project. See godot/fx_spawn/README_GODOT.txt (scripts MIT-0).

MORE IN THIS STYLE
  Boss Spell Effects: https://sovdigital.itch.io/boss-spell-effects
  Effects Complete Edition: https://sovdigital.itch.io/effects-complete-edition
  Complete Edition (every pack, boss and effect in one download): https://sovdigital.itch.io/complete-edition
  Everything by Sova Digital: https://sovdigital.itch.io/

Anything added to this pack later is free if you already own it.
