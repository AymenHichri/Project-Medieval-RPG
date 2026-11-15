extends TestCase
## Every CombatantVisual in res://data maps only animations that exist in its SpriteFrames (or that
## BattleSprite stands in for), and every battler in the data has a visual facing the right way.

const VISUAL_DIR: String = "res://data/visuals"
## Logical animations every visual must provide (no stand-in exists for them).
const REQUIRED: Array[StringName] = [&"idle", &"attack", &"hurt", &"death"]


func _visual_paths() -> Array[String]:
	var paths: Array[String] = []
	for file: String in DirAccess.get_files_at(VISUAL_DIR):
		if file.ends_with(".tres"):
			paths.append(VISUAL_DIR.path_join(file))
	return paths


func test_visuals_exist() -> void:
	assert_true(_visual_paths().size() >= 5, "knight, wolf, goblin, skeleton, charred skeleton")


func test_mapped_animations_exist() -> void:
	for path: String in _visual_paths():
		var visual: CombatantVisual = load(path) as CombatantVisual
		assert_not_null(visual, path)
		if visual == null:
			continue
		assert_not_null(visual.sprite_frames, "%s has SpriteFrames" % path)
		for anim: StringName in visual.anim_map:
			var vendor_name: StringName = visual.anim_map[anim]
			var frames: SpriteFrames = visual.frames_for(anim)
			var exists: bool = frames != null and frames.has_animation(vendor_name)
			assert_true(exists or anim in BattleSprite.STAND_INS,
					"%s: '%s' → '%s' is missing from its SpriteFrames" % [path, anim, vendor_name])
		for anim: StringName in REQUIRED:
			assert_true(visual.has_animation(anim), "%s maps '%s'" % [path, anim])


func test_hit_frames_are_inside_their_animations() -> void:
	for path: String in _visual_paths():
		var visual: CombatantVisual = load(path) as CombatantVisual
		var attack: StringName = visual.animation_for(&"attack")
		var count: int = visual.sprite_frames.get_frame_count(attack)
		assert_true(visual.hit_frame >= 0 and visual.hit_frame < count, "%s attack hit frame in range" % path)
		for anim: StringName in visual.hit_frames:
			if visual.has_animation(anim):
				var n: int = visual.frames_for(anim).get_frame_count(visual.animation_for(anim))
				assert_true(visual.hit_frames[anim] < n, "%s: hit frame of '%s' in range" % [path, anim])


func test_party_faces_east_enemies_face_west() -> void:
	var knight: CharacterData = load("res://data/characters/knight.tres") as CharacterData
	assert_not_null(knight.visual, "the Knight has a battle visual")
	if knight.visual != null:
		assert_eq(knight.visual.facing, &"E")
		assert_eq(knight.visual.anim_map[&"idle"], &"idle_E")
		assert_eq(knight.visual.offset, Vector2(0, -83), "feet pivot as in the exploration player")
	for id: String in ["wolf", "goblin_scout", "skeleton", "skeleton_charred"]:
		var enemy: EnemyData = load("res://data/enemies/%s.tres" % id) as EnemyData
		assert_not_null(enemy.visual, "%s has a battle visual" % id)
		if enemy.visual != null:
			assert_eq(enemy.visual.facing, &"W", id)
			assert_eq(enemy.visual.anim_map[&"attack"], &"attack_W", id)


func test_knight_moves_use_the_vendor_move_sheets() -> void:
	var knight: CombatantVisual = load(VISUAL_DIR + "/knight.tres") as CombatantVisual
	for anim: StringName in [&"whirlwind", &"charged_strike", &"cast"]:
		assert_true(knight.has_animation(anim), "knight maps %s" % anim)
		assert_ne(knight.frames_for(anim), knight.sprite_frames, "%s comes from a move sheet" % anim)
	assert_eq(knight.hit_frame_for(&"charged_strike"), 11, "vendor charged_strike hit frame")
	assert_eq(knight.last_frames[&"cast"], 6, "cast holds Charged Strike frames 0–6")


func test_skeleton_skill_falls_back_to_attack() -> void:
	var skeleton: CombatantVisual = load(VISUAL_DIR + "/skeleton.tres") as CombatantVisual
	assert_false(skeleton.has_animation(&"skill"), "no second attack in the skeleton sheets")
	assert_true(&"skill" in BattleSprite.STAND_INS)
