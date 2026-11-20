extends TestCase
## Three-member battles (Phase 8): a seeded fight with the real Knight, Warden and Hexblade;
## statuses inflicted by enemies and cured by a skill or an item; Blessed from the Warden; Provoke
## draws the enemies' blows; Guard covers an ally; a full wipe is a DEFEAT.

const KNIGHT: String = "res://data/characters/knight.tres"
const WARDEN: String = "res://data/characters/warden.tres"
const HEXBLADE: String = "res://data/characters/hexblade.tres"
const WOLF: String = "res://data/enemies/wolf.tres"
const SKELETON: String = "res://data/enemies/skeleton.tres"


func _skill(id: StringName) -> SkillData:
	return load("res://data/skills/%s.tres" % id) as SkillData


func _party() -> Array[Combatant]:
	var out: Array[Combatant] = []
	for path: String in [KNIGHT, WARDEN, HEXBLADE]:
		out.append(PartyMember.create(load(path) as CharacterData).combatant)
	return out


## A foe that never acts on its own (no AI skills) and survives a long time.
func _dummy(attack: int = 0) -> EnemyData:
	return BattleFixtures.enemy_data(&"dummy", StatBlock.create(9999, 0, attack, 999, 0, 999, 1, 0))


## Runs one round with the given party actions; returns its events.
func _round(engine: BattleEngine, actions: Array[BattleAction]) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	engine.begin_round(actions)
	while engine.has_next_action():
		events.append_array(engine.execute_next())
	events.append_array(engine.end_round())
	return events


func test_three_member_seeded_battle_is_won_and_deterministic() -> void:
	var outcomes: Array[String] = []
	for run: int in 2:
		var party: Array[Combatant] = _party()
		var engine: BattleEngine = BattleEngine.new()
		var wolf: EnemyData = load(WOLF) as EnemyData
		engine.setup(BattleFixtures.setup([wolf, wolf, load(SKELETON) as EnemyData]), party, BattleFixtures.rng(808))
		var events: Array[BattleEvent] = BattleFixtures.run_auto_battle(engine, 40)
		assert_eq(engine.outcome(), BattleEngine.Outcome.VICTORY, "three members beat two wolves and a skeleton")
		var actors: Dictionary[Combatant, bool] = {}
		for e: BattleEvent in events:
			if e.type == BattleEvent.Type.ACTION_STARTED:
				actors[e.get_value(&"actor") as Combatant] = true
		for member: Combatant in party:
			assert_true(actors.has(member), "%s acted" % member.display_name)
		var result: BattleResult = engine.compute_rewards()
		assert_eq(result.xp_per_member, ceili(float(result.xp) / result.survivors.size()), "XP split between the survivors")
		outcomes.append("%d/%d/%d/%d" % [engine.round_number, party[0].hp, party[1].hp, party[2].hp])
	assert_eq(outcomes[0], outcomes[1], "same seed, same battle")


func test_enemy_status_attack_inflicts_bleed_and_purify_cures_it() -> void:
	var party: Array[Combatant] = _party()
	var knight: Combatant = party[0]
	var warden: Combatant = party[1]
	var wolf: EnemyData = load(WOLF) as EnemyData
	var rend: SkillData = _skill(&"rend")
	assert_true(rend in wolf.skills, "the wolf knows Rend")
	assert_eq(rend.inflicts.id, &"bleed")
	var engine: BattleEngine = BattleEngine.new()
	engine.setup(BattleFixtures.setup([wolf]), party, BattleFixtures.rng(1))
	# Force the wolf's Rend until it lands (the AI picks it at random).
	var resolver: ActionResolver = ActionResolver.new(engine.party, engine.enemies, BattleFixtures.rng(9))
	var tries: int = 0
	while not knight.has_status(&"bleed") and tries < 50:
		tries += 1
		knight.hp = knight.max_hp()
		resolver.resolve(BattleAction.use_skill(engine.enemies[0], rend, [knight] as Array[Combatant]))
	assert_true(knight.has_status(&"bleed"), "Rend inflicted Bleed within 50 tries")
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.use_skill(warden, _skill(&"purify"), [knight] as Array[Combatant]))
	assert_false(knight.has_status(&"bleed"), "Purify cured it")
	var removed: BattleEvent = BattleFixtures.first(events, BattleEvent.Type.STATUS_REMOVED)
	assert_not_null(removed)
	assert_eq(removed.get_value(&"reason"), &"cured")


