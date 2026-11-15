extends TestCase
## BattleEngine integration: whole battles with fixture stats and seeded RNG.

const MAX_ROUNDS: int = 20


func _knight() -> Combatant:
	return BattleFixtures.hero(StatBlock.create(120, 20, 30, 20, 12, 14, 12, 8))


func _wolf() -> EnemyData:
	return BattleFixtures.enemy_data(&"wolf", StatBlock.create(45, 0, 22, 8, 0, 6, 16, 6), 8, 5)


func _skeleton() -> EnemyData:
	return BattleFixtures.enemy_data(&"skeleton", StatBlock.create(60, 0, 26, 16, 0, 4, 8, 4), 12, 7)


func _engine(enemies: Array[EnemyData], party: Array[Combatant], seed_value: int, can_flee: bool = true) -> BattleEngine:
	var engine: BattleEngine = BattleEngine.new()
	engine.setup(BattleFixtures.setup(enemies, can_flee), party, BattleFixtures.rng(seed_value))
	return engine


func test_knight_beats_two_wolves() -> void:
	for seed_value: int in [1, 2, 3, 4, 5]:
		var engine: BattleEngine = _engine([_wolf(), _wolf()], [_knight()], seed_value)
		var events: Array[BattleEvent] = BattleFixtures.run_auto_battle(engine, MAX_ROUNDS)
		assert_eq(engine.outcome(), BattleEngine.Outcome.VICTORY, "seed %d" % seed_value)
		assert_eq(BattleFixtures.count(events, BattleEvent.Type.DEFEATED), 2, "a Defeated event per wolf")
		assert_eq(BattleFixtures.count(events, BattleEvent.Type.BATTLE_ENDED), 1, "the end is reported once")
		var rewards: BattleResult = engine.compute_rewards()
		assert_true(rewards.is_victory())
		assert_eq(rewards.xp, 16)
		assert_eq(rewards.gold, 10)
		assert_eq(rewards.xp_per_member, 16)
		assert_eq(rewards.defeated_enemy_ids, [&"wolf", &"wolf"] as Array[StringName])


func test_duplicate_enemies_get_letters() -> void:
	var engine: BattleEngine = _engine([_wolf(), _wolf(), _skeleton()], [_knight()], 1)
	assert_eq(engine.enemies[0].display_name, "Wolf A")
	assert_eq(engine.enemies[1].display_name, "Wolf B")
	assert_eq(engine.enemies[2].display_name, "Skeleton")


func test_weak_knight_loses_to_three_skeletons() -> void:
	var weak: Combatant = BattleFixtures.hero(StatBlock.create(40, 0, 8, 2, 0, 0, 5))
	var engine: BattleEngine = _engine([_skeleton(), _skeleton(), _skeleton()], [weak], 4)
	BattleFixtures.run_auto_battle(engine, MAX_ROUNDS)
	assert_eq(engine.outcome(), BattleEngine.Outcome.DEFEAT)
	var result: BattleResult = engine.compute_rewards()
	assert_eq(result.xp, 0, "no rewards on defeat")
	assert_eq(result.gold, 0)


func _flee_once(seed_value: int) -> Dictionary:
	var knight: Combatant = _knight()
	var engine: BattleEngine = _engine([_wolf(), _wolf()], [knight], seed_value)
	engine.begin_round([BattleAction.flee(knight), BattleAction.attack(knight, engine.enemies[0])])
	var events: Array[BattleEvent] = []
	while engine.has_next_action():
		events.append_array(engine.execute_next())
	var flee_event: BattleEvent = BattleFixtures.first(events, BattleEvent.Type.FLEE_ATTEMPTED)
	return {
		&"success": flee_event.get_value(&"success") as bool,
		&"outcome": engine.outcome(),
		&"knight_attacked": _attacked_by(events, knight),
		&"enemies_acted": _attacked_by(events, engine.enemies[0]) or _attacked_by(events, engine.enemies[1]),
	}


func _attacked_by(events: Array[BattleEvent], actor: Combatant) -> bool:
	for e: BattleEvent in events:
		if e.type == BattleEvent.Type.DAMAGE and e.get_value(&"source") == actor:
			return true
	return false


func test_flee_is_deterministic_per_seed() -> void:
	var seen_success: bool = false
	var seen_failure: bool = false
	for seed_value: int in 30:
		var first_run: Dictionary = _flee_once(seed_value)
		assert_eq(first_run, _flee_once(seed_value), "seed %d repeats" % seed_value)
		assert_false(first_run[&"knight_attacked"] as bool, "fleeing replaces the party's other actions")
		if first_run[&"success"]:
			seen_success = true
			assert_eq(first_run[&"outcome"], BattleEngine.Outcome.FLED)
			assert_false(first_run[&"enemies_acted"] as bool, "nobody acts after a successful escape")
		else:
			seen_failure = true
			assert_eq(first_run[&"outcome"], BattleEngine.Outcome.ONGOING)
			assert_true(first_run[&"enemies_acted"] as bool, "enemies still act after a failed escape")
	assert_true(seen_success and seen_failure, "both outcomes occur over 30 seeds")


