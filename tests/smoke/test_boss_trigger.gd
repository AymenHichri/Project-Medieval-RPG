extends TestCase
## The crypt door BossTrigger in graveyard_01 (Phase 10): sealed (lock icon) without the three grave
## flags; with them it fires once into a no-flee boss battle; winning sets `defeated_flag` (through
## SceneManager.end_battle); afterwards it never fires again.

const GRAVEYARD: String = "res://scenes/world/maps/graveyard_01.tscn"
const GRAVE_FLAGS: Array[StringName] = [&"grave_widow_searched", &"grave_soldier_searched", &"grave_fresh_searched"]
const MAX_FRAMES: int = 6000

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _flags: Dictionary[StringName, Variant] = {}
var _items: Inventory
var _party: Party
var _quests: QuestLog


func before_each() -> void:
	SceneManager.instant_transitions = true
	SceneManager.instant_battles = true
	SceneManager.auto_battles = true
	SceneManager.battle_rng = BattleFixtures.rng(21)
	_flags = GameState.flags.duplicate()
	_items = GameState.inventory
	_party = GameState.party
	_quests = GameState.quests
	GameState.flags = {}
	GameState.inventory = Inventory.new()
	GameState.quests = QuestLog.new()
	GameState.party = Party.new()


func after_each() -> void:
	DialogueTestUtil.close_dialogue()
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
	GameState.flags = _flags
	GameState.inventory = _items
	GameState.party = _party
	GameState.quests = _quests


## A party that wins on auto-attack: a level 30 Knight.
func _strong_party() -> void:
	GameState.party.add(PartyMember.create(load("res://data/characters/knight.tres") as CharacterData, 30, BattleFixtures.rng(2)))


func _graveyard() -> Map:
	await SceneManager.change_map(GRAVEYARD, &"from_village")
	await _tree.process_frame
	return _tree.current_scene as Map


func _door(map: Map) -> BossTrigger:
	return map.get_node_or_null(^"World/CryptDoor") as BossTrigger


## Interacts with the door, answering every line, and waits until a started battle is over.
func _use_door(door: BossTrigger, map: Map) -> void:
	door.interact(map.player)
	DialogueTestUtil.close_dialogue()
	await _tree.process_frame
	var frames: int = 0
	while (SceneManager.in_battle or SceneManager.is_transitioning) and frames < MAX_FRAMES:
		frames += 1
		await _tree.process_frame
	DialogueTestUtil.close_dialogue()


func test_sealed_without_the_grave_flags() -> void:
	_strong_party()
	var map: Map = await _graveyard()
	var door: BossTrigger = _door(map)
	assert_not_null(door, "the crypt door is in the graveyard")
	if door == null:
		return
	assert_eq(door.shown_icon(), Interactable.LOCKED_ICON, "locked icon")
	GameState.set_flag(GRAVE_FLAGS[0])
	GameState.set_flag(GRAVE_FLAGS[1])
	assert_false(door.is_available(), "two of three graves are not enough")
	await _use_door(door, map)
	assert_eq(door.fights_started, 0, "no fight")
	assert_false(SceneManager.in_battle)
	assert_false(door.start_fight())
	assert_false(GameState.get_flag(&"blade_assassin_defeated") as bool)


func test_fires_once_and_victory_sets_the_defeated_flag() -> void:
	_strong_party()
	var map: Map = await _graveyard()
	var door: BossTrigger = _door(map)
	for flag: StringName in GRAVE_FLAGS:
		GameState.set_flag(flag)
	assert_null(door.shown_icon(), "unsealed")
	var setups: Array[BattleSetup] = []
	var results: Array[BattleResult] = []
	var on_start: Callable = func(s: BattleSetup) -> void: setups.append(s)
	var on_end: Callable = func(r: BattleResult) -> void: results.append(r)
	SceneManager.battle_started.connect(on_start)
	SceneManager.battle_ended.connect(on_end)
	await _use_door(door, map)
	SceneManager.battle_started.disconnect(on_start)
	SceneManager.battle_ended.disconnect(on_end)
	assert_eq(door.fights_started, 1)
	assert_eq(setups.size(), 1, "one battle")
	if setups.is_empty() or results.is_empty():
		return
	assert_false(setups[0].can_flee, "no flee")
	assert_true(setups[0].is_boss)
	assert_eq(setups[0].enemies[0].id, &"blade_assassin")
	assert_true(results[0].is_victory(), "the level 30 Knight wins")
	assert_true(GameState.get_flag(&"blade_assassin_defeated") as bool, "defeated_flag set on victory")
	assert_eq(_tree.current_scene, map, "back on the same map")
	# Never again.
	await _use_door(door, map)
	assert_eq(door.fights_started, 1, "never fires again")
	assert_false(door.start_fight())
	assert_null(door.shown_icon())


func test_defeat_does_not_set_the_flag() -> void:
	GameState.party.add(PartyMember.create(load("res://data/characters/knight.tres") as CharacterData))
	var map: Map = await _graveyard()
	var door: BossTrigger = _door(map)
	for flag: StringName in GRAVE_FLAGS:
		GameState.set_flag(flag)
	await _use_door(door, map)
	assert_false(GameState.get_flag(&"blade_assassin_defeated") as bool, "a lone level 1 Knight loses")
	assert_true(_tree.current_scene is GameOverScreen, "Game Over")
	assert_eq(AudioManager.music.stack_depth(), 0, "no map music left waiting to return")