func test_grave_chill_curses_and_holy_water_lifts_it() -> void:
	var party: Array[Combatant] = _party()
	var hexblade: Combatant = party[2]
	var skeleton: EnemyData = load(SKELETON) as EnemyData
	var chill: SkillData = _skill(&"grave_chill")
	assert_true(chill in skeleton.skills)
	var resolver: ActionResolver = ActionResolver.new(party, [Combatant.from_enemy(skeleton)] as Array[Combatant], BattleFixtures.rng(5))
	var tries: int = 0
	while not hexblade.has_status(&"curse") and tries < 50:
		tries += 1
		hexblade.hp = hexblade.max_hp()
		resolver.resolve(BattleAction.use_skill(resolver.enemies[0], chill, [hexblade] as Array[Combatant]))
	assert_true(hexblade.has_status(&"curse"), "Grave Chill cursed within 50 tries")
	assert_true(hexblade.effective_stat(&"magic") < hexblade.stats.magic, "Curse lowers MAG")
	var water: ItemData = load("res://data/items/holy_water.tres") as ItemData
	resolver.resolve(BattleAction.use_item(party[0], water, [hexblade] as Array[Combatant]))
	assert_false(hexblade.has_status(&"curse"), "Holy Water lifted the Curse")


func test_purify_on_a_healthy_ally_has_no_effect() -> void:
	var party: Array[Combatant] = _party()
	var resolver: ActionResolver = ActionResolver.new(party, [] as Array[Combatant], BattleFixtures.rng(1))
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.use_skill(party[1], _skill(&"purify"), [party[0]] as Array[Combatant]))
	assert_eq(BattleFixtures.count(events, BattleEvent.Type.NO_EFFECT), 1)
	assert_eq(party[1].mp, party[1].max_mp() - _skill(&"purify").mp_cost, "the MP is still spent")


func test_blessing_and_benediction_apply_blessed() -> void:
	var party: Array[Combatant] = _party()
	var warden: Combatant = party[1]
	var resolver: ActionResolver = ActionResolver.new(party, [] as Array[Combatant], BattleFixtures.rng(1))
	resolver.resolve(BattleAction.use_skill(warden, _skill(&"blessing"), [party[2]] as Array[Combatant]))
	assert_true(party[2].has_status(&"blessed"))
	assert_true(party[2].effective_stat(&"defense") > party[2].stats.defense, "Blessed raises DEF")
	assert_false(party[0].has_status(&"blessed"), "only the target")
	warden.mp = warden.max_mp()
	resolver.resolve(BattleAction.use_skill(warden, _skill(&"benediction"), [] as Array[Combatant]))
	for member: Combatant in party:
		assert_true(member.has_status(&"blessed"), "%s blessed by Benediction" % member.display_name)


func test_provoke_draws_every_single_target_action() -> void:
	var party: Array[Combatant] = _party()
	var warden: Combatant = party[1]
	var engine: BattleEngine = BattleEngine.new()
	var biter: EnemyData = _dummy(30)
	engine.setup(BattleFixtures.setup([biter, biter, biter]), party, BattleFixtures.rng(12))
	var events: Array[BattleEvent] = _round(engine, [BattleAction.use_skill(warden, _skill(&"provoke"), [] as Array[Combatant])] as Array[BattleAction])
	var first_action: BattleEvent = BattleFixtures.first(events, BattleEvent.Type.ACTION_STARTED)
	assert_eq(first_action.get_value(&"actor"), warden, "Provoke goes first (priority)")
	assert_true(warden.has_status(&"taunt"), "still taunting after the first round")
	for e: BattleEvent in events:
		if e.type == BattleEvent.Type.DAMAGE:
			assert_eq(e.subject(), warden, "every blow hit the Warden")
	var hits: int = BattleFixtures.count(events, BattleEvent.Type.DAMAGE)
	assert_eq(hits, 3, "all three foes attacked")
	events = _round(engine, [] as Array[BattleAction])
	for e: BattleEvent in events:
		if e.type == BattleEvent.Type.DAMAGE:
			assert_eq(e.subject(), warden, "second round too")
	assert_false(warden.has_status(&"taunt"), "Taunt wears off after two rounds")


