Free Weather Effects  -  version 1.1.0

Free HD weather for top-down games: seamless rain, snow, fog and cloud-shadow overlays, plus lightning strikes, a lightning ground hit, a rain splash and a wind gust, as PNG, single frames and Godot 4 resources.

- lightning strike: a bolt draws down from the sky, flashes and fades (6 frames, 320 x 672 px)
- lightning strike forked: a forked bolt with branches, flashes and fades (6 frames, 320 x 672 px)
- lightning ground hit: where the bolt lands: a flash, sparks thrown out and a rising scorch plume (6 frames, 256 x 256 px)
- rain splash: a raindrop crown and ring on the ground (6 frames, 192 x 192 px)
- wind gust: wind lines sweeping left to right (6 frames, 384 x 192 px)

Seamless overlays (1024 x 1024 px tiles):
- rain near: big, fast rain streaks (front layer)
- rain far: fine, dense rain (back layer)
- snow near: big soft snowflakes (front layer)
- snow far: fine falling snow (back layer)
- fog: thin drifting fog banks
- cloud shadow: cloud shadows passing over the ground

Each effect folder has a horizontal PNG strip, single frames, a JSON with frame size, frame count, FPS, loop and pivot, and a Godot 4 SpriteFrames file (godot/).
Each overlay folder has the colour tile (use it with texture repeat), a greyscale mask for any tint, a JSON with the scroll speed, and a Godot 4 ShaderMaterial: put it on a ColorRect that covers the view and set "tiles" to the rect size divided by 1024. Stack a near and a far layer at different speeds for depth.

The bolts start at the top edge of their frame (they come down from the sky); place the pivot where the bolt meets the ground and play lightning ground hit on the same point.

ADDED IN 1.0.4
Two water effects from Water & Splash Effects: a small splash crown and a wading step. Each comes with colour variations green (swamp water), crimson (blood) and black (oil) in ColourVariations/<colour>/<effect>/.
- splash crown small (from Water & Splash Effects): effect (6 frames)
  colour variations of splash crown small (from Water & Splash Effects): green, crimson, black
- wade step (from Water & Splash Effects): effect (6 frames)
  colour variations of wade step (from Water & Splash Effects): green, crimson, black

GODOT SPAWN HELPER
godot/fx_spawn/ holds Fx, a small autoload that spawns any effect in one line (Fx.spawn("frost", "impact", position)) and frees one-shots by itself; fx_gallery.tscn shows every effect in the project. See godot/fx_spawn/README_GODOT.txt (scripts MIT-0).

ADDED IN 1.1.0
Wind gust in 8 headings: the wind gust effect has a second clip, gust_dirs, with one row per heading (S, SE, E, NE, N, NW, W, SW), 8 frames each, a loop, and its own Godot 4 SpriteFrames file (godot/wind_gust_gust_dirs_spriteframes.tres; animations gust_dirs_<heading>). The original gust clip is unchanged.
Rain and snow tiles for any angle: weather_tiles/ has one seamless rain tile and one seamless snow tile (1024 px), a Godot 4 shader (godot/weather_scroll.gdshader) that scrolls a tile at any angle and speed from a direction and speed setting, ready-made materials, and TILED_NOTE.txt for Tiled maps.

Anything added to this pack later is free if you already own it.
