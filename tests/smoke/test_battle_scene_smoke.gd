extends TestCase
## battle_scene.tscn runs headless in instant mode: auto-battles reach their end, and the real
## command menu → target selector flow drives rounds (Attack, Whirlwind, Defend, cancel).

const BATTLE_SCENE: String = "res://scenes/battle/battle_scene.tscn"
## Frame budget for a whole battle (a frame count, not wall-clock time).
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


func _knight(hp: int = -1) -> Combatant:
	var data: CharacterData = load("res://data/characters/knight.tres") as CharacterData
	return Combatant.from_character(data, null, [], hp)


func _enemy(id: String) -> EnemyData:
	return load("res://data/enemies/%s.tres" % id) as EnemyData


func _setup(ids: Array[String]) -> BattleSetup:
	var setup: BattleSetup = BattleSetup.new()
	for id: String in ids:
		setup.enemies.append(_enemy(id))
	return setup


func _start(ids: Array[String], party: Array[Combatant], auto: bool, seed_value: int = 7) -> void:
	_battle = (load(BATTLE_SCENE) as PackedScene).instantiate() as BattleController
	_battle.instant = true
	_battle.auto_battle = auto
	_tree.root.add_child(_battle)
	_battle.finished.connect(func(r: BattleResult) -> void: _result = r)
	var potion: ItemData = load("res://data/items/minor_potion.tres") as ItemData
	var bag: Dictionary[ItemData, int] = {potion: 2}
	_battle.start(_setup(ids), party, BattleFixtures.rng(seed_value), bag)


## Runs frames until the battle ends or the budget is spent. Returns the frames used.
func _run_to_end() -> int:
	var frames: int = 0
	while _result == null and frames < MAX_FRAMES:
		await _tree.process_frame
		frames += 1
	return frames


func test_one_vs_one_auto_battle_reaches_victory() -> void:
	_start(["wolf"], [_knight()], true)
	var frames: int = await _run_to_end()
	assert_not_null(_result, "finished within %d frames" % MAX_FRAMES)
	if _result == null:
		return
	assert_true(frames < MAX_FRAMES)
	assert_eq(_result.outcome, BattleEngine.Outcome.VICTORY)
	var wolf: EnemyData = _enemy("wolf")
	assert_eq(_result.xp, wolf.xp, "rewards = the wolf's xp")
	assert_eq(_result.gold, wolf.gold, "rewards = the wolf's gold")
	assert_true(_battle.results_screen.visible, "victory shows the results screen")
	assert_eq(_battle.results_screen.experience_text(), "Experience  +%d" % wolf.xp)


func test_scene_builds_battlers_hud_and_background() -> void:
	_start(["wolf", "goblin_scout"], [_knight()], true)
	assert_eq(_battle.sprites.size(), 3)
	var knight: BattleSprite = _battle.sprite_of(_battle.engine.party[0])
	var wolf: BattleSprite = _battle.sprite_of(_battle.engine.enemies[0])
	assert_true(knight.position.x < wolf.position.x, "party on the left, enemies on the right")
	assert_eq(knight.facing_sign(), 1.0, "party faces right")
	assert_eq(wolf.facing_sign(), -1.0, "enemies face left")
	assert_false(knight.hp_bar.visible, "party HP lives in the HUD")
	assert_true(wolf.hp_bar.visible, "enemies show an HP bar")
	assert_eq(wolf.hp_bar.style, StatBar.Style.ENEMY_HP)
	assert_not_null(_battle.hud.hp_bar(_battle.engine.party[0]), "HUD row for the Knight")
	assert_eq(_battle.get_node(^"%Background").get_child_count(), 1, "default background added")
	await _run_to_end()


func test_weak_knight_is_defeated_without_results_screen() -> void:
	var bones: Array[String] = ["skeleton", "skeleton", "skeleton"]
	_start(bones, [_knight(1)], true)
	await _run_to_end()
	assert_not_null(_result)
	if _result != null:
		assert_eq(_result.outcome, BattleEngine.Outcome.DEFEAT)
		assert_false(_battle.results_screen.visible)
		assert_true(_battle.sprite_of(_battle.engine.party[0]).is_fallen(), "the Knight lies fallen")


