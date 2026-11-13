extends TestCase
## Exploration scenes instantiate headless, run a few frames and are wired correctly.

const VILLAGE: String = "res://scenes/world/maps/village_01.tscn"
const PLAYER: String = "res://scenes/world/player/player.tscn"
## Frames to run after adding a scene to the tree.
const SMOKE_FRAMES: int = 3
## Physics frames to push the player against a wall (≈1 s at 60 Hz, ≥ 2 tiles of walking).
const PUSH_FRAMES: int = 60

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _node: Node


## Frees synchronously: the runner does not await after_each(), and a lingering map would
## overlap the next test's map (duplicate navigation regions, leaks at exit).
func after_each() -> void:
	if is_instance_valid(_node):
		_node.get_parent().remove_child(_node)
		_node.free()
	_node = null


func test_player_scene_runs() -> void:
	var player: PlayerController = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_node = player
	_tree.root.add_child(player)
	await _frames(SMOKE_FRAMES)
	assert_eq(player.sprite.animation, &"idle_S")
	assert_almost_eq(player.camera.zoom.x, FollowCamera.DEFAULT_ZOOM, 0.001, "camera zoom")
	assert_eq(player.collision_layer, 1 << 2, "player is on physics layer 3 'player'")
	assert_true(player.collision_mask & 1 != 0, "player collides with world_solid")


func test_village_runs_and_has_camera_bounds() -> void:
	var map: Map = await _add_village()
	await _frames(SMOKE_FRAMES)
	var bounds: Rect2 = map.get_camera_bounds()
	assert_true(bounds.get_area() > 0.0, "camera bounds have positive area: %s" % bounds)
	assert_eq(map.map_id, &"village_01")
	assert_not_null(map.player, "map found its player")
	if map.player == null:
		return
	var camera: FollowCamera = map.player.camera
	assert_eq(camera.limit_left, floori(bounds.position.x))
	assert_eq(camera.limit_bottom, ceili(bounds.end.y))
	var world: Node2D = map.get_node(^"World") as Node2D
	assert_true(world.y_sort_enabled, "World is y-sorted")
	assert_eq(map.player.get_parent(), world, "player is a y-sorted sibling of the props")


func test_village_start_spawn() -> void:
	var map: Map = await _add_village()
	var spawn: SpawnPoint = map.get_spawn(&"start")
	assert_not_null(spawn, "start spawn")
	if spawn != null:
		assert_true(bounds_contain(map, spawn.global_position), "start spawn is inside the map")


func test_props_block_the_player() -> void:
	var map: Map = await _add_village()
	var player: PlayerController = map.player
	var cottage: Node2D = map.get_node(^"World/Cottage") as Node2D
	player.set_physics_process(false)
	player.global_position = cottage.global_position + Vector2(0, 160)
	for i: int in PUSH_FRAMES:
		await _tree.physics_frame
		player.move(Vector2.UP)
	assert_true(player.global_position.y > cottage.global_position.y,
		"walked through the cottage footprint: y=%f, base=%f" % [player.global_position.y, cottage.global_position.y])
	assert_eq(player.facing, &"N")
	assert_eq(player.sprite.animation, StringName("%s_N" % PlayerController.MOVE_ANIMATION))


func test_house_sides_are_solid() -> void:
	# Regression: the vendor footprint only covers the bottom band of a building, so the
	# Knight could walk into the walls from the side. The HouseBlock closes that gap.
	var map: Map = await _add_village()
	var player: PlayerController = map.player
	var cottage: Node2D = map.get_node(^"World/Cottage") as Node2D
	var block: CollisionPolygon2D = cottage.get_node(^"Body/HouseBlock") as CollisionPolygon2D
	assert_not_null(block, "cottage has a HouseBlock")
	if block == null:
		return
	var right_edge: float = cottage.global_position.x + block.polygon[1].x
	var wall_line: float = cottage.global_position.y
	player.set_physics_process(false)
	player.global_position = Vector2(right_edge + 200.0, wall_line - 100.0)
	for i: int in PUSH_FRAMES:
		await _tree.physics_frame
		player.move(Vector2.LEFT)
	assert_true(player.global_position.x > right_edge,
		"walked into the cottage side: x=%f, wall=%f" % [player.global_position.x, right_edge])


func test_move_animation_speed_follows_ground_speed() -> void:
	var map: Map = await _add_village()
	var player: PlayerController = map.player
	player.set_physics_process(false)
	for i: int in 5:
		await _tree.physics_frame
		player.move(Vector2.DOWN)
	assert_almost_eq(player.sprite.speed_scale,
		player.walk_speed / PlayerController.MOVE_CYCLE_GROUND_SPEED, 0.05, "walk playback")
	await _tree.physics_frame
	player.move(Vector2.ZERO)
	assert_almost_eq(player.sprite.speed_scale, player.idle_animation_speed, 0.001, "idle playback")


func test_player_on_apron_draws_in_front_of_house() -> void:
	# Regression: houses sorted at the bottom of their image (the far edge of the cobble
	# apron), so a player standing on the apron was drawn behind the house.
	var map: Map = await _add_village()
	var cottage: Node2D = map.get_node(^"World/Cottage") as Node2D
	var footprint: CollisionPolygon2D = cottage.get_node(^"Body/Footprint") as CollisionPolygon2D
	var top: float = INF
	for point: Vector2 in footprint.polygon:
		top = minf(top, point.y)
	assert_almost_eq(top, 0.0, 0.5, "house origin (Y-sort point) is at the front wall line")


func test_debug_overlay_text() -> void:
	var map: Map = await _add_village()
	var overlay: DebugOverlay = null
	for child: Node in map.get_children():
		if child is DebugOverlay:
			overlay = child as DebugOverlay
	assert_not_null(overlay, "debug builds add the overlay")
	if overlay != null:
		var text: String = overlay.build_text()
		assert_true(text.contains("FPS"), text)
		assert_true(text.contains("village_01"), text)
		assert_true(text.contains("Player"), text)
		assert_true(text.contains("Zone none"), text)


func bounds_contain(map: Map, point: Vector2) -> bool:
	return map.get_camera_bounds().has_point(point)


func _add_village() -> Map:
	var map: Map = (load(VILLAGE) as PackedScene).instantiate() as Map
	_node = map
	_tree.root.add_child(map)
	await _tree.process_frame
	return map


func _frames(count: int) -> void:
	for i: int in count:
		await _tree.process_frame
