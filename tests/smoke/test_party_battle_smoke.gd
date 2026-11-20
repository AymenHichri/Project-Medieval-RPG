extends TestCase
## battle_scene.tscn with a 3-member party (Phase 8): three battlers and HUD rows, the command menu
## walks member by member, cancel steps back to the previous member, Guard and Purify go through
## the real menus, and status badges reach the HUD.

const BATTLE_SCENE: String = "res://scenes/battle/battle_scene.tscn"
const MAX_FRAMES: int = 5000

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _battle: BattleController
var _result: BattleResult


func after_each() -> void:
	if is_instance_valid(_battle):
		_battle.get_parent().remove_child(_battle)
		_battle.free()
	_battle = null
	_result = null


func _party() -> Array[Combatant]:
	var out: Array[Combatant] = []
	for id: String in ["knight", "warden", "hexblade"]:
		out.append(PartyMember.create(load("res://data/characters/%s.tres" % id) as CharacterData).combatant)
	return out


func _start(ids: Array[String], party: Array[Combatant], auto: bool, seed_value: int = 7) -> void:
	var setup: BattleSetup = BattleSetup.new()
	for id: String in ids:
		setup.enemies.append(load("res://data/enemies/%s.tres" % id) as EnemyData)
	_battle = (load(BATTLE_SCENE) as PackedScene).instantiate() as BattleController
	_battle.instant = true
	_battle.auto_battle = auto
	_tree.root.add_child(_battle)
	_battle.finished.connect(func(r: BattleResult) -> void: _result = r)
	_battle.start(setup, party, BattleFixtures.rng(seed_value))


func _skill(id: StringName) -> SkillData:
	return load("res://data/skills/%s.tres" % id) as SkillData


## Picks `skill` from the Skills or Magic list of the member whose menu is open.
func _choose_skill(skill: SkillData) -> void:
	var menu: MenuList = _battle.command_menu.commands()
	menu.select(menu.index_of(&"skills" if skill.category == SkillData.Category.SKILL else &"magic"))
	menu.press(&"accept")
	var list: MenuList = _battle.command_menu.sub_menu()
	list.select(list.index_of(skill))
	list.press(&"accept")


func test_three_battlers_and_hud_rows() -> void:
	_start(["wolf", "wolf"], _party(), false)
	assert_eq(_battle.sprites.size(), 5)
	for member: Combatant in _battle.engine.party:
		assert_not_null(_battle.sprite_of(member), "%s has a battler" % member.display_name)
		assert_not_null(_battle.hud.hp_bar(member), "%s has a HUD row" % member.display_name)
	var a: Vector2 = _battle.sprite_of(_battle.engine.party[0]).position
	var b: Vector2 = _battle.sprite_of(_battle.engine.party[1]).position
	assert_ne(a, b, "members stand in different slots")


func test_commands_walk_members_and_cancel_steps_back() -> void:
	_start(["wolf"], _party(), false)
	var menu: MenuList = _battle.command_menu.commands()
	var party: Array[Combatant] = _battle.engine.party
	assert_false(menu.allow_cancel, "the first member cannot go back")
	menu.press(&"accept")  # Knight: Attack
	_battle.target_selector.press(&"accept")
	assert_true(menu.is_active())
	assert_true(menu.allow_cancel, "the Warden's menu can go back")
	assert_eq((_battle.command_menu.get_node(^"%MemberName") as Label).text, party[1].display_name)
	menu.press(&"cancel")
	assert_eq((_battle.command_menu.get_node(^"%MemberName") as Label).text, party[0].display_name, "back to the Knight")
	assert_eq(_battle.engine.round_number, 0)
	for i: int in party.size():
		menu.select(menu.index_of(&"defend"))
		menu.press(&"accept")
	await _tree.process_frame
	assert_eq(_battle.engine.round_number, 1, "three commands start the round")


func test_guard_through_the_menus_covers_the_knight() -> void:
	_start(["wolf"], _party(), false)
	var party: Array[Combatant] = _battle.engine.party
	var menu: MenuList = _battle.command_menu.commands()
	menu.select(menu.index_of(&"defend"))
	menu.press(&"accept")  # Knight defends
	_choose_skill(_skill(&"guard"))
	assert_true(_battle.target_selector.is_active(), "Guard asks which ally")
	_battle.target_selector.press(&"move_left")
	assert_eq(_battle.target_selector.current(), party[0])
	_battle.target_selector.press(&"accept")
	menu.select(menu.index_of(&"defend"))
	menu.press(&"accept")  # Hexblade defends
	var knight_hp: int = party[0].hp
	await _tree.process_frame
	assert_eq(_battle.engine.round_number, 1)
	assert_eq(party[0].hp, knight_hp, "the wolf's single blow went to the Warden")


func test_status_badges_and_purify() -> void:
	var party: Array[Combatant] = _party()
	var bleed: StatusEffectData = load("res://data/status_effects/bleed.tres") as StatusEffectData
	StatusEffects.apply(party[0], bleed, BattleFixtures.rng(1))
	_start(["wolf"], party, false)
	assert_eq(_battle.hud.status_count(party[0]), 1, "the Bleed icon is on the Knight's row")
	var menu: MenuList = _battle.command_menu.commands()
	menu.select(menu.index_of(&"defend"))
	menu.press(&"accept")
	_choose_skill(_skill(&"purify"))
	_battle.target_selector.press(&"move_left")
	_battle.target_selector.press(&"accept")
	menu.select(menu.index_of(&"defend"))
	menu.press(&"accept")
	await _tree.process_frame
	assert_false(party[0].has_status(&"bleed"), "Purify cured the Bleed")
	assert_eq(_battle.hud.status_count(party[0]), 0, "and the icon is gone")


func test_three_member_auto_battle_reaches_the_results() -> void:
	_start(["wolf", "goblin_scout", "skeleton"], _party(), true, 21)
	var frames: int = 0
	while _result == null and frames < MAX_FRAMES:
		await _tree.process_frame
		frames += 1
	assert_not_null(_result, "the battle ended")
	assert_true(_result.is_victory())
	assert_true(_battle.results_screen.visible)
