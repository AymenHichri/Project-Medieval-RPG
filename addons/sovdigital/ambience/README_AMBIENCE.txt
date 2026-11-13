Time of day and weather moods  -  ambience controller by SovDigital (MIT-0)

One node that sets the time of day for a whole level: day, golden hour, dusk, night, storm, fog and blood moon.
It blends the CanvasModulate colour, the screen grade (exposure, contrast, saturation, tints, vignette) and every
lamp, torch and fire light at once, makes the flames flicker, and can run a full day cycle. It also sets the global
shader parameter tod_night (0 day .. 1 night) for shaders that read it.

  scripts/ambience_controller.gd   the controller (one Node per level)
  scripts/light_fx.gd              optional, on a PointLight2D: torch, candle, lamp, street lamp, neon, broken,
                                   alarm strobe, beacon, searchlight, headlights, hologram, pulse
  shaders/screen_grade.gdshader    the screen grade it makes when a scene has none
  textures/lights/                 light textures for PointLight2D: radial, narrow and wide cone, headlights, strip

TRY IT
  Every example scene in example/scenes/ has an "Ambience" node. Run a scene (F6) and press:
    1 day   2 golden hour   3 dusk   4 night   5 storm   6 fog   7 blood moon   C day cycle on / off
  The scene starts with its own colours (keep_scene_look); the keys blend to the other moods.

IN YOUR LEVEL
  1. Add a Node to the level's root and attach scripts/ambience_controller.gd. Set `preset` in the Inspector.
  2. It finds the level's CanvasModulate, a screen grade ColorRect and a child node named "Lights" by itself
     (or set canvas_modulate, grade_rect and lights_root). With no CanvasModulate or grade it makes its own.
     Every PointLight2D under "Lights" (or in the group "ambience_lamps") is a lamp: give it its night strength
     (energy); the controller dims it by day and makes it flicker (flicker 0 = steady).
  3. From your game:
       $Ambience.set_preset("dusk", 6.0)      # blend to dusk over 6 seconds
       $Ambience.start_day_cycle(6.0)         # run the clock from 06:00; cycle_minutes sets the length of a day
       $Ambience.time_of_day = 19.5           # jump the clock
  keep_scene_look = true: the colours the scene already has become its look for `preset`.

The scripts have no global class name, so several of our downloads can share one Godot project.
Fog, cloud shadows, sunbeams and moonlight, smoke plumes, modern and sci-fi lights and holograms for the same
controller come with Weather Effects and Ambient Effects on our itch.io page.
Made and tested with Godot 4.6. Licence: MIT No Attribution (MIT-0): use, change and ship them in anything, no
credit needed. The tileset art keeps the tileset's own licence.
