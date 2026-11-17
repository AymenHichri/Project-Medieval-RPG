extends TestCase
## The vertical slice end to end (Phase 7, headless): title → New Game → intro card → village
## start spawn; then to the graveyard, a forced encounter, an auto-battle win, and back in the
## world with gold, XP and drops applied.

const GRAVEYARD: String = "res://scenes/world/maps/graveyard_01.tscn"
const MAX_FRAMES: int = 6000

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _saved_rng: RandomNumberGenerator


func before_each() -> void:
	SceneManager.instant_transitions = true
	SceneManager.instant_battles = true
	SceneManager.auto_battles = true
	SceneManager.battle_rng = BattleFixtures.rng(3)
	_saved_rng = GameState.rng
	GameState.rng = BattleFixtures.rng(9)


func after_each() -> void:
	var scene: Node = _tree.current_scene
	if scene != null and is_instance_valid(scene):
		_tree.root.remove_child(scene)
		scene.free()
	_tree.current_scene = null
	SceneManager.instant_transitions = false
	SceneManager.instant_battles = false
	SceneManager.auto_battles = false
	SceneManager.battle_rng = null
	GameState.rng = _saved_rng
	AudioManager.music.stop(0.0)
	GameState.new_game()


func _frames(count: int) -> void:
	for i: int in count:
		await _tree.process_frame


func test_title_new_game_intro_card_village() -> void:
	var title: Node = await SceneManager.go_to(SceneManager.TITLE_SCENE)
	assert_true(title is TitleScreen)
	# The backdrop's ambience controller finishes its deferred setup on the next frame.
	await _frames(2)
	GameState.gold = 77
	(title.get_node(^"%NewGameButton") as Button).pressed.emit()
	await _frames(3)
	var card: IntroCard = _tree.current_scene as IntroCard
	assert_not_null(card, "the intro card follows New Game")
	assert_eq(GameState.gold, 0, "a new game resets GameState")
	assert_eq(GameState.party.size(), 1)
	assert_eq(GameState.party.leader().level, 1)
	card.show_all()
	assert_true(card.all_lines_shown())
	card.finish()
	await _frames(3)
	var village: Map = _tree.current_scene as Map
	assert_not_null(village, "a map is current")
	if village == null:
		return
	assert_eq(village.map_id, &"village_01")
	var start: SpawnPoint = village.get_spawn(&"start")
	assert_true(village.player.global_position.distance_to(start.global_position) < 1.0, "at the start spawn")
	assert_true(village.player.input_enabled, "the player can move")
	assert_eq(GameState.current_map, SceneManager.START_MAP)


func test_graveyard_encounter_win_applies_rewards() -> void:
	GameState.new_game()
	await SceneManager.change_map(SceneManager.START_MAP, SceneManager.START_SPAWN)
	await _frames(2)
	await SceneManager.change_map(GRAVEYARD, &"from_village")
	await _frames(1)
	var map: Map = _tree.current_scene as Map
	assert_eq(map.map_id, &"graveyard_01")
	await _tree.physics_frame
	await _tree.physics_frame
	var member: PartyMember = GameState.party.leader()
	var position: Vector2 = map.player.global_position
	var results: Array[BattleResult] = []
	var on_end: Callable = func(r: BattleResult) -> void: results.append(r)
	SceneManager.battle_ended.connect(on_end)
	map.player.encounter_tracker.rng.seed = 8
	assert_true(map.player.encounter_tracker.force_encounter(), "an encounter starts")
	var frames: int = 0
	while results.is_empty() and frames < MAX_FRAMES:
		await _tree.process_frame
		frames += 1
	SceneManager.battle_ended.disconnect(on_end)
	assert_eq(results.size(), 1, "the battle ended")
	if results.is_empty():
		return
	var result: BattleResult = results[0]
	assert_true(result.is_victory(), "the level 1 Knight wins a forced encounter")
	assert_eq(_tree.current_scene, map, "back in the graveyard")
	assert_true(map.player.global_position.distance_to(position) <= 1.0, "where the player stood")
	assert_eq(GameState.gold, result.gold, "gold applied")
	assert_eq(member.xp, result.xp_per_member, "XP applied")
	assert_eq(member.level, Progression.level_for_xp(member.data.growth, member.xp), "level follows XP")
	for drop: ItemData in result.drops:
		assert_true(GameState.item_count(drop.id) > 0, "drop %s added" % drop.id)
	assert_true(map.player.input_enabled)
