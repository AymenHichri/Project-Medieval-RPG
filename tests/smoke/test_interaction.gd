extends TestCase
## Facing an Interactable shows its prompt; `accept` opens its dialogue in the box, the player
## can't move or interact while it is open, and advancing past the last line closes it.

const GRAVEYARD: String = "res://scenes/world/maps/graveyard_01.tscn"
const HEADSTONE: NodePath = ^"World/HeadstoneWeathered/Interactable"
## Physics frames for the probe to move and its overlaps to update.
const SETTLE_FRAMES: int = 4
## Where the player stands relative to the headstone's interactable (just south of it).
const STAND_OFFSET: Vector2 = Vector2(0, 50)

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _map: Map


func after_each() -> void:
	DialogueTestUtil.close_dialogue()
	if is_instance_valid(_map):
		_tree.root.remove_child(_map)
		_map.free()
	_map = null


func test_vector_from_dir_inverts_dir_from_vector() -> void:
	for dir: StringName in PlayerController.DIRECTIONS:
		var v: Vector2 = PlayerController.vector_from_dir(dir)
		assert_almost_eq(v.length(), 1.0, 0.0001, "%s is a unit vector" % dir)
		assert_eq(PlayerController.dir_from_vector(v), dir)
	assert_eq(PlayerController.vector_from_dir(&"up"), Vector2.ZERO, "unknown name")


func test_facing_an_object_focuses_it() -> void:
	var headstone: Interactable = await _stand_by_headstone(&"N")
	var probe: InteractionProbe = _map.player.probe
	assert_eq(probe.target, headstone, "probe focuses the headstone")
	assert_true(headstone.is_focused(), "prompt is shown")


func test_facing_away_does_not_focus() -> void:
	var headstone: Interactable = await _stand_by_headstone(&"S")
	assert_null(_map.player.probe.target, "nothing in front of the player")
	assert_false(headstone.is_focused(), "prompt hidden")


func test_interact_opens_and_closes_the_dialogue() -> void:
	var headstone: Interactable = await _stand_by_headstone(&"N")
	var lines: Array = DialogueData.load_dialogue(headstone.dialogue_id)["lines"] as Array
	var player: PlayerController = _map.player
	var box: DialogueBox = DialogueManager.get_box()

	assert_true(player.probe.try_interact(), "interaction started")
	assert_true(DialogueManager.is_active, "dialogue open")
	assert_true(box.is_open(), "box visible")
	assert_eq(box.get_text(), str((lines[0] as Dictionary)["text"]), "first line shown")
	assert_false(player.can_act(), "player blocked while the dialogue is open")
	assert_false(headstone.is_focused(), "prompt hidden during the dialogue")
	assert_false(player.probe.try_interact(), "no second interaction while open")

	# Movement input is ignored: physics frames with the player's own process don't move it.
	var before: Vector2 = player.global_position
	Input.action_press(&"move_down")
	for i: int in SETTLE_FRAMES:
		await _tree.physics_frame
	Input.action_release(&"move_down")
	assert_eq(player.global_position, before, "player did not move")

	for i: int in lines.size():
		DialogueManager.advance()
	assert_false(DialogueManager.is_active, "dialogue closed after the last line")
	assert_false(box.is_open(), "box hidden")
	assert_true(player.can_act(), "player free again")
	for i: int in SETTLE_FRAMES:
		await _tree.physics_frame
	assert_true(headstone.is_focused(), "prompt back after closing")


func _stand_by_headstone(facing: StringName) -> Interactable:
	_map = (load(GRAVEYARD) as PackedScene).instantiate() as Map
	_tree.root.add_child(_map)
	var headstone: Interactable = _map.get_node(HEADSTONE) as Interactable
	_map.player.global_position = headstone.global_position + STAND_OFFSET
	_map.player.face(facing)
	for i: int in SETTLE_FRAMES:
		await _tree.physics_frame
	return headstone
