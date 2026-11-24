extends TestCase
## "Silence in the Graveyard" end to end (Phase 10), without the fight itself (tests/smoke/
## test_boss_trigger.gd covers it): the Elder's quest icon, accepting starts the quest, the Journal
## and Map tabs follow it, the three graves move it on (the fresh one gives the Skull Key, which
## unlocks the crypt crate), the boss's flag sends the player back, and the report pays out and
## completes it. Also the villagers' flag-dependent lines.

const VILLAGE: String = "res://scenes/world/maps/village_01.tscn"
const GRAVEYARD: String = "res://scenes/world/maps/graveyard_01.tscn"
const QUEST_ID: StringName = &"silence_in_the_graveyard"

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _map: Map
var _flags: Dictionary[StringName, Variant] = {}
var _items: Inventory
var _party: Party
var _quests: QuestLog
var _visited: Array[String] = []


func before_each() -> void:
	_flags = GameState.flags.duplicate()
	_items = GameState.inventory
	_party = GameState.party
	_quests = GameState.quests
	_visited = GameState.visited_maps.duplicate()
	GameState.flags = {}
	GameState.inventory = Inventory.new()
	GameState.party = Party.new()
	GameState.quests = QuestLog.new()
	GameState.visited_maps = []
	GameState.ensure_party()


func after_each() -> void:
	DialogueTestUtil.close_dialogue()
	_free_map()
	if _tree.paused:
		_tree.paused = false
	AudioManager.music.stop(0.0)
	GameState.flags = _flags
	GameState.inventory = _items
	GameState.party = _party
	GameState.quests = _quests
	GameState.visited_maps = _visited
	GameState.current_map = ""


func _open(path: String) -> void:
	_free_map()
	_map = (load(path) as PackedScene).instantiate() as Map
	_tree.root.add_child(_map)
	_map.place_player(&"start" if path == VILLAGE else &"from_village")
	GameState.current_map = path
	await _tree.process_frame


func _free_map() -> void:
	if is_instance_valid(_map):
		_tree.root.remove_child(_map)
		_map.free()
	_map = null


func _node(path: String) -> Node:
	return _map.get_node_or_null(NodePath(path))


## Interacts with `area`, picking choice `choice` on choice lines, until the dialogue closes.
func _use(area: Interactable, choice: int = 0) -> void:
	area.interact(_map.player)
	var guard: int = 0
	while DialogueManager.is_active and guard < 200:
		guard += 1
		if DialogueManager.runner != null and DialogueManager.runner.has_choices():
			DialogueManager.choose(choice)
		else:
			DialogueManager.advance()
	await _tree.process_frame


## The text of every line `dialogue_id` plays now (closing it as it goes).
func _lines_of(dialogue_id: StringName) -> PackedStringArray:
	var texts: PackedStringArray = []
	DialogueManager.start(dialogue_id)
	var guard: int = 0
	while DialogueManager.is_active and guard < 50:
		guard += 1
		texts.append(DialogueManager.runner.text())
		if DialogueManager.runner.has_choices():
			DialogueManager.choose(0)
		else:
			DialogueManager.advance()
	return texts


func _pause_menu() -> PauseMenu:
	_map.open_pause_menu()
	return _map.pause_menu


