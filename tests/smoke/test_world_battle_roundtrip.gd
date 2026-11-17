extends TestCase
## SceneManager.start_battle → auto-win → end_battle: the same map instance comes back with the
## player where it stood, the rewards are applied once, and the map music resumes after pop().
## Also: a forced encounter in the graveyard starts a battle, and a defeat returns to the title.

const GRAVEYARD: String = "res://scenes/world/maps/graveyard_01.tscn"
const MAX_FRAMES: int = 6000
const MusicTest: GDScript = preload("res://tests/unit/test_music_manager.gd")

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _gold: int = 0
var _items: Dictionary[StringName, int] = {}


func before_each() -> void:
	SceneManager.instant_transitions = true
	SceneManager.instant_battles = true
	SceneManager.auto_battles = true
	SceneManager.battle_rng = BattleFixtures.rng(3)
	_gold = GameState.gold
	_items = GameState.items.duplicate()
	GameState.party.clear()
	GameState.ensure_party()


func after_each() -> void:
	var scene: Node = _tree.current_scene
	if scene != null:
		_tree.root.remove_child(scene)
		scene.free()
	_tree.current_scene = null
	SceneManager.instant_transitions = false
	SceneManager.instant_battles = false
	SceneManager.auto_battles = false
	SceneManager.battle_rng = null
	AudioManager.music.stop(0.0)
	GameState.current_map = ""
	GameState.gold = _gold
	GameState.items = _items
	GameState.party.clear()


func _wolf_setup(music: MusicTrack = null) -> BattleSetup:
	var setup: BattleSetup = BattleSetup.new()
	setup.enemies = [load("res://data/enemies/wolf.tres") as EnemyData]
	setup.music = music
	return setup


func _graveyard() -> Map:
	await SceneManager.change_map(GRAVEYARD, &"from_village")
	await _tree.process_frame
	return _tree.current_scene as Map


func test_roundtrip_restores_map_player_and_music() -> void:
	var map: Map = await _graveyard()
	assert_not_null(map)
	if map == null:
		return
	var field: MusicTrack = MusicTrack.new()
	field.stream = MusicTest.silent_stream(30.0)
	map.music = field
	AudioManager.music.play(field, 0.0)
	map.player.global_position = Vector2(1500, 1800)
	var position: Vector2 = map.player.global_position
	var battle_music: MusicTrack = MusicTrack.new()
	battle_music.stream = MusicTest.silent_stream(30.0)
	var started: Array[BattleSetup] = []
	var ended: Array[BattleResult] = []
	var on_start: Callable = func(s: BattleSetup) -> void: started.append(s)
	var on_end: Callable = func(r: BattleResult) -> void: ended.append(r)
	SceneManager.battle_started.connect(on_start)
	SceneManager.battle_ended.connect(on_end)
	var seen_battle: Array[bool] = [false]
	var watch: Callable = func() -> void:
		seen_battle[0] = seen_battle[0] or _tree.current_scene is BattleController
	_tree.process_frame.connect(watch)

	var result: BattleResult = await SceneManager.start_battle(_wolf_setup(battle_music))

	_tree.process_frame.disconnect(watch)
	SceneManager.battle_started.disconnect(on_start)
	SceneManager.battle_ended.disconnect(on_end)
	assert_not_null(result, "the battle ran")
	if result == null:
		return
	assert_true(seen_battle[0], "the battle scene was the current scene")
	assert_true(result.is_victory(), "auto-battle wins against one wolf")
	assert_eq(_tree.current_scene, map, "the same map instance is back")
	assert_true(map.is_inside_tree())
	assert_true(map.player.global_position.distance_to(position) <= 1.0,
		"player at %s, was at %s" % [map.player.global_position, position])
	assert_eq(GameState.gold, _gold + result.gold, "gold applied once")
	assert_true(result.gold > 0, "the wolf gives gold")
	for drop: ItemData in result.drops:
		assert_true(GameState.item_count(drop.id) > 0, "drop %s added" % drop.id)
	assert_eq(AudioManager.music.current_track, field, "the map track is current again")
	assert_eq(AudioManager.music.stack_depth(), 0)
	assert_eq(started.size(), 1)
	assert_eq(ended.size(), 1)
	assert_false(SceneManager.in_battle)
	assert_false(SceneManager.is_transitioning)
	assert_true(map.player.input_enabled, "the player can move again")
	assert_eq(map.player.encounter_tracker.steps_since_last, 0, "grace restarts after the battle")
	assert_null(SceneManager.detached_world())
	for child: Node in _tree.root.get_children():
		assert_false(child is BattleController and not child.is_queued_for_deletion(), "battle freed")


func test_party_hp_carries_over_between_battles() -> void:
	await _graveyard()
	var knight: Combatant = GameState.party.leader().combatant
	await SceneManager.start_battle(_wolf_setup())
	var after_first: int = knight.hp
	assert_eq(GameState.party.leader().combatant, knight, "same party member")
	assert_true(after_first > 0)
	await SceneManager.start_battle(_wolf_setup())
	assert_true(knight.hp <= after_first, "HP is not refilled between battles")


func test_forced_encounter_in_the_graveyard_starts_a_battle() -> void:
	var map: Map = await _graveyard()
	var ended: Array[BattleResult] = []
	var on_end: Callable = func(r: BattleResult) -> void: ended.append(r)
	SceneManager.battle_ended.connect(on_end)
	await _tree.physics_frame
	await _tree.physics_frame
	assert_not_null(map.player.encounter_tracker.current_zone(), "the entry spawn is in the zone")
	map.player.encounter_tracker.rng.seed = 8
	assert_true(map.player.encounter_tracker.force_encounter(), "an encounter starts")
	var frames: int = 0
	while ended.is_empty() and frames < MAX_FRAMES:
		await _tree.process_frame
		frames += 1
	SceneManager.battle_ended.disconnect(on_end)
	assert_eq(ended.size(), 1, "the battle ended within %d frames" % MAX_FRAMES)
	if ended.is_empty():
		return
	if ended[0].outcome == BattleEngine.Outcome.VICTORY:
		assert_eq(_tree.current_scene, map, "back on the graveyard map")


func test_defeat_shows_game_over() -> void:
	var map: Map = await _graveyard()
	GameState.party.leader().combatant.hp = 1
	var setup: BattleSetup = BattleSetup.new()
	var skeleton: EnemyData = load("res://data/enemies/skeleton.tres") as EnemyData
	setup.enemies = [skeleton, skeleton, skeleton]
	var result: BattleResult = await SceneManager.start_battle(setup)
	assert_eq(result.outcome, BattleEngine.Outcome.DEFEAT, "a 1 HP knight loses to three skeletons")
	assert_false(is_instance_valid(map), "the map was dropped")
	assert_not_null(_tree.current_scene, "a scene is current")
	if _tree.current_scene != null:
		assert_eq(_tree.current_scene.scene_file_path, SceneManager.GAME_OVER_SCENE, "the Game Over screen")
	assert_eq(GameState.gold, _gold, "no rewards on defeat")
	assert_false(SceneManager.in_battle)
	assert_false(SceneManager.is_transitioning)


func test_start_battle_is_ignored_while_busy() -> void:
	await _graveyard()
	SceneManager.is_transitioning = true
	var result: BattleResult = await SceneManager.start_battle(_wolf_setup())
	SceneManager.is_transitioning = false
	assert_null(result, "ignored during a transition")
	assert_null(await SceneManager.start_battle(BattleSetup.new()), "an empty setup is ignored")
