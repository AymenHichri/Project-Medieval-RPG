extends TestCase
## Battle effects (SovDigital effect packs): every FxSpec points at a real animation, the data
## assigns them, the presenter picks the right one per event, and a real battle spawns them.

const FX_DIR: String = "res://data/fx"
const BATTLE_SCENE: String = "res://scenes/battle/battle_scene.tscn"

var _tree: SceneTree = Engine.get_main_loop() as SceneTree


func _knight() -> Combatant:
	return Combatant.from_character(load("res://data/characters/knight.tres") as CharacterData)


func _wolf() -> Combatant:
	return Combatant.from_enemy(load("res://data/enemies/wolf.tres") as EnemyData)


func _damage(target: Combatant, source: Variant = null) -> BattleEvent:
	return BattleEvent.new(BattleEvent.Type.DAMAGE, {&"target": target, &"amount": 5, &"source": source})


func test_every_fx_spec_is_valid() -> void:
	var files: PackedStringArray = DirAccess.get_files_at(FX_DIR)
	assert_true(files.size() >= 6)
	for file: String in files:
		if not file.ends_with(".tres"):
			continue
		var spec: FxSpec = load(FX_DIR.path_join(file)) as FxSpec
		assert_not_null(spec, file)
		if spec != null:
			assert_true(spec.is_valid(), "%s: animation '%s' exists" % [file, spec.animation])


func test_data_assigns_effects() -> void:
	for id: String in ["knight", "wolf", "goblin_scout", "skeleton", "skeleton_charred"]:
		var visual: CombatantVisual = load("res://data/visuals/%s.tres" % id) as CombatantVisual
		assert_not_null(visual.hit_fx, "%s has a hit effect" % id)
	assert_not_null((load("res://data/skills/ember.tres") as SkillData).impact_fx)
	assert_not_null((load("res://data/skills/minor_heal.tres") as SkillData).impact_fx)
	assert_not_null((load("res://data/items/minor_potion.tres") as ItemData).impact_fx)


func test_choose_fx_rules() -> void:
	var knight: Combatant = _knight()
	var wolf: Combatant = _wolf()
	var wolf_look: CombatantVisual = wolf.enemy_data.visual
	var attack: BattleAction = BattleAction.attack(knight, wolf)
	assert_eq(BattlePresenter.choose_fx(attack, _damage(wolf), wolf_look), wolf_look.hit_fx, "a plain hit bleeds")
	var whirl: SkillData = load("res://data/skills/whirlwind.tres") as SkillData
	var spin: BattleAction = BattleAction.use_skill(knight, whirl, [wolf] as Array[Combatant])
	assert_eq(BattlePresenter.choose_fx(spin, _damage(wolf), wolf_look), wolf_look.hit_fx, "a physical skill too")
	var ember: SkillData = load("res://data/skills/ember.tres") as SkillData
	var cast: BattleAction = BattleAction.use_skill(knight, ember, [wolf] as Array[Combatant])
	assert_eq(BattlePresenter.choose_fx(cast, _damage(wolf), wolf_look), ember.impact_fx, "a spell's own impact")
	var burn: StatusEffectData = load("res://data/status_effects/burn.tres") as StatusEffectData
	assert_null(BattlePresenter.choose_fx(attack, _damage(wolf, burn), wolf_look), "no effect on status ticks")
	var potion: ItemData = load("res://data/items/minor_potion.tres") as ItemData
	var drink: BattleAction = BattleAction.use_item(knight, potion, [knight] as Array[Combatant])
	var heal: BattleEvent = BattleEvent.new(BattleEvent.Type.HEAL, {&"target": knight, &"amount": 40})
	assert_eq(BattlePresenter.choose_fx(drink, heal, null), potion.impact_fx, "the potion's burst")
	assert_null(BattlePresenter.choose_fx(null, _damage(wolf), wolf_look), "no action, no effect")


func test_battle_spawns_effects_on_hits() -> void:
	var battle: BattleController = (load(BATTLE_SCENE) as PackedScene).instantiate() as BattleController
	battle.instant = true
	battle.auto_battle = true
	_tree.root.add_child(battle)
	var done: Array[bool] = [false]
	battle.finished.connect(func(_r: BattleResult) -> void: done[0] = true)
	var setup: BattleSetup = BattleSetup.new()
	setup.enemies = [load("res://data/enemies/wolf.tres") as EnemyData]
	battle.start(setup, [_knight()] as Array[Combatant], BattleFixtures.rng(7), {})
	var frames: int = 0
	while not done[0] and frames < 5000:
		await _tree.process_frame
		frames += 1
	assert_true(done[0], "the battle ended")
	assert_true(battle.presenter.fx_count > 0, "hits played effects (%d)" % battle.presenter.fx_count)
	_tree.root.remove_child(battle)
	battle.free()


func test_fx_node_frees_itself() -> void:
	var spec: FxSpec = load(FX_DIR.path_join("blood_hit.tres")) as FxSpec
	var parent: Node2D = Node2D.new()
	_tree.root.add_child(parent)
	var fx: BattleFx = BattleFx.spawn(parent, spec, Vector2(100, 100), true)
	assert_not_null(fx)
	assert_true(fx.scale.x < 0.0, "mirrored")
	var frames: int = 0
	while is_instance_valid(fx) and frames < 300:
		await _tree.process_frame
		frames += 1
	assert_false(is_instance_valid(fx), "freed after one play")
	assert_null(BattleFx.spawn(parent, null, Vector2.ZERO), "no spec, no node")
	parent.queue_free()
