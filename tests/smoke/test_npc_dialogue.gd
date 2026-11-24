extends TestCase
## The Elder in village_01 (Phase 7): reachable on foot from the start spawn, turns to face the
## player, shows the full dialogue box (speaker, portrait, typewriter, choices), and the choice
## sets a flag that changes the next talk. The well heals the party.

const VILLAGE: String = "res://scenes/world/maps/village_01.tscn"
const SETTLE_FRAMES: int = 4
## Physics frames allowed to walk to a target.
const WALK_FRAMES: int = 600

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _map: Map
var _flags: Dictionary[StringName, Variant] = {}
var _items: Inventory
var _party: Party
var _speed: Settings.TextSpeed
var _quests: QuestLog


func before_each() -> void:
	_flags = GameState.flags.duplicate()
	_items = GameState.inventory
	GameState.inventory = Inventory.new()
	_party = GameState.party
	_speed = Settings.text_speed
	_quests = GameState.quests
	GameState.quests = QuestLog.new()
	GameState.flags = {}
	GameState.party = Party.new()
	GameState.ensure_party()
	_map = (load(VILLAGE) as PackedScene).instantiate() as Map
	_tree.root.add_child(_map)
	_map.place_player(&"start")


func after_each() -> void:
	DialogueTestUtil.close_dialogue()
	if is_instance_valid(_map):
		_tree.root.remove_child(_map)
		_map.free()
	_map = null
	GameState.flags = _flags
	GameState.inventory = _items
	GameState.party = _party
	GameState.quests = _quests
	Settings.text_speed = _speed


## Walks the player (with real physics) to `target`, then faces `facing`. Returns true on arrival.
func _walk_to(target: Vector2, facing: StringName) -> bool:
	var player: PlayerController = _map.player
	for i: int in WALK_FRAMES:
		var to_target: Vector2 = target - player.global_position
		if to_target.length() < 8.0:
			break
		player.move(to_target.normalized() * minf(1.0, to_target.length() / 20.0))
		await _tree.physics_frame
	player.move(Vector2.ZERO)
	player.face(facing)
	for i: int in SETTLE_FRAMES:
		await _tree.physics_frame
	return player.global_position.distance_to(target) < 12.0


func _elder() -> Npc:
	return _map.get_node(^"World/Elder") as Npc


func test_the_elder_is_reachable_and_faces_the_player() -> void:
	var elder: Npc = _elder()
	assert_not_null(elder)
	assert_eq(elder.current_facing, &"SW", "rests facing the start spawn")
	_map.player.set_physics_process(false)
	var arrived: bool = await _walk_to(elder.global_position + Vector2(-70, 70), &"NE")
	assert_true(arrived, "walked from the start spawn to the Elder (at %s)" % _map.player.global_position)
	assert_eq(_map.player.probe.target, elder, "the Elder is focused")
	assert_true(_map.player.probe.try_interact())
	assert_eq(elder.current_facing, &"SW", "turned towards the player (south-west of it)")
	var box: DialogueBox = DialogueManager.get_box()
	assert_eq(box.get_speaker(), "Elder Maren")
	assert_not_null(box.get_portrait(), "portrait shown")
	DialogueTestUtil.close_dialogue()
	await _tree.process_frame
	assert_eq(elder.current_facing, &"SW", "back to its resting facing")


func test_typewriter_then_choices_then_flag_changes_second_talk() -> void:
	Settings.text_speed = Settings.TextSpeed.NORMAL
	var elder: Npc = _elder()
	var box: DialogueBox = DialogueManager.get_box()
	await _tree.process_frame
	elder.interact(_map.player)
	assert_true(DialogueManager.is_active)
	assert_true(box.is_typing(), "the line types out")
	for i: int in 3:
		await _tree.process_frame
	assert_true(box.is_typing(), "still typing after a few frames")
	box.finish_typing()
	assert_false(box.is_typing())
	assert_eq(box.get_choice_buttons().size(), 0, "first line has no choices")
	while not DialogueManager.runner.has_choices():
		DialogueManager.advance()
	assert_eq(box.get_choice_buttons().size(), 0, "choices wait for the text")
	box.finish_typing()
	var buttons: Array[Button] = box.get_choice_buttons()
	assert_eq(buttons.size(), 2)
	assert_eq(buttons[0].text, "I'll go.")
	buttons[0].pressed.emit()
	assert_eq(GameState.get_flag(&"elder_agreed"), true)
	assert_eq(GameState.item_count(&"minor_potion"), 2)
	DialogueTestUtil.close_dialogue()
	await _tree.process_frame
	elder.interact(_map.player)
	assert_eq(DialogueManager.runner.dialogue_id, &"elder_again_agreed", "a different response")
	DialogueTestUtil.close_dialogue()


func test_instant_text_speed_shows_the_whole_line() -> void:
	Settings.text_speed = Settings.TextSpeed.INSTANT
	# One frame for the map's deferred setup (the ambience controller adds its layer deferred).
	await _tree.process_frame
	_elder().interact(_map.player)
	assert_false(DialogueManager.get_box().is_typing())
	DialogueTestUtil.close_dialogue()


func test_the_well_heals_the_party() -> void:
	var well: RestPoint = _map.get_node(^"World/Well/RestPoint") as RestPoint
	assert_not_null(well)
	_map.player.set_physics_process(false)
	var arrived: bool = await _walk_to(well.global_position + Vector2(0, 80), &"N")
	assert_true(arrived, "walked to the well (at %s)" % _map.player.global_position)
	assert_eq(_map.player.probe.target, well, "the well is focused")
	var knight: Combatant = GameState.party.leader().combatant
	knight.hp = 5
	knight.mp = 0
	assert_true(_map.player.probe.try_interact())
	assert_eq(knight.hp, knight.max_hp())
	assert_eq(knight.mp, knight.max_mp())
	assert_eq(DialogueManager.runner.dialogue_id, &"rest_at_well")
	DialogueTestUtil.close_dialogue()
