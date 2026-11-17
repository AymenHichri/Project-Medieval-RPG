Free Projectile Effects - Arrow & Fire  -  version 1.0.2

2 free HD projectile effects for top-down games: release, impact and expiry, plus in-flight sprites in 8 directions.

- arrow: expiry (4 frames), impact (7 frames), release (7 frames), flight_1 (6 frames, 8 directions), flight_2 (6 frames, 8 directions), flight_3 (6 frames, 8 directions)
- fire: expiry (4 frames), impact (7 frames), release (7 frames), flight (6 frames, 8 directions)

Each effect folder has horizontal PNG strips, single frames, a JSON with frame size, frame count, FPS and pivot, and a Godot 4 SpriteFrames file (godot/). In-flight sprites have 8 rows: S, SE, E, NE, N, NW, W, SW.

SMOOTH CLIPS
  Every idle, walk, run, attack and hurt animation (and every effect) also comes as <animation>_smooth: the same animation with twice the frames, played at twice the fps (same frame size, feet pivot and row order). Sheets, single frames, 128 px copies, colour variations and recolour masks included; Godot 4 SpriteFrames in godot/<name>_smooth_spriteframes.tres (animations <animation>_smooth_<direction>); the JSON lists them. Effects: <clip>_smooth sheets next to the originals, listed in each effect JSON.

MORE IN THIS STYLE
  Projectile & Impact Effects: https://sovdigital.itch.io/projectile-impact-effects
  Effects Complete Edition: https://sovdigital.itch.io/effects-complete-edition
  Complete Edition (every pack, boss and effect in one download): https://sovdigital.itch.io/complete-edition
  Everything by Sova Digital: https://sovdigital.itch.io/
