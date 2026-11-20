extends TestCase
## Party (Phase 8): add/remove, at most 3 members, a dead member gets no XP and no turn, a revived
## one acts in its old place again; recruiting joins at the leader's level and sets a flag.

const WARDEN: String = "res://data/characters/warden.tres"
const HEXBLADE: String = "res://data/characters/hexblade.tres"

var _saved_party: Party
var _saved_flags: Dictionary[StringName, Variant] = {}
var _saved_rng: RandomNumberGenerator


func before_each() -> void:
	_saved_party = GameState.party
	_saved_flags = GameState.flags.duplicate()
	_saved_rng = GameState.rng
	GameState.party = Party.new()
	GameState.flags = {}
	GameState.rng = BattleFixtures.rng(3)


func after_each() -> void:
	GameState.party = _saved_party
	GameState.flags = _saved_flags
	GameState.rng = _saved_rng


func _member(id: StringName, stats: StatBlock = null) -> PartyMember:
	var data: CharacterData = BattleFixtures.character_data(id, stats if stats != null else StatBlock.create(50, 10, 20, 10, 5, 5, 10, 0))
	data.growth = GrowthCurve.new()
	data.growth.stat_gain_per_level = StatBlock.create(1, 1, 1, 1)
	return PartyMember.create(data)


func test_add_and_remove_keep_order() -> void:
	var party: Party = Party.new()
	var a: PartyMember = _member(&"a")
	var b: PartyMember = _member(&"b")
	var c: PartyMember = _member(&"c")
	assert_true(party.add(a))
	assert_true(party.add(b))
	assert_true(party.add(c))
	assert_false(party.add(b), "no duplicates")
	assert_true(party.remove(b))
	assert_false(party.remove(b), "already gone")
	assert_eq(party.members, [a, c] as Array[PartyMember])
	assert_eq(party.combatants(), [a.combatant, c.combatant] as Array[Combatant], "battle order follows the party")
	assert_true(party.has_character(&"c"))
	assert_eq(party.member_by_id(&"a"), a)
	assert_null(party.member_by_id(&"b"))


func test_party_holds_at_most_three() -> void:
	var party: Party = Party.new()
	for id: StringName in [&"a", &"b", &"c"]:
		assert_true(party.add(_member(id)))
	assert_true(party.is_full())
	assert_false(party.add(_member(&"d")), "a fourth member is refused")
	assert_eq(party.size(), Party.MAX_ACTIVE)


func test_dead_member_gets_no_xp() -> void:
	var party: Party = Party.new()
	var alive: PartyMember = _member(&"alive")
	var fallen: PartyMember = _member(&"fallen")
	party.add(alive)
	party.add(fallen)
	GameState.party = party
	fallen.combatant.take_damage(9999)
	var engine: BattleEngine = BattleEngine.new()
	var weak: EnemyData = BattleFixtures.enemy_data(&"rat", StatBlock.create(1, 0, 1, 0), 30, 4)
	engine.setup(BattleFixtures.setup([weak]), party.combatants(), BattleFixtures.rng(1))
	BattleFixtures.run_auto_battle(engine, 10)
	var result: BattleResult = engine.compute_rewards()
	assert_true(result.is_victory())
	assert_eq(result.survivors, [alive.combatant] as Array[Combatant])
	assert_eq(result.xp_per_member, 30, "the survivor takes all the XP")
	GameState.apply_battle_rewards(result)
	assert_eq(alive.xp, 30)
	assert_eq(fallen.xp, 0, "the fallen member earns nothing")
	assert_eq(party.living_members(), [alive] as Array[PartyMember])


