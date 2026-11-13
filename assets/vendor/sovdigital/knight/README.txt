Knight - Free Sampler  -  version 2.2.9

1 top-down character(s), 8 directions each.

- Knight: attack, attack2, death, hurt, idle, run, walk (232x246 px frames); attack 6, attack2 6, death 6, hurt 6, idle 12, run 12, walk 12 frames per direction

Extra moves (8 directions each):
- Knight: whirlwind (whirlwind, 11 frames, 268x246 px), whirlwind_ring (whirlwind (wind ring), 11 frames, 268x266 px, with layers), dash_strike (dash strike, 12 frames, 536x346 px), combo (three-hit combo, 17 frames, 232x246 px), charged_strike (charged strike, 14 frames, 348x274 px, with layers), jump_slam (jump slam, 11 frames, 344x354 px, with layers)

MOVES
  characters/<name>/moves/<move>/            extra attack moves, each in all 8 directions
    <move>.png                               sheet: 8 rows (S, SE, E, NE, N, NW, W, SW), one column per frame
    frames/<DIRECTION>/<index>.png           every frame as its own PNG
    <move>.json                              frame size, feet pivot per direction, fps, hit frames, root motion
    godot/<move>_spriteframes.tres           Godot 4 SpriteFrames, animations named <move>_<direction>
    layers/<move>_fx_back|body|fx_front.png  (moves with effects) the same frames split into effects behind,
                                             the character, and effects in front; use body alone for no effects
  A move can use a bigger cell than the character's other animations (room for a dash, leap or glow).
  cell_offset in the JSON says where the normal cell sits inside it; with the per-direction pivot the feet
  line up with idle, so a move starts and ends without a jump. Moves come at full size only.

Weapon trail (steel look, 8 directions each):
- Knight: weapon trail and hit spark for attack and attack2

WEAPON TRAILS
  characters/knight/weapon_trails/knight_<attack>_<trail|spark>_steel/   one layer per folder
    effect.png                               sheet: 8 rows (S, SE, E, NE, N, NW, W, SW), one column per frame
    frames/effect_<DIRECTION>/<index>.png    every frame as its own PNG
    <folder name>.json                       frame size, fps, feet pivot, strike frames and contact frame per direction
    godot/<folder name>_spriteframes.tres    Godot 4 SpriteFrames, animations named effect_<direction>
  Each layer has the same cell, frames, fps and row order as the Knight's attack sheet it belongs to (sheets/attack.png
  or sheets/attack2.png). Play it in a second sprite on top of the Knight with the same direction and frame index (in
  Godot: a child AnimatedSprite2D that copies the parent's animation frame). The hit spark shows at the contact frame.
  Leave the layers off for a plain attack. Weapon trails come at full size only.
  Fire, frost, shadow and holy looks, and trails for more characters, are in Weapon Trails & Hit Sparks.

FOLDERS
  characters/<name>/sheets/      one PNG per animation; 8 rows = directions, columns = frames
  characters/<name>/frames/      every frame as its own PNG: <animation>/<DIRECTION>/<index>.png
  characters/<name>/_sizes/128/  the same sheets and frames at 128 px cell height
  characters/<name>/godot/       Godot 4 SpriteFrames (.tres), animations named <animation>_<direction>
  characters/<name>/<name>.json  frame size, feet pivot, frames, fps and looping per animation
  ColourVariations/              optional colour variations, recolour masks and a Godot shader
  previews/                       animated GIF previews

SMOOTH CLIPS
  Every idle, walk, run, attack and hurt animation (and every effect) also comes as <animation>_smooth: the same animation with twice the frames, played at twice the fps (same frame size, feet pivot and row order). Sheets, single frames, 128 px copies, colour variations and recolour masks included; Godot 4 SpriteFrames in godot/<name>_smooth_spriteframes.tres (animations <animation>_smooth_<direction>); the JSON lists them. Effects: <clip>_smooth sheets next to the originals, listed in each effect JSON.

COLOUR VARIATIONS (ColourVariations/, optional: delete the folder if you don't need it)
  ColourVariations/<variation>/<name>/  every animation of a character in another colour variation: the same
      sheets, frame size, feet pivot and Godot SpriteFrames as characters/<name>/ (sheets only; slice
      them like the main sheets). Previews: previews/<name>_colour_variations.png
  - Knight: Red (red/), Blue (blue/), Green (green/), Gold (gold/), Black (black/)
  ColourVariations/recolour_masks/<name>/<clip>.png  material masks in the same layout as the sheets
      (red = main material, green = second material) for your own colours at runtime.
  ColourVariations/godot/recolour_mask.gdshader + recolour_masks.gd  Godot 4: give the AnimatedSprite2D a
      ShaderMaterial with the shader, attach the script, set masks_dir, then pick colour_main / colour_second.

DIRECTIONS
  Sheet rows top to bottom: S, SE, E, NE, N, NW, W, SW

GODOT 4
  Copy a whole character folder into your project and assign godot/<name>_spriteframes.tres
  to an AnimatedSprite2D. Paths inside are relative, so the folder can live anywhere.

OTHER ENGINES (Unity, GameMaker, Construct, Defold, ...)
  Slice a sheet as a grid: columns = frames, 8 rows = directions. Frame size and pivot are in the JSON.

Speeds are in the JSON per animation (12-frame idle, walk and run play at double speed). Idle, walk and run loop.

License: see LICENSE.txt.

MORE IN THIS STYLE
  Armored Knights: https://sovdigital.itch.io/armored-knights
  Medieval Knights & Archers Set: https://sovdigital.itch.io/knights-and-soldiers-set
  Complete Edition (every pack, boss and effect in one download): https://sovdigital.itch.io/complete-edition
  Everything by Sova Digital: https://sovdigital.itch.io/
