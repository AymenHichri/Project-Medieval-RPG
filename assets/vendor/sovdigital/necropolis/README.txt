Free Necropolis – Top-Down Tileset & Props (HD) (version 1.1.0)
================================================================

Top-down environment art. Camera: three-quarter top-down (about 30 degrees), square grid.
Grid: 128 px tiles at full size; _sizes/64 is an exact 50 % copy with its own Godot and Tiled files.
Scale: a humanoid character is about 158 px tall at full size (1.23 tiles); our full character sheets at 50 % match _sizes/64.

What's inside
- grounds/              2 seamless 1024 px ground blocks; each block is also its own 8x8 tile atlas.
                        <ground>_single_tiles.png = single tiles sharing one border (any of them sits next to any other).
- terrain/<pair>/       1 sets of 16-tile corner autotiles: *_corners16.png (opaque) and
                        *_overlay16.png (transparent edges over a ground block). Corner code = NW*8 + NE*4 + SW*2 + SE.
- decals/               2 ground decals and ground patches (transparent PNG).
- walls/                3 wall modules. Straight runs marked repeat_x / repeat_y in biome.json join seamlessly
                        end to end; corners, gates, towers and stairs are whole pieces that meet the runs at their ends.
- buildings/, landmarks/   11 large pieces, each on its own ground patch.
- props/scatter/, props/setpieces/   12 props (small ground clutter and larger set pieces).
- destructibles/<name>/ 2 breakable props: intact, cracked and broken as single PNGs + a strip,
                        <name>_states.json (footprint and collision per state: broken rubble is walkable),
                        godot/<name>_spriteframes.tres (animations intact / cracked / broken / states) and
                        godot/<name>.tscn (AnimatedSprite2D + footprint collision, no script).
- animated/<name>/      2 animated props as frames/ + a strip; godot/<name>_spriteframes.tres holds every
                        animation (see biome.json "anims"); godot/<name>.tscn plays the default one.
- atlases/              atlases with a 4 px extruded border around every cell (margin 4, separation 8).
- godot/necropolis-free_tileset.tres   Godot 4.6 TileSet (all paths relative: copy the whole folder anywhere in your project).
- tiled/                Tiled 1.12 tilesets (corner Wang sets, objects with collision) and a sample map in tiled/examples/.
- maps/                 the sample map rendered as one image.
- example/scenes/       ready-built example scenes (by day, at night and, where it fits, in the rain and the snow) made only
                        from this pack: copy the whole pack folder into your project, open example/scenes/*.tscn and press F6.
                        How they are built: example/README_EXAMPLE_SCENES.txt. Delete the folder if not needed.
- ColourVariations/<colour>/   the complete tree again per colour variation (same file names): Frost, Crimson, Moss, Ash. Fire and glow keep their colour.
- biome.json            every file, size, pivot, footprint, collision, surface and state, for any engine.

Godot 4.6
- Use godot/necropolis-free_tileset.tres on TileMapLayers. Suggested layers: 1 ground (paint a ground block with its saved pattern),
  2 terrain (terrain brush; set 0 = opaque corners, set 1 = transparent overlay), 3 decals, 4 World: one TileMapLayer with
  y_sort_enabled plus your characters as Y-sorted siblings under a Y-sorted parent, all on the same z_index, 5 weather/fog.
- Atlas pieces stand with their base on the bottom edge of the cell you paint; Y-sort origin = the base.
  Breakables and animated props are scene tiles (they stand at the cell centre) and can also be dropped in as scenes.
- Custom data: surface (String), breakable (bool), hazard (String: slow, slide, burn, poison or empty). These are
  hints; your game decides what they do.
- Physics layer 0 "world_solid" (collision layer 1): wall and prop footprints. Physics layer 1 "water" (collision layer 2).
  Navigation layer 0 on walkable ground. Occlusion layer 0 on walls for 2D lights.
- Texture filter: linear with mipmaps. The atlases are padded, so use_texture_padding is off.

Tiled 1.12
- Add tiled/necropolis-free_terrain.tsx (or _overlay.tsx) and use the Terrain brush. Ground blocks: tiled/necropolis-free_ground_<name>.tsx.
- Pieces: tiled/necropolis-free_objects.tsx on an object layer (bottom-aligned, collision included).

Other engines: every piece is a plain PNG; biome.json lists sizes, pivots, footprints and states.

Weather and wind (godot/weather/, MIT-0)
- cloth_wave, snow_cover, wet_surface, wind_sway: Godot 4 shaders for rain (wet_surface), wind (wind_sway, cloth_wave) and snow (snow_cover), and WorldWeather (scripts/world_weather.gd), one node that runs them for a whole level. How to use: godot/weather/README_WEATHER.txt.

Licence: see LICENSE.txt.

Version 1.0.1: godot/weather/ 1.2.1: banners keep their pole straight while the cloth waves (cloth_wave.gdshader: new pole pin; WorldWeather reads a cloth_pole meta), and snow_cover lays ground snow in world space, so neighbouring ground tiles join up while the snow builds up.

Version 1.1.0: time of day for every example scene: godot/ambience/ has a controller with day, golden hour, dusk, night, storm, fog and blood moon (keys 1-7 and C for a day cycle in the scenes; how to use it: godot/ambience/README_AMBIENCE.txt); the weather scripts have no global class name any more, so this download and our other tilesets, props and free packs work together in one Godot project.
