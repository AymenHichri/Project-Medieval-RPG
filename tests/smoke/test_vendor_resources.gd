extends TestCase
## Vendor SpriteFrames and TileSets load from their copied location (relative paths preserved).

const SOV: String = "res://assets/vendor/sovdigital"
const SPRITE_FRAMES: Array[String] = [
	SOV + "/knight/characters/knight/godot/knight_spriteframes.tres",
	SOV + "/knight/ColourVariations/black/knight/godot/knight_spriteframes.tres",
	SOV + "/knight/ColourVariations/gold/knight/godot/knight_spriteframes.tres",
	SOV + "/wolf/characters/wolf/godot/wolf_spriteframes.tres",
	SOV + "/goblin_scout/characters/goblin-scout/godot/goblin-scout_spriteframes.tres",
	SOV + "/skeleton/characters/skeleton/godot/skeleton_spriteframes.tres",
	SOV + "/blade_assassin/characters/blade-assassin/godot/blade-assassin_spriteframes.tres",
	SOV + "/blade_assassin/characters/blade-assassin-phase-two/godot/blade-assassin-phase-two_spriteframes.tres",
]
const REQUIRED_ANIMATIONS: Array[StringName] = [&"idle_E", &"idle_W", &"attack_E", &"hurt_W", &"death_W"]
const TILESETS: Array[String] = [
	SOV + "/village/godot/medieval-village-free_tileset.tres",
	SOV + "/village/ColourVariations/ash/godot/medieval-village-free_tileset.tres",
	SOV + "/necropolis/godot/necropolis-free_tileset.tres",
	SOV + "/necropolis/ColourVariations/ash/godot/necropolis-free_tileset.tres",
	SOV + "/castle_courtyard/godot/castle-courtyard_tileset.tres",
]


func test_sprite_frames_load_with_battle_animations() -> void:
	for path: String in SPRITE_FRAMES:
		var frames: SpriteFrames = load(path) as SpriteFrames
		assert_not_null(frames, "could not load " + path)
		if frames == null:
			continue
		for anim: StringName in REQUIRED_ANIMATIONS:
			assert_true(frames.has_animation(anim), "%s lacks %s" % [path.get_file(), anim])
			if frames.has_animation(anim):
				assert_true(frames.get_frame_count(anim) > 0, "%s %s has no frames" % [path.get_file(), anim])


func test_tilesets_load() -> void:
	for path: String in TILESETS:
		var tileset: TileSet = load(path) as TileSet
		assert_not_null(tileset, "could not load " + path)
		if tileset != null:
			assert_true(tileset.get_source_count() > 0, "%s has no sources" % path.get_file())
