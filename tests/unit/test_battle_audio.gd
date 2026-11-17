extends TestCase
## Battle sounds (PROJECT_PLAN.md Phase 7A): `BattlePresenter.choose_sfx` follows the FX rules
## (skill/item first, then the target's hit sound for physical blows; crit and miss override;
## nothing on status ticks), and a real battle starts sounds on its hits.
## In-memory sets only: the slice has no combat sound files yet.

const BATTLE_SCENE: String = "res://scenes/battle/battle_scene.tscn"

var _tree: SceneTree = Engine.get_main_loop() as SceneTree


static func sfx_set() -> SfxSet:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var data: PackedByteArray = PackedByteArray()
	data.resize(800)
	data.fill(0)
	wav.data = data
	var sfx: SfxSet = SfxSet.new()
	sfx.streams = [wav]
	return sfx


func _knight() -> Combatant:
	return Combatant.from_character(load("res://data/characters/knight.tres") as CharacterData)


func _wolf() -> Combatant:
	return Combatant.from_enemy(load("res://data/enemies/wolf.tres") as EnemyData)


func _damage(target: Combatant, extra: Dictionary = {}) -> BattleEvent:
	var data: Dictionary = {&"target": target, &"amount": 5, &"critical": false, &"immune": false, &"source": null}
	data.merge(extra, true)
	return BattleEvent.new(BattleEvent.Type.DAMAGE, data)


func test_choose_sfx_rules() -> void:
	var knight: Combatant = _knight()
	var wolf: Combatant = _wolf()
	var look: CombatantVisual = CombatantVisual.new()
	look.hit_sfx = sfx_set()
	var shared: Dictionary[StringName, SfxSet] = {&"crit": sfx_set(), &"miss": sfx_set()}
	var attack: BattleAction = BattleAction.attack(knight, wolf)
	assert_eq(BattlePresenter.choose_sfx(attack, _damage(wolf), look, shared), look.hit_sfx, "a blow uses the target's hit sound")
	assert_eq(BattlePresenter.choose_sfx(attack, _damage(wolf, {&"critical": true}), look, shared), shared[&"crit"], "crit overrides")
	assert_eq(BattlePresenter.choose_sfx(attack, _damage(wolf, {&"amount": 0}), look, shared), shared[&"miss"], "no damage = miss")
	assert_eq(BattlePresenter.choose_sfx(attack, _damage(wolf, {&"immune": true}), look, shared), shared[&"miss"], "immune = miss")
	assert_eq(BattlePresenter.choose_sfx(attack, _damage(wolf, {&"critical": true}), look), look.hit_sfx, "no shared crit set: the hit sound")

	var ember: SkillData = (load("res://data/skills/ember.tres") as SkillData).duplicate() as SkillData
	ember.impact_sfx = sfx_set()
	var cast: BattleAction = BattleAction.use_skill(knight, ember, [wolf] as Array[Combatant])
	assert_eq(BattlePresenter.choose_sfx(cast, _damage(wolf), look, shared), ember.impact_sfx, "a spell's own impact sound")
	ember.impact_sfx = null
	assert_null(BattlePresenter.choose_sfx(cast, _damage(wolf), look, shared), "a spell without one is not a physical hit")

	var burn: StatusEffectData = load("res://data/status_effects/burn.tres") as StatusEffectData
	assert_null(BattlePresenter.choose_sfx(attack, _damage(wolf, {&"source": burn}), look, shared), "status ticks are silent")
	assert_null(BattlePresenter.choose_sfx(null, _damage(wolf), look, shared), "no action, no sound")

	var potion: ItemData = (load("res://data/items/minor_potion.tres") as ItemData).duplicate() as ItemData
	potion.impact_sfx = sfx_set()
	var drink: BattleAction = BattleAction.use_item(knight, potion, [knight] as Array[Combatant])
	var heal: BattleEvent = BattleEvent.new(BattleEvent.Type.HEAL, {&"target": knight, &"amount": 40})
	assert_eq(BattlePresenter.choose_sfx(drink, heal, null, shared), potion.impact_sfx, "the potion's sound")


func test_battle_plays_sounds_on_hits_and_casts() -> void:
	var wolf_look: CombatantVisual = (load("res://data/enemies/wolf.tres") as EnemyData).visual
	var knight_look: CombatantVisual = (load("res://data/characters/knight.tres") as CharacterData).visual
	var saved: Array = [wolf_look.hit_sfx, wolf_look.cry_sfx, knight_look.attack_sfx]
	wolf_look.hit_sfx = sfx_set()
	wolf_look.cry_sfx = sfx_set()
	knight_look.attack_sfx = sfx_set()
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
	wolf_look.hit_sfx = saved[0]
	wolf_look.cry_sfx = saved[1]
	knight_look.attack_sfx = saved[2]
	assert_true(done[0], "the battle ended")
	# At least the wolf's cry, one swing and one hit.
	assert_true(battle.presenter.sfx_count >= 3, "sounds started (%d)" % battle.presenter.sfx_count)
	_tree.root.remove_child(battle)
	battle.free()


func test_no_sounds_without_sets() -> void:
	var presenter: BattlePresenter = BattlePresenter.new()
	presenter.instant = true
	presenter._play_sfx(null, null)
	presenter._play_sfx(SfxSet.new(), null)
	assert_eq(presenter.sfx_count, 0, "empty sets are not counted")
	presenter._play_sfx(sfx_set(), null)
	assert_eq(presenter.sfx_count, 1)
	presenter.free()
