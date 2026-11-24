extends TestCase
## Recruiting (Phase 8): the Warden in village_01 and the Hexblade in graveyard_01 join after their
## dialogue when the player accepts (flag set, NPC leaves, gone on the next visit), stay when the
## player declines; the pause menu's Party tab then shows all three members.

const VILLAGE: String = "res://scenes/world/maps/village_01.tscn"
const GRAVEYARD: String = "res://scenes/world/maps/graveyard_01.tscn"

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _map: Map
var _flags: Dictionary[StringName, Variant] = {}
var _items: Inventory
var _party: Party


func before_each() -> void:
	_flags = GameState.flags.duplicate()
	_items = GameState.inventory
	GameState.inventory = Inventory.new()
	_party = GameState.party
	GameState.flags = {}
	GameState.party = Party.new()
	GameState.ensure_party()


func after_each() -> void:
	DialogueTestUtil.close_dialogue()
	_free_map()
	if _tree.paused:
		_tree.paused = false
	GameState.flags = _flags
	GameState.inventory = _items
	GameState.party = _party


## Opens a map and lets it settle one frame (a recruit who already joined frees itself then).
func _open(path: String) -> void:
	_free_map()
	_map = (load(path) as PackedScene).instantiate() as Map
	_tree.root.add_child(_map)
	_map.place_player(&"start" if path == VILLAGE else &"from_village")
	await _tree.process_frame


func _free_map() -> void:
	if is_instance_valid(_map):
		_tree.root.remove_child(_map)
		_map.free()
	_map = null


func _recruit_npc(node_name: String) -> RecruitNpc:
	return _map.get_node_or_null(NodePath("World/" + node_name)) as RecruitNpc


## Talks to `npc`, answering the choice with `choice`, and waits for it to finish.
func _talk(npc: RecruitNpc, choice: int) -> void:
	var done: Array[bool] = [false]
	var talk: Callable = func() -> void:
		await npc.interact(_map.player)
		done[0] = true
	talk.call()
	var guard: int = 0
	while DialogueManager.is_active and guard < 200:
		guard += 1
		if DialogueManager.runner != null and DialogueManager.runner.has_choices():
			DialogueManager.choose(choice)
		else:
			DialogueManager.advance()
	for i: int in 4:
		await _tree.process_frame
	assert_true(done[0], "the talk finished")


func test_warden_waits_in_the_village_with_its_own_look() -> void:
	await _open(VILLAGE)
	var warden: RecruitNpc = _recruit_npc("Warden")
	assert_not_null(warden)
	var data: CharacterData = load("res://data/characters/warden.tres") as CharacterData
	assert_eq(warden.character, data)
	assert_eq(warden.sprite.sprite_frames, data.visual.sprite_frames, "the black recolour")
	assert_eq(warden.portrait, data.portrait, "portrait from the character")


func test_declining_keeps_the_warden_waiting() -> void:
	await _open(VILLAGE)
	var warden: RecruitNpc = _recruit_npc("Warden")
	await _talk(warden, 1)
	assert_eq(GameState.party.size(), 1, "nobody joined")
	assert_true(GameState.get_flag(&"met_warden") as bool)
	assert_false(GameState.get_flag(&"warden_joined") as bool)
	assert_true(is_instance_valid(warden) and warden.is_inside_tree(), "still there to ask again")


func test_accepting_adds_the_warden_and_it_leaves() -> void:
	await _open(VILLAGE)
	var warden: RecruitNpc = _recruit_npc("Warden")
	var joined: Array[PartyMember] = []
	warden.recruited.connect(func(m: PartyMember) -> void: joined.append(m))
	await _talk(warden, 0)
	assert_eq(GameState.party.size(), 2)
	assert_eq(GameState.party.members[1].data.id, &"warden", "joins behind the Knight")
	assert_eq(joined.size(), 1)
	assert_true(GameState.get_flag(&"warden_joined") as bool)
	# The fade lasts RecruitNpc.LEAVE_SECONDS of real time: allow plenty of (fast headless) frames.
	for i: int in 600:
		await _tree.process_frame
		if not is_instance_valid(warden):
			break
	assert_false(is_instance_valid(warden), "the NPC left the map")
	await _open(VILLAGE)
	assert_null(_recruit_npc("Warden"), "not there on the next visit")


func test_hexblade_joins_in_the_graveyard_with_holy_water() -> void:
	await _open(GRAVEYARD)
	var hexblade: RecruitNpc = _recruit_npc("Hexblade")
	assert_not_null(hexblade)
	await _talk(hexblade, 0)
	assert_true(GameState.party.has_character(&"hexblade"))
	assert_eq(GameState.item_count(&"holy_water"), 2, "the Hexblade's gift")


func test_party_tab_shows_every_member() -> void:
	GameState.recruit(load("res://data/characters/warden.tres") as CharacterData)
	GameState.recruit(load("res://data/characters/hexblade.tres") as CharacterData)
	await _open(VILLAGE)
	assert_true(_map.open_pause_menu())
	var page: StatusPage = _map.pause_menu.status_page
	assert_eq(page.member_buttons().size(), 3)
	assert_eq(_map.pause_menu.summary_text(), "Knight Lv 1, Warden Lv 1, Hexblade Lv 1")
	var knight: PartyMember = GameState.party.leader()
	assert_eq(page.shown, knight)
	assert_eq(page.portrait(), knight.data.portrait, "framed Knight portrait")
	assert_eq(page.stat_text(&"attack"), str(knight.stats.attack))
	page.show_member(GameState.party.members[2])
	var hexblade: PartyMember = GameState.party.members[2]
	assert_eq(page.stat_text(&"magic"), str(hexblade.stats.magic), "the Hexblade's page")
	assert_eq(page.portrait(), hexblade.data.portrait)
	_map.pause_menu.close()