func test_the_example_quest_end_to_end() -> void:
	await _open(VILLAGE)
	var elder: Npc = _node("World/Elder") as Npc
	assert_eq(elder.shown_icon(), Interactable.QUEST_ICON, "the Elder has a quest to give")
	await _use(elder, 0)
	assert_true(GameState.quests.is_active(QUEST_ID), "accepting starts the quest")
	assert_null(elder.shown_icon(), "nothing to give or hear while the graves wait")
	assert_eq(_map.hud.notice.visible, true)
	assert_eq(_map.hud.get_node("%NoticeText").get(&"text"), "New quest: Silence in the Graveyard")

	var menu: PauseMenu = _pause_menu()
	menu.show_tab(PauseMenu.TAB_JOURNAL)
	assert_true(menu.journal_page.visible)
	assert_eq(menu.journal_page.quest_buttons().size(), 1)
	assert_true(menu.journal_page.page_text().contains("Graves searched: 0/3"))
	menu.show_tab(PauseMenu.TAB_MAP)
	assert_eq(menu.map_page.shown_path, VILLAGE)
	assert_true(MapAtlas.Kind.PLAYER in menu.map_page.shown_kinds(), "you are here")
	assert_true(MapAtlas.Kind.EXIT in menu.map_page.shown_kinds())
	assert_true(MapAtlas.Kind.REST in menu.map_page.shown_kinds(), "the well")
	assert_false(MapAtlas.Kind.QUEST in menu.map_page.shown_kinds(), "nothing to do in the village yet")
	menu.close()

	await _open(GRAVEYARD)
	var chest: Chest = _node("World/ChestCrypt") as Chest
	assert_eq(chest.shown_icon(), Interactable.LOCKED_ICON, "the crypt crate is locked")
	menu = _pause_menu()
	menu.show_tab(PauseMenu.TAB_MAP)
	assert_eq(menu.map_page.shown_kinds().count(MapAtlas.Kind.QUEST), 3, "three graves to search")
	assert_false(MapAtlas.Kind.BOSS in menu.map_page.shown_kinds(), "the door comes later")
	assert_eq(menu.map_page.map_buttons().size(), 2, "both visited maps listed")
	menu.close()

	await _use(_node("World/HeadstoneWeathered/Interactable") as Interactable)
	await _use(_node("World/Grave12/Interactable") as Interactable)
	assert_eq(GameState.quests.stage_index(QUEST_ID), 0)
	assert_true(GameState.quests.stage_text(QUEST_ID, GameState.flags).ends_with("2/3"))
	await _use(_node("World/Grave23/Interactable") as Interactable)
	assert_eq(GameState.quests.stage_index(QUEST_ID), 1, "all three graves searched")
	assert_eq(GameState.item_count(&"skull_key"), 1, "the fresh grave's key")
	assert_null(chest.shown_icon(), "the key unlocks the crate")
	assert_eq(_lines_of(&"examine_headstone"), PackedStringArray(["You have already searched this grave."]))
	menu = _pause_menu()
	menu.show_tab(PauseMenu.TAB_MAP)
	assert_eq(menu.map_page.shown_kinds().count(MapAtlas.Kind.QUEST), 0)
	assert_true(MapAtlas.Kind.BOSS in menu.map_page.shown_kinds(), "now the crypt door")
	menu.close()
	var door: BossTrigger = _node("World/CryptDoor") as BossTrigger
	assert_true(door.is_available())

	GameState.set_flag(&"blade_assassin_defeated")
	assert_true(GameState.quests.current_stage(QUEST_ID).turn_in)
	await _open(VILLAGE)
	elder = _node("World/Elder") as Npc
	assert_eq(elder.shown_icon(), Interactable.QUEST_ICON, "the Elder waits for the report")
	var gold: int = GameState.gold
	await _use(elder)
	assert_true(GameState.quests.is_completed(QUEST_ID))
	assert_eq(GameState.gold, gold + 300, "the village's reward")
	assert_eq(GameState.item_count(&"soul_gem"), 1)
	assert_null(elder.shown_icon())
	menu = _pause_menu()
	menu.show_tab(PauseMenu.TAB_JOURNAL)
	assert_true(menu.journal_page.page_text().contains("graveyard is quiet"), "completed text")
	assert_true(menu.journal_page.page_text().contains(JournalPage.DONE_MARK), "stages done")
	menu.close()
	assert_eq(_lines_of(&"elder_intro")[0].left(20), "Folk are carving the", "the Elder's last word")


func test_graves_are_plain_before_the_quest() -> void:
	await _open(GRAVEYARD)
	await _use(_node("World/Grave12/Interactable") as Interactable)
	assert_false(GameState.get_flag(&"grave_soldier_searched") as bool)
	var door: BossTrigger = _node("World/CryptDoor") as BossTrigger
	assert_eq(door.shown_icon(), Interactable.LOCKED_ICON)
	GameState.set_flag(&"hexblade_joined")
	assert_eq(_lines_of(&"crypt_door_sealed").size(), 2)
	assert_true(_lines_of(&"crypt_door_sealed")[1].contains("ward feeds on the graves"), "the Hexblade's hint")


func test_villagers_follow_the_quest() -> void:
	var agreed: Array[String] = ["elder_agreed"]
	var done: Array[String] = ["elder_agreed", "blade_assassin_defeated"]
	for spec: Array in [
		[&"hollis_talk", [], "Forty years"], [&"hollis_talk", agreed, "So Maren sent you"],
		[&"hollis_talk", done, "Slept the whole night"],
		[&"ilse_talk", [], "The well was blessed"], [&"ilse_talk", agreed, "Take holy water"],
		[&"ilse_talk", done, "tastes sweeter"],
		[&"brenna_talk", [], "My Aldric"], [&"brenna_talk", done, "I remembered his voice"],
	]:
		GameState.flags = {}
		for flag: String in spec[1] as Array:
			GameState.set_flag(StringName(flag))
		var first: String = _lines_of(spec[0] as StringName)[0]
		assert_true(first.contains(spec[2] as String), "%s with %s: %s" % [spec[0], spec[1], first])
		AudioManager.music.stop(0.0)


func test_new_villagers_stand_in_the_village() -> void:
	await _open(VILLAGE)
	for npc_name: String in ["Hollis", "Ilse", "Brenna"]:
		var npc: Npc = _node("World/" + npc_name) as Npc
		assert_not_null(npc, npc_name)
		if npc != null:
			assert_not_null(npc.sprite.sprite_frames)
	var ilse: Npc = _node("World/Ilse") as Npc
	assert_true(ilse.sprite.sprite_frames.resource_path.contains("gold"), "Ilse's own look")