func test_guard_covers_an_ally_and_resets_at_round_end() -> void:
	var party: Array[Combatant] = _party()
	var knight: Combatant = party[0]
	var warden: Combatant = party[1]
	var engine: BattleEngine = BattleEngine.new()
	engine.setup(BattleFixtures.setup([_dummy(40)]), party, BattleFixtures.rng(3))
	var foe: Combatant = engine.enemies[0]
	var resolver: ActionResolver = ActionResolver.new(engine.party, engine.enemies, BattleFixtures.rng(3))
	var guard_events: Array[BattleEvent] = resolver.resolve(BattleAction.use_skill(warden, _skill(&"guard"), [knight] as Array[Combatant]))
	assert_not_null(BattleFixtures.first(guard_events, BattleEvent.Type.GUARDING))
	assert_true(warden.is_defending, "the guardian defends")
	assert_eq(knight.guarded_by, warden)
	var knight_hp: int = knight.hp
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.attack(foe, knight))
	var covered: BattleEvent = BattleFixtures.first(events, BattleEvent.Type.COVERED)
	assert_not_null(covered)
	assert_eq(covered.subject(), warden)
	assert_eq(covered.get_value(&"protected"), knight)
	assert_eq(BattleFixtures.first(events, BattleEvent.Type.DAMAGE).subject(), warden, "the Warden takes the blow")
	assert_eq(knight.hp, knight_hp, "the Knight is untouched")
	engine.end_round()
	assert_null(knight.guarded_by, "Guard lasts one round")
	assert_false(warden.is_defending)


func test_guard_does_not_cover_area_attacks_and_has_priority() -> void:
	var party: Array[Combatant] = _party()
	var guard: SkillData = _skill(&"guard")
	assert_eq(TurnOrder.priority(BattleAction.use_skill(party[1], guard, [party[0]] as Array[Combatant])), 1)
	var whirl: SkillData = _skill(&"whirlwind")
	var foe: Combatant = Combatant.from_enemy(_dummy(40))
	foe.mp = 99
	var resolver: ActionResolver = ActionResolver.new(party, [foe] as Array[Combatant], BattleFixtures.rng(2))
	party[0].guarded_by = party[1]
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.use_skill(foe, whirl, [] as Array[Combatant]))
	assert_eq(BattleFixtures.count(events, BattleEvent.Type.COVERED), 0, "area attacks are not covered")
	assert_eq(BattleFixtures.count(events, BattleEvent.Type.DAMAGE), 3)


func test_whole_party_wiped_is_defeat() -> void:
	var party: Array[Combatant] = _party()
	var engine: BattleEngine = BattleEngine.new()
	var brute: EnemyData = BattleFixtures.enemy_data(&"brute", StatBlock.create(9999, 0, 9999, 999, 0, 999, 99, 0))
	engine.setup(BattleFixtures.setup([brute, brute, brute]), party, BattleFixtures.rng(6))
	var events: Array[BattleEvent] = BattleFixtures.run_auto_battle(engine, 10)
	assert_eq(engine.outcome(), BattleEngine.Outcome.DEFEAT)
	for member: Combatant in party:
		assert_false(member.is_alive())
	var ended: BattleEvent = BattleFixtures.first(events, BattleEvent.Type.BATTLE_ENDED)
	assert_eq(ended.get_value(&"outcome"), BattleEngine.Outcome.DEFEAT)
	assert_false(engine.compute_rewards().is_victory())


func test_one_member_down_is_not_defeat() -> void:
	var party: Array[Combatant] = _party()
	var engine: BattleEngine = BattleEngine.new()
	engine.setup(BattleFixtures.setup([_dummy()]), party, BattleFixtures.rng(6))
	party[0].take_damage(9999)
	party[2].take_damage(9999)
	assert_eq(engine.outcome(), BattleEngine.Outcome.ONGOING, "the Warden still stands")
