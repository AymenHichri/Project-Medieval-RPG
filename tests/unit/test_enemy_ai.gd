extends TestCase
## EnemyAI: weighted choice, target strategies, heal rule.

const PICKS: int = 10000
const TOLERANCE: float = 0.03


func _enemy_with(profile: AIProfile, skills: Array[SkillData], mp: int = 50) -> Combatant:
	var data: EnemyData = BattleFixtures.enemy_data(&"caster", StatBlock.create(100, mp, 10, 10, 10))
	data.ai = profile
	data.skills = skills
	return Combatant.from_enemy(data)


func test_pick_weighted_respects_weights() -> void:
	var weights: Array[int] = [1, 3, 6]
	var counts: Array[int] = [0, 0, 0]
	var rng: RandomNumberGenerator = BattleFixtures.rng(42)
	for i: int in PICKS:
		counts[EnemyAI.pick_weighted(weights, rng)] += 1
	assert_almost_eq(counts[0] / float(PICKS), 0.1, TOLERANCE)
	assert_almost_eq(counts[1] / float(PICKS), 0.3, TOLERANCE)
	assert_almost_eq(counts[2] / float(PICKS), 0.6, TOLERANCE)
	assert_eq(EnemyAI.pick_weighted([0, 0] as Array[int], rng), -1)


func test_profile_weights_over_many_choices() -> void:
	var bolt: SkillData = BattleFixtures.skill(&"bolt", SkillData.Category.MAGIC, 0, 10, Targeting.Mode.ONE_ENEMY)
	var profile: AIProfile = AIProfile.new()
	profile.attack_weight = 1
	profile.skill_weights = {bolt: 3}
	var enemy: Combatant = _enemy_with(profile, [bolt])
	var foes: Array[Combatant] = [BattleFixtures.hero(StatBlock.create(100, 0, 10, 10))]
	var allies: Array[Combatant] = [enemy]
	var rng: RandomNumberGenerator = BattleFixtures.rng(7)
	var skill_picks: int = 0
	for i: int in PICKS:
		if EnemyAI.choose_from(enemy, allies, foes, rng).kind == BattleAction.Kind.SKILL:
			skill_picks += 1
	assert_almost_eq(skill_picks / float(PICKS), 0.75, TOLERANCE)


func test_unaffordable_skill_is_skipped() -> void:
	var nova: SkillData = BattleFixtures.skill(&"nova", SkillData.Category.MAGIC, 99, 10, Targeting.Mode.ALL_ENEMIES)
	var profile: AIProfile = AIProfile.new()
	profile.attack_weight = 1
	profile.skill_weights = {nova: 1000}
	var enemy: Combatant = _enemy_with(profile, [nova], 5)
	var foes: Array[Combatant] = [BattleFixtures.hero(StatBlock.create(100, 0, 10, 10))]
	var rng: RandomNumberGenerator = BattleFixtures.rng(3)
	for i: int in 100:
		assert_eq(EnemyAI.choose_from(enemy, [enemy], foes, rng).kind, BattleAction.Kind.ATTACK)


func test_lowest_hp_strategy() -> void:
	var profile: AIProfile = AIProfile.new()
	profile.target_strategy = AIProfile.TargetStrategy.LOWEST_HP
	var enemy: Combatant = _enemy_with(profile, [])
	var a: Combatant = BattleFixtures.hero(StatBlock.create(100, 0, 10, 10))
	var b: Combatant = BattleFixtures.hero(StatBlock.create(100, 0, 10, 10))
	var c: Combatant = BattleFixtures.hero(StatBlock.create(100, 0, 10, 10))
	b.hp = 12
	c.hp = 0  # dead: never chosen
	var rng: RandomNumberGenerator = BattleFixtures.rng(1)
	for i: int in 50:
		assert_eq(EnemyAI.choose_from(enemy, [enemy], [a, b, c], rng).targets[0], b)


func test_highest_attack_strategy() -> void:
	var profile: AIProfile = AIProfile.new()
	profile.target_strategy = AIProfile.TargetStrategy.HIGHEST_ATTACK
	var enemy: Combatant = _enemy_with(profile, [])
	var weak: Combatant = BattleFixtures.hero(StatBlock.create(100, 0, 10, 10))
	var strong: Combatant = BattleFixtures.hero(StatBlock.create(100, 0, 40, 10))
	assert_eq(EnemyAI.choose_from(enemy, [enemy], [weak, strong], BattleFixtures.rng()).targets[0], strong)


func test_heal_rule_heals_wounded_ally() -> void:
	var mend: SkillData = BattleFixtures.skill(&"mend", SkillData.Category.MAGIC, 3, 20, Targeting.Mode.ONE_ALLY)
	mend.effect = SkillData.Effect.HEAL
	var profile: AIProfile = AIProfile.new()
	profile.heal_below_hp_pct = 0.5
	var healer: Combatant = _enemy_with(profile, [mend])
	var hurt: Combatant = BattleFixtures.foe(StatBlock.create(100, 0, 10, 10))
	hurt.hp = 30
	var foes: Array[Combatant] = [BattleFixtures.hero(StatBlock.create(100, 0, 10, 10))]
	var action: BattleAction = EnemyAI.choose_from(healer, [healer, hurt], foes, BattleFixtures.rng())
	assert_eq(action.kind, BattleAction.Kind.SKILL)
	assert_eq(action.skill, mend)
	assert_eq(action.targets[0], hurt)


func test_no_profile_attacks() -> void:
	var enemy: Combatant = BattleFixtures.foe(StatBlock.create(10, 0, 10, 10))
	var foe: Combatant = BattleFixtures.hero(StatBlock.create(100, 0, 10, 10))
	var action: BattleAction = EnemyAI.choose_from(enemy, [enemy], [foe], BattleFixtures.rng())
	assert_eq(action.kind, BattleAction.Kind.ATTACK)
	assert_eq(action.targets[0], foe)
