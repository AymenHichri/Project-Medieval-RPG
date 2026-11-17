extends TestCase
## The generated res://data battle files load and follow the plan's rules.

const DIRS: Dictionary[String, String] = {
	"res://data/status_effects": "StatusEffectData",
	"res://data/skills": "SkillData",
	"res://data/items": "ItemData",
	"res://data/enemies": "EnemyData",
	"res://data/characters": "CharacterData",
}
const EXPECTED: Array[String] = [
	"res://data/enemies/wolf.tres", "res://data/enemies/goblin_scout.tres", "res://data/enemies/skeleton.tres",
	"res://data/enemies/skeleton_charred.tres", "res://data/skills/attack_basic.tres",
	"res://data/skills/whirlwind.tres", "res://data/skills/charged_strike.tres", "res://data/skills/ember.tres",
	"res://data/skills/minor_heal.tres", "res://data/characters/knight.tres", "res://data/items/minor_potion.tres",
	"res://data/status_effects/bleed.tres", "res://data/status_effects/burn.tres",
	"res://data/status_effects/curse.tres", "res://data/status_effects/blessed.tres",
	"res://data/status_effects/sleep.tres", "res://data/status_effects/stun.tres",
]


func _enemy(id: String) -> EnemyData:
	return load("res://data/enemies/%s.tres" % id) as EnemyData


func test_expected_files_exist() -> void:
	for path: String in EXPECTED:
		assert_true(ResourceLoader.exists(path), "missing " + path)


func test_ids_match_file_names_and_types() -> void:
	for dir_path: String in DIRS:
		for file: String in DirAccess.get_files_at(dir_path):
			if not file.ends_with(".tres"):
				continue
			var res: Resource = load(dir_path.path_join(file))
			assert_not_null(res, file)
			if res == null:
				continue
			assert_eq(res.get_script().get_global_name(), StringName(DIRS[dir_path]), file)
			assert_eq(res.get(&"id"), StringName(file.get_basename()), "id of " + file)


func test_enemy_affinities() -> void:
	assert_eq(Elements.affinity(_enemy("wolf").affinities, Elements.Element.FIRE), Elements.WEAK)
	assert_eq(Elements.affinity(_enemy("goblin_scout").affinities, Elements.Element.LIGHTNING), Elements.WEAK)
	var skeleton: EnemyData = _enemy("skeleton")
	assert_eq(Elements.affinity(skeleton.affinities, Elements.Element.HOLY), Elements.WEAK)
	assert_eq(Elements.affinity(skeleton.affinities, Elements.Element.SHADOW), Elements.RESIST)
	assert_eq(Elements.affinity(_enemy("skeleton_charred").affinities, Elements.Element.FIRE), Elements.IMMUNE)


func test_enemies_are_complete() -> void:
	for id: String in ["wolf", "goblin_scout", "skeleton", "skeleton_charred"]:
		var data: EnemyData = _enemy(id)
		assert_not_null(data.stats, id + " stats")
		assert_true(data.stats.max_hp > 0 and data.xp > 0 and data.gold > 0, id + " has HP and rewards")
		for drop: DropEntry in data.drops:
			assert_not_null(drop.item, id + " drop item")


func test_charred_skeleton_resists_burn() -> void:
	var charred: Combatant = Combatant.from_enemy(_enemy("skeleton_charred"))
	var burn: StatusEffectData = load("res://data/status_effects/burn.tres") as StatusEffectData
	assert_true(StatusEffects.is_immune(charred, burn))


func test_knight() -> void:
	var knight: CharacterData = load("res://data/characters/knight.tres") as CharacterData
	assert_eq(knight.base_stats.max_hp, 120)
	assert_eq(knight.starting_skills.size(), 3)
	assert_eq(knight.skill_unlocks[0].skill.id, &"charged_strike")
	assert_eq(knight.growth.xp_for_level(1), 0)
	assert_true(knight.growth.xp_for_level(3) > knight.growth.xp_for_level(2))
	for skill: SkillData in knight.starting_skills:
		assert_true(skill.mp_cost <= knight.base_stats.max_mp, skill.id + " is castable at level 1")


func test_minor_potion() -> void:
	var potion: ItemData = load("res://data/items/minor_potion.tres") as ItemData
	assert_not_null(potion.icon, "HD flask icon")
	assert_eq(potion.effect, ItemData.Effect.HEAL_HP)
	assert_true(potion.usable_in_battle and potion.usable_in_field)


func test_status_icons_and_tags() -> void:
	for id: String in ["bleed", "burn", "curse", "blessed"]:
		var status: StatusEffectData = load("res://data/status_effects/%s.tres" % id) as StatusEffectData
		assert_not_null(status.icon, id + " icon")
	for id: String in ["sleep", "stun"]:
		var status: StatusEffectData = load("res://data/status_effects/%s.tres" % id) as StatusEffectData
		assert_true(status.skip_turn and not status.tag_text.is_empty(), id + " skips turns and has a tag")


func test_knight_wins_a_real_wolf_fight() -> void:
	var knight: CharacterData = load("res://data/characters/knight.tres") as CharacterData
	var setup: BattleSetup = BattleFixtures.setup([_enemy("wolf"), _enemy("wolf")])
	var engine: BattleEngine = BattleEngine.new()
	engine.setup(setup, [Combatant.from_character(knight)], BattleFixtures.rng(10))
	BattleFixtures.run_auto_battle(engine, 20)
	assert_eq(engine.outcome(), BattleEngine.Outcome.VICTORY, "the slice's first fight is winnable by attacking")