func test_dead_member_is_left_out_of_the_turn_order() -> void:
	var a: PartyMember = _member(&"a")
	var b: PartyMember = _member(&"b")
	var engine: BattleEngine = BattleEngine.new()
	var dummy: EnemyData = BattleFixtures.enemy_data(&"dummy", StatBlock.create(999, 0, 0, 99))
	engine.setup(BattleFixtures.setup([dummy]), [a.combatant, b.combatant] as Array[Combatant], BattleFixtures.rng(2))
	b.combatant.take_damage(9999)
	var foe: Combatant = engine.enemies[0]
	engine.begin_round([BattleAction.attack(a.combatant, foe), BattleAction.attack(b.combatant, foe)] as Array[BattleAction])
	var actors: Array[Combatant] = _actors_of_round(engine)
	assert_true(a.combatant in actors)
	assert_false(b.combatant in actors, "a fallen member does not act")


func test_revived_member_acts_again_in_its_place() -> void:
	var a: PartyMember = _member(&"a")
	var b: PartyMember = _member(&"b")
	var c: PartyMember = _member(&"c")
	var party_side: Array[Combatant] = [a.combatant, b.combatant, c.combatant]
	var engine: BattleEngine = BattleEngine.new()
	var dummy: EnemyData = BattleFixtures.enemy_data(&"dummy", StatBlock.create(999, 0, 0, 99))
	engine.setup(BattleFixtures.setup([dummy]), party_side, BattleFixtures.rng(4))
	b.combatant.take_damage(9999)
	assert_eq(b.combatant.revive(10), 10)
	assert_eq(engine.party, party_side, "the revived member is still second")
	var foe: Combatant = engine.enemies[0]
	var actions: Array[BattleAction] = []
	for member: Combatant in party_side:
		actions.append(BattleAction.attack(member, foe))
	engine.begin_round(actions)
	assert_true(b.combatant in _actors_of_round(engine), "acts again after a revive")


func test_recruit_joins_at_the_leaders_level_and_sets_the_flag() -> void:
	GameState.ensure_party()
	var knight: PartyMember = GameState.party.leader()
	knight.gain_xp(Progression.total_xp_for_level(knight.data.growth, 4), GameState.rng)
	assert_eq(knight.level, 4)
	var joined: Array[PartyMember] = []
	var on_join: Callable = func(m: PartyMember) -> void: joined.append(m)
	GameState.member_joined.connect(on_join)
	var warden: CharacterData = load(WARDEN) as CharacterData
	var member: PartyMember = GameState.recruit(warden, &"warden_joined")
	GameState.member_joined.disconnect(on_join)
	assert_not_null(member)
	assert_eq(member.level, 4, "catches up with the leader")
	assert_eq(member.xp, Progression.total_xp_for_level(warden.growth, 4))
	assert_true(member.stats.max_hp > warden.base_stats.max_hp, "level gains applied")
	assert_eq(member.combatant.hp, member.stats.max_hp, "joins at full HP")
	assert_eq(member.combatant.mp, member.stats.max_mp, "and full MP")
	assert_true(GameState.get_flag(&"warden_joined") as bool)
	assert_eq(joined, [member] as Array[PartyMember])
	var benediction: SkillData = Progression.skills_learned_at(warden, 4)[0]
	assert_true(benediction in member.skills(), "learned the level 4 skill on the way")


func test_recruit_refuses_duplicates_and_a_full_party() -> void:
	GameState.ensure_party()
	var warden: CharacterData = load(WARDEN) as CharacterData
	var hexblade: CharacterData = load(HEXBLADE) as CharacterData
	assert_not_null(GameState.recruit(warden))
	assert_null(GameState.recruit(warden), "already in the party")
	assert_not_null(GameState.recruit(hexblade))
	assert_eq(GameState.party.size(), 3)
	var extra: CharacterData = BattleFixtures.character_data(&"extra", StatBlock.create(10, 0, 1, 1))
	assert_null(GameState.recruit(extra, &"extra_joined"), "the party is full")
	assert_false(GameState.get_flag(&"extra_joined") as bool, "no flag when nobody joined")


## The actors in the order the engine will run them this round.
func _actors_of_round(engine: BattleEngine) -> Array[Combatant]:
	var actors: Array[Combatant] = []
	while engine.has_next_action():
		for e: BattleEvent in engine.execute_next():
			if e.type == BattleEvent.Type.ACTION_STARTED:
				actors.append(e.get_value(&"actor") as Combatant)
	return actors