func test_menu_attack_round() -> void:
	_start(["wolf"], [_knight()], false)
	var menu: MenuList = _battle.command_menu.commands()
	assert_true(menu.is_active(), "the command menu waits for the Knight")
	assert_eq(menu.selected_value(), &"attack", "Attack is preselected")
	menu.press(&"accept")
	assert_true(_battle.target_selector.is_active(), "Attack asks for a target")
	assert_eq(_battle.target_selector.current(), _battle.engine.enemies[0])
	_battle.target_selector.press(&"accept")
	await _tree.process_frame
	assert_eq(_battle.engine.round_number, 1, "the round was played")
	var wolf: Combatant = _battle.engine.enemies[0]
	assert_true(wolf.hp < wolf.max_hp(), "the wolf took damage")
	assert_eq(_battle.presenter.shown_hp(wolf), wolf.hp, "shown HP caught up with the engine")
	assert_eq(_battle.sprite_of(wolf).hp_bar.value, wolf.hp, "enemy bar shows its HP")


func test_cancel_from_target_returns_to_commands() -> void:
	_start(["wolf"], [_knight()], false)
	var menu: MenuList = _battle.command_menu.commands()
	menu.press(&"accept")
	_battle.target_selector.press(&"cancel")
	assert_false(_battle.target_selector.is_active())
	assert_true(menu.is_active(), "back on the command list")
	assert_eq(_battle.engine.round_number, 0, "no round started")


func test_whirlwind_hits_every_enemy_and_spends_mp() -> void:
	_start(["wolf", "goblin_scout"], [_knight()], false)
	var knight: Combatant = _battle.engine.party[0]
	var menu: MenuList = _battle.command_menu.commands()
	menu.select(menu.index_of(&"skills"))
	menu.press(&"accept")
	var skills: MenuList = _battle.command_menu.sub_menu()
	assert_true(skills.is_active(), "the Skills list opens")
	var whirlwind: SkillData = load("res://data/skills/whirlwind.tres") as SkillData
	skills.select(skills.index_of(whirlwind))
	skills.press(&"accept")
	assert_true(_battle.target_selector.is_active(), "an ALL skill still confirms its targets")
	_battle.target_selector.press(&"accept")
	await _tree.process_frame
	assert_eq(knight.mp, knight.max_mp() - whirlwind.mp_cost, "Whirlwind's MP was spent")
	assert_eq(_battle.hud.mp_bar(knight).value, knight.mp, "the HUD shows the MP drop")
	for enemy: Combatant in _battle.engine.enemies:
		assert_true(enemy.hp < enemy.max_hp(), "%s was hit" % enemy.display_name)


func test_unaffordable_skill_is_disabled() -> void:
	var knight: Combatant = _knight()
	knight.mp = 5
	_start(["wolf"], [knight], false)
	var menu: MenuList = _battle.command_menu.commands()
	menu.select(menu.index_of(&"skills"))
	menu.press(&"accept")
	var skills: MenuList = _battle.command_menu.sub_menu()
	var whirlwind: SkillData = load("res://data/skills/whirlwind.tres") as SkillData
	var index: int = skills.index_of(whirlwind)
	assert_true(index >= 0, "Whirlwind is listed")
	assert_false(skills.is_enabled(index), "6 MP Whirlwind is greyed out with 5 MP")
	skills.select(index)
	skills.press(&"accept")
	assert_true(skills.is_active(), "a disabled skill cannot be chosen")
	skills.press(&"cancel")
	assert_true(menu.is_active(), "cancel goes back to the commands")


func test_defend_round() -> void:
	_start(["wolf"], [_knight()], false)
	var menu: MenuList = _battle.command_menu.commands()
	menu.select(menu.index_of(&"defend"))
	menu.press(&"accept")
	await _tree.process_frame
	assert_eq(_battle.engine.round_number, 1, "Defend needs no target")
	assert_false(_battle.sprite_of(_battle.engine.party[0]).is_defending(), "the stance ends with the round")


func test_first_member_cannot_cancel() -> void:
	_start(["wolf"], [_knight()], false)
	var menu: MenuList = _battle.command_menu.commands()
	menu.press(&"cancel")
	assert_true(menu.is_active(), "nobody to go back to")
