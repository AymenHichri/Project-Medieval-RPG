extends TestCase
## PlayerController.dir_from_vector: 8 sectors of 45°, centred on each direction (screen y down).

## Small angle offset (radians) used to probe both sides of a sector boundary.
const EPSILON: float = 0.001


func test_cardinal_and_diagonal_vectors() -> void:
	var cases: Dictionary[StringName, Vector2] = {
		&"E": Vector2(1, 0), &"SE": Vector2(1, 1), &"S": Vector2(0, 1), &"SW": Vector2(-1, 1),
		&"W": Vector2(-1, 0), &"NW": Vector2(-1, -1), &"N": Vector2(0, -1), &"NE": Vector2(1, -1),
	}
	for expected: StringName in cases:
		assert_eq(PlayerController.dir_from_vector(cases[expected]), expected, "for %s" % cases[expected])


func test_boundary_angles() -> void:
	var boundary: float = deg_to_rad(22.5)
	assert_eq(PlayerController.dir_from_vector(Vector2.from_angle(boundary - EPSILON)), &"E")
	assert_eq(PlayerController.dir_from_vector(Vector2.from_angle(boundary + EPSILON)), &"SE")
	assert_eq(PlayerController.dir_from_vector(Vector2.from_angle(-boundary + EPSILON)), &"E")
	assert_eq(PlayerController.dir_from_vector(Vector2.from_angle(-boundary - EPSILON)), &"NE")
	# Around west, where the angle wraps from +PI to -PI.
	assert_eq(PlayerController.dir_from_vector(Vector2.from_angle(PI - boundary + EPSILON)), &"W")
	assert_eq(PlayerController.dir_from_vector(Vector2.from_angle(PI - boundary - EPSILON)), &"SW")
	assert_eq(PlayerController.dir_from_vector(Vector2.from_angle(-PI + boundary - EPSILON)), &"W")
	assert_eq(PlayerController.dir_from_vector(Vector2.from_angle(-PI + boundary + EPSILON)), &"NW")


func test_zero_vector_keeps_last_direction() -> void:
	assert_eq(PlayerController.dir_from_vector(Vector2.ZERO, &"NW"), &"NW")
	assert_eq(PlayerController.dir_from_vector(Vector2(0.001, 0.0), &"E"), &"E", "below the input threshold")
	assert_eq(PlayerController.dir_from_vector(Vector2.ZERO), &"S", "default facing")


func test_every_direction_has_walk_and_idle_animations() -> void:
	var frames: SpriteFrames = load(
		"res://assets/vendor/sovdigital/knight/characters/knight/godot/knight_spriteframes.tres") as SpriteFrames
	for dir: StringName in PlayerController.DIRECTIONS:
		assert_true(frames.has_animation(StringName("walk_" + dir)), "walk_" + dir)
		assert_true(frames.has_animation(StringName("idle_" + dir)), "idle_" + dir)
