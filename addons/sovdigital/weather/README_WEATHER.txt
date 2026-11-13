Weather and wind shaders  -  from Free Godot 4 Sprite Shaders 1.2.0 by SovDigital (MIT-0)

Four Godot 4 canvas_item shaders that bring this tileset to life, plus one helper node:
  shaders/wind_sway.gdshader    trees, bushes, grass and reeds sway in the wind; the base stays planted
  shaders/cloth_wave.gdshader   banners, flags and cloth wave; only the cloth moves
  shaders/wet_surface.gdshader  rain: darker, richer colours, a wet sheen and puddle patches on the ground
  shaders/snow_cover.gdshader   snow settles on roofs, tree tops and the ground, then thaws
  scripts/world_weather.gd      WorldWeather: one node that runs wind, rain and snow for a whole level
  scripts/sprite_shader_region.gd  keeps the shaders right on sprite sheets (AtlasTexture frames)

QUICK START
  1. Add a Node to your level, name it WorldWeather and attach scripts/world_weather.gd to it (Inspector >
     Script > Load). The scripts have no global class name, so several of our downloads (tilesets, props,
     free packs, Free Godot 4 Sprite Shaders) can share one Godot project.
  2. Put trees, bushes and grass in the group "wind_sway" (Node > Groups). Give each a meta "wind_preset":
     tree, bush, grass or reeds (Inspector > Add Metadata). Banners go in "cloth_wave"; give them a meta
     "cloth_rect" (Vector4: the cloth's box inside the sprite, 0..1). Buildings, props and the ground go in
     "weather"; give ground layers the meta "ground" = true.
  3. From your game:  $WorldWeather.start_rain(3.0)   $WorldWeather.stop_rain(8.0)
                      $WorldWeather.start_snow(10.0)  $WorldWeather.thaw(10.0)
                      $WorldWeather.wind_strength = 2.0
  Or set a material by hand: Inspector > CanvasItem > Material > New ShaderMaterial > drag a .gdshader in, then
  tween its parameter (wetness for rain, amount for snow) from code.

TIPS
  - Wind and cloth bend from the bottom / attached edge of the texture, so use them on single pieces
    (Sprite2D or one piece per atlas texture). Wet and snow work on any tiles: put the material on the TileMapLayer.
  - Mirror plants with scale.x = -1 rather than flip_h.
  - The rain pieces in this tileset (puddles, wet ground, drips, rain splash) add standing water on top.
  - More settings and every parameter: the full Free Godot 4 Sprite Shaders download (free) on our itch.io page.

License: these shaders and scripts are MIT No Attribution (MIT-0): use, change and ship them in anything,
no credit needed. The tileset art keeps the tileset's own licence.
