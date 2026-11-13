extends TestCase
## SceneManager.change_map with instant transitions: the new map replaces the old one, the
## player lands on the spawn with its facing, and walking into an exit changes the map.

const VILLAGE: String = "res://scenes/world/maps/village_01.tscn"
const GRAVEYARD: String = "res://scenes/world/maps/graveyard_01.tscn"
## A spawn id no map has.
const MISSING_SPAWN: StringName = &"no_such_spawn"
## Allowed distance (px) between the player and the spawn marker.
const SPAWN_TOLERANCE: float = 1.0
## Physics frames for the exit trigger to see the player.
const TRIGGER_FRAMES: int = 4

var _tree: SceneTree = Engine.get_main_loop() as SceneTree


func before_each() -> void:
	SceneManager.instant_transitions = true


## Frees the map the test left behind synchronously (the runner does not await after_each()).
## Changes map, then lets one frame pass: the vendor ambience controller adds nodes with
## deferred calls, which leak if the map is freed in the frame it was created.
func _change(path: String, spawn_id: StringName) -> void:
	await SceneManager.change_map(path, spawn_id)
	await _tree.process_frame


func after_each() -> void:
	var scene: Node = _tree.current_scene
	if scene != null:
		_tree.root.remove_child(scene)
		scene.free()
	_tree.current_scene = null
	SceneManager.instant_transitions = false
	GameState.current_map = ""


func test_change_map_places_player_at_spawn() -> void:
	await _change(GRAVEYARD, &"from_village")
	var map: Map = _tree.current_scene as Map
	assert_not_null(map, "current scene is a Map")
	if map == null:
		return
	assert_eq(map.map_id, &"graveyard_01")
	var spawn: SpawnPoint = map.get_spawn(&"from_village")
	assert_not_null(spawn, "graveyard has from_village")
	assert_not_null(map.player, "map has a player")
	if spawn == null or map.player == null:
		return
	assert_true(map.player.global_position.distance_to(spawn.global_position) <= SPAWN_TOLERANCE,
		"player at %s, spawn at %s" % [map.player.global_position, spawn.global_position])
	assert_eq(map.player.facing, StringName(spawn.facing), "player faces the spawn's direction")
	assert_eq(map.player.facing, &"N", "arrives facing away from the south gate")
	assert_true(map.player.input_enabled, "input is back on after the transition")
	assert_false(SceneManager.is_transitioning)
	assert_eq(GameState.current_map, GRAVEYARD)


func test_change_map_replaces_the_old_map() -> void:
	await _change(VILLAGE, &"start")
	var village: Node = _tree.current_scene
	var changed: Array[String] = []
	var on_changed: Callable = func(path: String) -> void: changed.append(path)
	SceneManager.map_changed.connect(on_changed)
	await _change(GRAVEYARD, &"from_village")
	SceneManager.map_changed.disconnect(on_changed)
	assert_false(is_instance_valid(village), "the village was freed")
	var maps: int = 0
	for child: Node in _tree.root.get_children():
		if child is Map:
			maps += 1
	assert_eq(maps, 1, "exactly one map in the tree")
	assert_eq(changed, [GRAVEYARD] as Array[String], "map_changed emitted once with the path")


func test_unknown_spawn_falls_back_to_first_spawn() -> void:
	await _change(VILLAGE, MISSING_SPAWN)
	var map: Map = _tree.current_scene as Map
	var first: SpawnPoint = map.get_spawns()[0]
	assert_eq(first.spawn_id, &"start", "the village's first spawn is start")
	assert_true(map.player.global_position.distance_to(first.global_position) <= SPAWN_TOLERANCE,
		"player at the first spawn")


func test_change_map_ignored_while_transitioning() -> void:
	SceneManager.is_transitioning = true
	await SceneManager.change_map(VILLAGE, &"start")
	SceneManager.is_transitioning = false
	assert_null(_tree.current_scene, "no map was loaded")


func test_walking_into_exit_changes_map() -> void:
	await _change(VILLAGE, &"from_graveyard")
	var village: Map = _tree.current_scene as Map
	var exit: MapTransition = _find_transition(village, GRAVEYARD)
	assert_not_null(exit, "village has an exit to the graveyard")
	if exit == null:
		return
	var target_spawn: StringName = exit.target_spawn  # the village is freed by the change
	village.player.set_physics_process(false)
	village.player.global_position = exit.global_position
	for i: int in TRIGGER_FRAMES:
		await _tree.physics_frame
	await _tree.process_frame  # the exit defers change_map out of the physics callback
	await _tree.process_frame
	var graveyard: Map = _tree.current_scene as Map
	assert_not_null(graveyard, "current scene is a map")
	if graveyard == null:
		return
	assert_eq(graveyard.map_id, &"graveyard_01", "walking into the exit loads the graveyard")
	var spawn: SpawnPoint = graveyard.get_spawn(target_spawn)
	assert_true(graveyard.player.global_position.distance_to(spawn.global_position) <= SPAWN_TOLERANCE,
		"player at the graveyard entry spawn")


func _find_transition(root: Node, target: String) -> MapTransition:
	for node: Node in root.find_children("*", "Area2D", true, false):
		var exit: MapTransition = node as MapTransition
		if exit != null and exit.target_map == target:
			return exit
	return null
