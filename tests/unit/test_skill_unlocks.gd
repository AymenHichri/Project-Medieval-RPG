extends TestCase
## Skill unlocks (Phase 8): a skill is learned at exactly its level; a reward that skips several
## levels teaches every skill in between, each once; the results screen lists them.


func _skill(id: StringName) -> SkillData:
	return BattleFixtures.skill(id, SkillData.Category.SKILL, 0, 100, Targeting.Mode.ONE_ENEMY)


func _unlock(level: int, skill: SkillData) -> SkillUnlock:
	var unlock: SkillUnlock = SkillUnlock.new()
	unlock.level = level
	unlock.skill = skill
	return unlock


## A character with a flat XP curve (10 XP per level) and unlocks at levels 2, 3 and 5.
func _character(unlocks: Array[SkillUnlock]) -> CharacterData:
	var data: CharacterData = BattleFixtures.character_data(&"tester", StatBlock.create(50, 10, 10, 10))
	var growth: GrowthCurve = GrowthCurve.new()
	growth.xp_base = 10
	growth.xp_exponent = 0.0
	growth.stat_gain_per_level = StatBlock.create(1, 1, 1, 1)
	growth.max_level = 10
	data.growth = growth
	data.skill_unlocks = unlocks
	return data


func test_skill_is_learned_at_exactly_its_level() -> void:
	var slash: SkillData = _skill(&"slash")
	var member: PartyMember = PartyMember.create(_character([_unlock(3, slash)]))
	member.gain_xp(10, BattleFixtures.rng(1))
	assert_eq(member.level, 2)
	assert_false(slash in member.skills(), "not yet at level 2")
	var ups: Array[LevelUp] = member.gain_xp(9, BattleFixtures.rng(1))
	assert_true(ups.is_empty(), "one XP short of level 3")
	assert_false(slash in member.skills())
	ups = member.gain_xp(1, BattleFixtures.rng(1))
	assert_eq(member.level, 3)
	assert_true(slash in member.skills(), "learned on reaching level 3")
	assert_eq(ups[0].learned, [slash] as Array[SkillData])


func test_multi_level_jump_learns_every_skill_once() -> void:
	var a: SkillData = _skill(&"a")
	var b: SkillData = _skill(&"b")
	var c: SkillData = _skill(&"c")
	var member: PartyMember = PartyMember.create(_character([_unlock(2, a), _unlock(3, b), _unlock(5, c)]))
	var ups: Array[LevelUp] = member.gain_xp(40, BattleFixtures.rng(2))
	assert_eq(member.level, 5)
	assert_eq(ups.size(), 4, "levels 2, 3, 4 and 5")
	assert_eq(ups[0].learned, [a] as Array[SkillData])
	assert_eq(ups[1].learned, [b] as Array[SkillData])
	assert_true(ups[2].learned.is_empty())
	assert_eq(ups[3].learned, [c] as Array[SkillData])
	for skill: SkillData in [a, b, c]:
		assert_eq(member.skills().count(skill), 1, "%s learned once" % skill.id)


func test_starting_skill_unlocked_again_is_not_duplicated() -> void:
	var a: SkillData = _skill(&"a")
	var data: CharacterData = _character([_unlock(2, a)])
	data.starting_skills = [a]
	var member: PartyMember = PartyMember.create(data)
	var ups: Array[LevelUp] = member.gain_xp(10, BattleFixtures.rng(3))
	assert_eq(member.skills().count(a), 1)
	assert_true(ups[0].learned.is_empty(), "nothing new to announce")


func test_recruit_created_above_level_one_knows_its_skills() -> void:
	var a: SkillData = _skill(&"a")
	var c: SkillData = _skill(&"c")
	var member: PartyMember = PartyMember.create(_character([_unlock(2, a), _unlock(5, c)]), 4, BattleFixtures.rng(4))
	assert_eq(member.level, 4)
	assert_true(a in member.skills())
	assert_false(c in member.skills(), "level 5 skill not yet")
	member.gain_xp(10, BattleFixtures.rng(4))
	assert_true(c in member.skills(), "learned at level 5 as usual")


func test_results_preview_lists_learned_skills() -> void:
	var saved: Party = GameState.party
	var a: SkillData = _skill(&"a")
	a.display_name = "Cleave"
	var member: PartyMember = PartyMember.create(_character([_unlock(3, a)]))
	GameState.party = Party.new()
	GameState.party.add(member)
	var result: BattleResult = BattleResult.new()
	result.outcome = BattleEngine.Outcome.VICTORY
	result.xp_per_member = 25
	result.survivors = [member.combatant]
	var lines: PackedStringArray = GameState.preview_level_ups(result)
	GameState.party = saved
	assert_eq(Array(lines), ["Tester reached level 2!", "Tester reached level 3!", "Tester learned Cleave!"])


func test_party_data_unlocks() -> void:
	var warden: CharacterData = load("res://data/characters/warden.tres") as CharacterData
	var hexblade: CharacterData = load("res://data/characters/hexblade.tres") as CharacterData
	assert_eq(Progression.skills_learned_at(warden, 4)[0].id, &"benediction")
	assert_eq(Progression.skills_learned_at(hexblade, 3)[0].id, &"hex")
