Free Ambient Effects  -  version 1.0.0

Free HD ambient effects for top-down games: looping smoke, steam and toxic gas, embers and sparks, a dust devil, and seamless ember and light-shaft overlays, as PNG, single frames and Godot 4 resources.

- smoke column: a rising column of smoke (seamless loop) (8 frames, 256 x 384 px)
- steam vent: steam rising from a vent (seamless loop) (8 frames, 256 x 320 px)
- toxic gas: a low cloud of toxic gas rolling in place (seamless loop) (8 frames, 320 x 256 px)
- ember swirl: embers spiralling up from a fire (seamless loop) (8 frames, 256 x 280 px)
- ember burst: embers and ash thrown up from a log or brazier (6 frames, 256 x 256 px)
- sparks burst: a spray of sparks from one point, falling with gravity (6 frames, 256 x 256 px)
- dust swirl: a small dust devil turning on the spot (seamless loop) (8 frames, 256 x 280 px)

Seamless overlays (1024 x 1024 px tiles):
- embers: embers drifting up over a burning area (additive)
- light shafts: warm light shafts falling through a canopy or window (additive)

Each effect folder has a horizontal PNG strip, single frames, a JSON with frame size, frame count, FPS, loop and pivot, and a Godot 4 SpriteFrames file (godot/).
Each overlay folder has the colour tile (use it with texture repeat), a greyscale mask for any tint, a JSON with the scroll speed, and a Godot 4 ShaderMaterial: put it on a ColorRect that covers the view and set "tiles" to the rect size divided by 1024. Stack a near and a far layer at different speeds for depth.

Ember swirl, ember burst, sparks burst and the ember and light-shaft overlays are glows: they look best drawn additively (Godot: CanvasItemMaterial blend mode Add), and they also work with normal blending.

