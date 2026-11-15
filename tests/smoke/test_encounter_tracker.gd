extends TestCase
## EncounterTracker: steps from travelled distance (64 px each), none while blocked by a wall,
## the zone stack (last entered wins), grace after a reset, and the graveyard/village zones.

const PLAYER_SCENE: String = "res://scenes/world/player/player.tscn"
const VILLAGE: String = "res://scenes/world/maps/village_01.tscn"
const GRAVEYARD: String = "res://scenes/world/maps/graveyard_01.tscn"

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _root: Node2D
var _was_enabled: bool = true


func before_each() -> void:
	_was_enabled = EncounterTracker.encounters_enabled
	EncounterTracker.encounters_enabled = true


func after_each() -> void:
	if is_instance_valid(_root):
		_tree.root.remove_child(_root)
		_root.free()
	_root = null
	EncounterTracker.encounters_enabled = _was_enabled


## A bare scene with a player at `at` (its own physics process off: tests drive `move()`).
func _player_scene(at: Vector2 = Vector2.ZERO) -> PlayerController:
	_root = Node2D.new()
	_tree.root.add_child(_root)
	var player: PlayerController = (load(PLAYER_SCENE) as PackedScene).instantiate() as PlayerController
	player.position = at
	_root.add_child(player)
	player.set_physics_process(false)
	return player


func _zone(table_id: StringName, rect: Rect2, chance: float = 0.0) -> EncounterZone:
	var zone: EncounterZone = (load("res://scenes/world/components/encounter_zone.tscn") as PackedScene).instantiate() as EncounterZone
	var table: EncounterTable = EncounterTable.new()
	table.id = table_id
	table.base_chance_per_step = chance
	table.grace_steps = 0
	var group: EncounterGroup = EncounterGroup.new()
	group.enemies = [BattleFixtures.enemy_data(&"foe", StatBlock.new())]
	table.groups = [group]
	zone.table = table
	zone.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
		Vector2(rect.position.x, rect.end.y)])
	_root.add_child(zone)
	return zone


func _physics_frames(count: int) -> void:
	for i: int in count:
		await _tree.physics_frame


func test_640_px_is_10_steps() -> void:
	var tracker: EncounterTracker = _player_scene().encounter_tracker
	var steps: Array[int] = []
	tracker.step_taken.connect(func(n: int) -> void: steps.append(n))
	assert_eq(tracker.add_distance(640.0), 10)
	assert_eq(tracker.total_steps, 10)
	assert_eq(steps.size(), 10, "one step_taken per step")
	assert_eq(tracker.add_distance(63.0), 0, "a partial step is kept")
	assert_eq(tracker.add_distance(1.0), 1, "and completes later")


func test_walking_counts_real_distance() -> void:
	var player: PlayerController = _player_scene(Vector2(0, 0))
	var tracker: EncounterTracker = player.encounter_tracker
	var start: Vector2 = player.global_position
	for i: int in 60:
		player.move(Vector2.RIGHT)
		await _tree.physics_frame
	var travelled: float = player.global_position.distance_to(start)
	assert_true(travelled > 128.0, "the player moved (%f px)" % travelled)
	var expected: int = floori(travelled / EncounterTracker.STEP_DISTANCE)
	assert_true(absi(tracker.total_steps - expected) <= 1,
		"steps %d for %f px (expected about %d)" % [tracker.total_steps, travelled, expected])


func test_blocked_by_a_wall_counts_no_steps() -> void:
	var player: PlayerController = _player_scene(Vector2(0, 0))
	var wall: StaticBody2D = StaticBody2D.new()
	wall.collision_layer = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(40, 400)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector2(50, 0)
	_root.add_child(wall)
	await _physics_frames(2)
	# Walk into the wall until pressed against it, then keep pushing.
	for i: int in 30:
		player.move(Vector2.RIGHT)
		await _tree.physics_frame
	var tracker: EncounterTracker = player.encounter_tracker
	var before: int = tracker.total_steps
	var x: float = player.global_position.x
	for i: int in 120:
		player.move(Vector2.RIGHT)
		await _tree.physics_frame
	assert_almost_eq(player.global_position.x, x, 1.0, "the wall stops the player")
	assert_eq(tracker.total_steps, before, "pushing against a wall takes no steps")


func test_no_steps_while_input_is_off() -> void:
	var player: PlayerController = _player_scene()
	player.input_enabled = false
	player.velocity = Vector2(300, 0)
	await _physics_frames(30)
	assert_eq(player.encounter_tracker.total_steps, 0)


