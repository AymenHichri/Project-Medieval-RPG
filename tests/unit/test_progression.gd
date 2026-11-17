extends TestCase
## Progression, PartyMember and Party (PROJECT_PLAN.md §6.4, Phase 7).

const KNIGHT: String = "res://data/characters/knight.tres"


func _knight() -> CharacterData:
	return load(KNIGHT) as CharacterData


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_xp_to_next_matches_the_formula() -> void:
	var growth: GrowthCurve = _knight().growth
	assert_eq(growth.xp_base, 12)
	assert_almost_eq(growth.xp_exponent, 1.6, 0.0001)
	for level: int in [1, 2, 5, 10]:
		assert_eq(Progression.xp_to_next(growth, level), roundi(12 * pow(level, 1.6)), "level %d" % level)


func test_xp_to_next_is_monotonic_up_to_the_cap() -> void:
	var growth: GrowthCurve = _knight().growth
	var previous: int = 0
	for level: int in range(1, growth.max_level):
		var needed: int = Progression.xp_to_next(growth, level)
		assert_true(needed > previous, "level %d needs %d, level %d needed %d" % [level, needed, level - 1, previous])
		previous = needed
	assert_eq(Progression.xp_to_next(growth, growth.max_level), 0, "no XP past the cap")


func test_level_for_xp_and_totals_agree() -> void:
	var growth: GrowthCurve = _knight().growth
	assert_eq(Progression.level_for_xp(growth, 0), 1)
	for level: int in range(2, 12):
		var total: int = Progression.total_xp_for_level(growth, level)
		assert_eq(Progression.level_for_xp(growth, total), level, "exactly enough for %d" % level)
		assert_eq(Progression.level_for_xp(growth, total - 1), level - 1, "one short of %d" % level)
	assert_eq(Progression.level_for_xp(growth, 10_000_000), growth.max_level, "capped")
	assert_eq(growth.xp_for_level(1), 0)


func test_one_level_up_adds_gains_and_raises_hp() -> void:
	var member: PartyMember = PartyMember.create(_knight())
	member.combatant.hp = 50
	var ups: Array[LevelUp] = member.gain_xp(Progression.xp_to_next(member.data.growth, 1), _rng(1))
	assert_eq(ups.size(), 1)
	assert_eq(member.level, 2)
	var base: StatBlock = member.data.base_stats
	assert_eq(member.stats.max_hp, base.max_hp + ups[0].gains.max_hp)
	assert_eq(member.combatant.max_hp(), member.stats.max_hp, "the fighter uses the level stats")
	assert_eq(member.combatant.hp, 50 + ups[0].gains.max_hp, "HP rises by the max HP gain")
	assert_eq(base.max_hp, 120, "the .tres base stats are never mutated")


func test_multi_level_up_from_one_big_reward() -> void:
	var member: PartyMember = PartyMember.create(_knight())
	var growth: GrowthCurve = member.data.growth
	var ups: Array[LevelUp] = member.gain_xp(Progression.total_xp_for_level(growth, 5) + 3, _rng(2))
	assert_eq(ups.size(), 4, "levels 2, 3, 4 and 5")
	assert_eq(member.level, 5)
	var levels: Array[int] = []
	for up: LevelUp in ups:
		levels.append(up.level)
	assert_eq(levels, [2, 3, 4, 5] as Array[int])
	assert_eq(member.xp_to_next_level(), Progression.xp_to_next(growth, 5) - 3)


func test_stat_gains_stay_within_one_of_the_curve() -> void:
	var growth: GrowthCurve = _knight().growth
	var rng: RandomNumberGenerator = _rng(42)
	var seen_low: bool = false
	var seen_high: bool = false
	for i: int in 300:
		var gains: StatBlock = Progression.roll_gains(growth, rng)
		for stat: StringName in StatBlock.NAMES:
			var expected: int = growth.stat_gain_per_level.get_stat(stat)
			var got: int = gains.get_stat(stat)
			assert_true(absi(got - expected) <= 1 and got >= 0, "%s gain %d vs %d" % [stat, got, expected])
			seen_low = seen_low or got < expected
			seen_high = seen_high or got > expected
	assert_true(seen_low and seen_high, "both directions occur")


func test_same_seed_same_gains() -> void:
	var a: PartyMember = PartyMember.create(_knight())
	var b: PartyMember = PartyMember.create(_knight())
	a.gain_xp(500, _rng(7))
	b.gain_xp(500, _rng(7))
	for stat: StringName in StatBlock.NAMES:
		assert_eq(a.stats.get_stat(stat), b.stats.get_stat(stat), stat)


func test_skill_unlocked_at_level_three_is_learned_once() -> void:
	var member: PartyMember = PartyMember.create(_knight())
	var charged: SkillData = load("res://data/skills/charged_strike.tres") as SkillData
	assert_false(charged in member.skills())
	member.gain_xp(Progression.total_xp_for_level(member.data.growth, 2), _rng(3))
	assert_false(charged in member.skills(), "not yet at level 2")
	var ups: Array[LevelUp] = member.gain_xp(Progression.xp_to_next(member.data.growth, 2), _rng(3))
	assert_eq(member.level, 3)
	assert_true(charged in member.skills(), "learned at level 3")
	assert_eq(ups[0].learned, [charged] as Array[SkillData])
	assert_true("Knight learned Charged Strike!" in ups[0].describe())
	member.gain_xp(1000, _rng(3))
	assert_eq(member.skills().count(charged), 1, "never learned twice")


func test_party_holds_at_most_three() -> void:
	var party: Party = Party.new()
	for i: int in 3:
		assert_true(party.add(PartyMember.create(_knight())))
	assert_false(party.add(PartyMember.create(_knight())), "a fourth member is refused")
	assert_eq(party.size(), 3)
	assert_eq(party.combatants().size(), 3)
	assert_eq(party.member_of(party.members[1].combatant), party.members[1])


func test_heal_all_restores_hp_mp_and_clears_statuses() -> void:
	var party: Party = Party.new()
	party.add(PartyMember.create(_knight()))
	var fighter: Combatant = party.leader().combatant
	fighter.hp = 3
	fighter.mp = 0
	fighter.statuses.append(ActiveStatus.new(load("res://data/status_effects/bleed.tres") as StatusEffectData, 3))
	party.heal_all()
	assert_eq(fighter.hp, fighter.max_hp())
	assert_eq(fighter.mp, fighter.max_mp())
	assert_true(fighter.statuses.is_empty())
