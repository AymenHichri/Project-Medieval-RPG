extends TestCase
## Footsteps (Phase 7): the map reads the TileSet `surface` under the player, and walking emits
## a footstep about every STEP_DISTANCE, which the map turns into a surface footstep sound.

const VILLAGE: String = "res://scenes/world/maps/village_01.tscn"
const GRAVEYARD: String = "res://scenes/world/maps/graveyard_01.tscn"

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _map: Map


func after_each() -> void:
	if is_instance_valid(_map):
		_tree.root.remove_child(_map)
		_map.free()
	_map = null


func _load(path: String) -> Map:
	_map = (load(path) as PackedScene).instantiate() as Map
	_tree.root.add_child(_map)
	await _tree.process_frame
	return _map


func test_village_streets_are_mud_and_lawns_grass() -> void:
	var map: Map = await _load(VILLAGE)
	assert_eq(map.surface_at(Vector2(2048, 1800)), &"mud", "the square (street overlay)")
	assert_eq(map.surface_at(Vector2(600, 800)), &"grass", "a lawn")


func test_graveyard_has_a_surface_underfoot() -> void:
	var map: Map = await _load(GRAVEYARD)
	var surface: StringName = map.surface_at(map.get_spawn(&"from_village").global_position)
	assert_true(surface in [&"stone", &"ash"], "got '%s'" % surface)


func test_walking_emits_footsteps_at_stride_distance() -> void:
	var map: Map = await _load(VILLAGE)
	map.place_player(&"start")
	var player: PlayerController = map.player
	player.set_physics_process(false)
	var steps: Array[Vector2] = []
	player.footstep.connect(func(at: Vector2) -> void: steps.append(at))
	var start: Vector2 = player.global_position
	for i: int in 120:
		player.move(Vector2.DOWN)
		await _tree.physics_frame
	var walked: float = player.global_position.distance_to(start)
	assert_true(walked > 300.0, "walked %f px" % walked)
	var expected: float = (walked - PlayerController.STEP_DISTANCE * 0.5) / PlayerController.STEP_DISTANCE
	assert_true(absf(steps.size() - expected) <= 1.5, "%d footsteps over %f px" % [steps.size(), walked])
	player.move(Vector2.ZERO)
	var count: int = steps.size()
	for i: int in 10:
		player.move(Vector2.ZERO)
		await _tree.physics_frame
	assert_eq(steps.size(), count, "no footsteps standing still")