func test_overlapping_zones_last_entered_wins() -> void:
	var player: PlayerController = _player_scene(Vector2(-1000, -1000))
	var outer: EncounterZone = _zone(&"woods", Rect2(-400, -400, 800, 800))
	var inner: EncounterZone = _zone(&"deep_woods", Rect2(-100, -100, 200, 200))
	var tracker: EncounterTracker = player.encounter_tracker
	await _physics_frames(3)
	assert_null(tracker.current_zone(), "outside every zone")
	player.global_position = Vector2(-300, 0)
	await _physics_frames(3)
	assert_eq(tracker.current_zone(), outer, "in the outer zone")
	player.global_position = Vector2(0, 0)
	await _physics_frames(3)
	assert_eq(tracker.current_zone(), inner, "the inner zone wins once entered")
	player.global_position = Vector2(-300, 0)
	await _physics_frames(3)
	assert_eq(tracker.current_zone(), outer, "leaving the inner zone restores the outer one")
	player.global_position = Vector2(-1000, -1000)
	await _physics_frames(3)
	assert_null(tracker.current_zone(), "left both")


func test_exit_report_while_still_inside_is_ignored() -> void:
	var player: PlayerController = _player_scene(Vector2(0, 0))
	var zone: EncounterZone = _zone(&"woods", Rect2(-200, -200, 400, 400))
	await _physics_frames(3)
	var tracker: EncounterTracker = player.encounter_tracker
	assert_eq(tracker.current_zone(), zone)
	tracker.exit_zone(zone)  # what the zone reports when the world is detached for a battle
	assert_eq(tracker.current_zone(), zone, "the player still stands inside")
	tracker.enter_zone(zone)
	tracker.exit_zone(zone)
	assert_eq(tracker.current_zone(), zone, "re-entering does not duplicate the zone")


func test_steps_in_a_zone_trigger_and_reset_grace() -> void:
	var player: PlayerController = _player_scene(Vector2(0, 0))
	var zone: EncounterZone = _zone(&"woods", Rect2(-200, -200, 400, 400), 1.0)
	zone.table.grace_steps = 3
	await _physics_frames(3)
	var tracker: EncounterTracker = player.encounter_tracker
	var met: Array[EncounterGroup] = []
	tracker.encounter_triggered.connect(func(g: EncounterGroup, _t: EncounterTable) -> void: met.append(g))
	tracker.add_distance(EncounterTracker.STEP_DISTANCE * 3)
	assert_eq(met.size(), 0, "no battle during the 3 grace steps")
	tracker.add_distance(EncounterTracker.STEP_DISTANCE * 10)
	assert_eq(met.size(), 1, "one battle on step 4; the rest of the distance is dropped")
	assert_eq(tracker.steps_since_last, 0, "grace restarts after a battle")
	EncounterTracker.encounters_enabled = false
	tracker.add_distance(EncounterTracker.STEP_DISTANCE * 20)
	assert_eq(met.size(), 1, "no battle while encounters are switched off")
	assert_true(tracker.force_encounter(), "F5 still forces one")
	assert_eq(met.size(), 2)


func test_steps_tick_game_state_modifiers() -> void:
	var tracker: EncounterTracker = _player_scene().encounter_tracker
	GameState.add_encounter_modifier(&"test_torch", 0.25, 3)
	tracker.add_distance(EncounterTracker.STEP_DISTANCE * 3)
	assert_false(GameState.encounter_rate_modifiers.has(&"test_torch"), "expired after 3 steps")
	GameState.remove_encounter_modifier(&"test_torch")


func test_graveyard_has_a_zone_and_the_village_none() -> void:
	var village: Map = (load(VILLAGE) as PackedScene).instantiate() as Map
	assert_eq(village.get_encounter_zones().size(), 0, "no random encounters in the village")
	village.free()
	var graveyard: Map = (load(GRAVEYARD) as PackedScene).instantiate() as Map
	var zones: Array[EncounterZone] = graveyard.get_encounter_zones()
	assert_eq(zones.size(), 1)
	if zones.size() == 1:
		assert_not_null(zones[0].table, "zone has a table")
		assert_eq(zones[0].zone_id(), &"graveyard_outskirts")
		var spawn: SpawnPoint = null
		for s: SpawnPoint in graveyard.get_spawns():
			spawn = s
		assert_true(Geometry2D.is_point_in_polygon(spawn.position, zones[0].polygon),
			"the entry spawn is inside the zone (the grace steps keep it quiet)")
	graveyard.free()