func test_cannot_flee_boss() -> void:
	var knight: Combatant = _knight()
	var engine: BattleEngine = _engine([_wolf()], [knight], 1, false)
	assert_eq(engine.flee_chance(), 0.0)
	engine.begin_round([BattleAction.flee(knight)])
	var events: Array[BattleEvent] = engine.execute_next()
	assert_eq(BattleFixtures.first(events, BattleEvent.Type.ACTION_FAILED).get_value(&"reason"), &"cannot_flee")


func test_phase_two_triggers_exactly_once() -> void:
	var unmasked: EnemyData = BattleFixtures.enemy_data(&"warden_unmasked", StatBlock.create(100, 0, 12, 10, 0, 0, 5), 50, 40)
	var boss: EnemyData = BattleFixtures.enemy_data(&"warden", StatBlock.create(100, 0, 12, 10, 0, 0, 5), 20, 10)
	boss.phase_two = unmasked
	boss.phase_two_at_hp_pct = 0.5
	var engine: BattleEngine = _engine([boss], [_knight()], 6, false)
	var events: Array[BattleEvent] = BattleFixtures.run_auto_battle(engine, 40)
	assert_eq(engine.outcome(), BattleEngine.Outcome.VICTORY)
	assert_eq(BattleFixtures.count(events, BattleEvent.Type.PHASE_CHANGE), 1)
	var change: BattleEvent = BattleFixtures.first(events, BattleEvent.Type.PHASE_CHANGE)
	assert_eq(change.get_value(&"new_data"), unmasked)
	assert_eq(engine.compute_rewards().xp, 50, "rewards come from the final form")


func test_xp_is_shared_by_survivors_only() -> void:
	var a: Combatant = _knight()
	var b: Combatant = _knight()
	var c: Combatant = _knight()
	var engine: BattleEngine = _engine([_wolf(), _wolf()], [a, b, c], 2)
	c.hp = 0
	BattleFixtures.run_auto_battle(engine, MAX_ROUNDS)
	var result: BattleResult = engine.compute_rewards()
	assert_eq(result.survivors.size(), 2)
	assert_eq(result.xp_per_member, 8, "16 XP over 2 survivors")


func test_drops_are_rolled_per_enemy() -> void:
	var potion: ItemData = ItemData.new()
	potion.id = &"potion"
	var always: DropEntry = DropEntry.new()
	always.item = potion
	always.chance = 1.0
	var wolf: EnemyData = _wolf()
	wolf.drops = [always]
	var engine: BattleEngine = _engine([wolf, wolf], [_knight()], 3)
	BattleFixtures.run_auto_battle(engine, MAX_ROUNDS)
	assert_eq(engine.compute_rewards().drops.size(), 2)


func test_defend_resets_at_round_end_and_round_counts() -> void:
	var knight: Combatant = _knight()
	var engine: BattleEngine = _engine([_wolf()], [knight], 1)
	engine.begin_round([BattleAction.defend(knight)])
	var first_events: Array[BattleEvent] = engine.execute_next()
	assert_eq(first_events[0].type, BattleEvent.Type.ACTION_STARTED)
	assert_eq((first_events[0].get_value(&"action") as BattleAction).kind, BattleAction.Kind.DEFEND, "Defend acts first")
	assert_true(knight.is_defending)
	while engine.has_next_action():
		engine.execute_next()
	var end_events: Array[BattleEvent] = engine.end_round()
	assert_false(knight.is_defending)
	assert_eq(BattleFixtures.first(end_events, BattleEvent.Type.ROUND_ENDED).get_value(&"round"), 1)


func test_same_seed_same_battle() -> void:
	var a: BattleEngine = _engine([_wolf(), _skeleton()], [_knight()], 77)
	var b: BattleEngine = _engine([_wolf(), _skeleton()], [_knight()], 77)
	var events_a: Array[BattleEvent] = BattleFixtures.run_auto_battle(a, MAX_ROUNDS)
	var events_b: Array[BattleEvent] = BattleFixtures.run_auto_battle(b, MAX_ROUNDS)
	assert_eq(events_a.size(), events_b.size())
	assert_eq(a.round_number, b.round_number)
	assert_eq(a.party[0].hp, b.party[0].hp)


func test_status_damage_can_end_the_battle() -> void:
	var bleed: StatusEffectData = load("res://data/status_effects/bleed.tres") as StatusEffectData
	var knight: Combatant = _knight()
	var engine: BattleEngine = _engine([_wolf()], [knight], 1)
	engine.enemies[0].hp = 1
	StatusEffects.apply(engine.enemies[0], bleed, engine.rng)
	engine.begin_round([BattleAction.defend(knight)])
	while engine.has_next_action():
		engine.execute_next()
	var events: Array[BattleEvent] = engine.end_round()
	assert_eq(engine.outcome(), BattleEngine.Outcome.VICTORY)
	assert_eq(BattleFixtures.count(events, BattleEvent.Type.BATTLE_ENDED), 1)
