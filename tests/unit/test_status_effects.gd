extends TestCase
## StatusEffects: ticks, durations, immunities, healing modifiers, skip-turn, refresh.


func _target(hp: int = 100) -> Combatant:
	return BattleFixtures.foe(StatBlock.create(hp, 10, 10, 10, 10, 10, 10))


func _load(id: String) -> StatusEffectData:
	return load("res://data/status_effects/%s.tres" % id) as StatusEffectData


func test_bleed_ticks_five_percent_and_expires() -> void:
	var t: Combatant = _target(100)
	StatusEffects.apply(t, _load("bleed"), BattleFixtures.rng())
	for round_index: int in 3:
		var events: Array[BattleEvent] = StatusEffects.tick_round_end([t])
		var dmg: BattleEvent = BattleFixtures.first(events, BattleEvent.Type.DAMAGE)
		assert_not_null(dmg, "tick %d" % round_index)
		if dmg != null:
			assert_eq(dmg.get_value(&"amount"), 5)
	assert_eq(t.hp, 85)
	assert_false(t.has_status(&"bleed"), "expired after 3 rounds")
	assert_eq(BattleFixtures.count(StatusEffects.tick_round_end([t]), BattleEvent.Type.DAMAGE), 0)


func test_burn_does_nothing_to_fire_immune() -> void:
	var t: Combatant = _target()
	t.affinities = {Elements.Element.FIRE: Elements.IMMUNE}
	var events: Array[BattleEvent] = StatusEffects.apply(t, _load("burn"), BattleFixtures.rng())
	assert_eq(events[0].type, BattleEvent.Type.STATUS_RESISTED)
	assert_false(t.has_status(&"burn"))


func test_listed_immunity() -> void:
	var t: Combatant = _target()
	t.status_immunities = [_load("sleep")]
	StatusEffects.apply(t, _load("sleep"), BattleFixtures.rng())
	assert_false(t.has_status(&"sleep"))


func test_curse_halves_healing_received_and_lowers_attack() -> void:
	var t: Combatant = _target()
	StatusEffects.apply(t, _load("curse"), BattleFixtures.rng())
	assert_almost_eq(StatusEffects.healing_received_multiplier(t), 0.5, 0.0001)
	assert_eq(t.effective_stat(&"attack"), 8, "10 × 0.75 rounded")
	assert_true(StatusEffects.modifies_stat(t, &"magic"))
	assert_false(StatusEffects.modifies_stat(t, &"defense"))
	var plain: int = DamageCalculator.heal(20, 10, BattleFixtures.rng(4))
	var cursed: int = DamageCalculator.heal(20, 10, BattleFixtures.rng(4), StatusEffects.healing_received_multiplier(t))
	assert_almost_eq(float(cursed), plain * 0.5, 1.0)


func test_blessed_regen_never_exceeds_max_hp() -> void:
	var t: Combatant = _target(100)
	t.hp = 99
	StatusEffects.apply(t, _load("blessed"), BattleFixtures.rng())
	var events: Array[BattleEvent] = StatusEffects.tick_round_end([t])
	assert_eq(t.hp, 100)
	assert_eq(BattleFixtures.first(events, BattleEvent.Type.HEAL).get_value(&"amount"), 1, "only the missing HP")
	StatusEffects.tick_round_end([t])
	assert_eq(t.hp, 100)
	assert_eq(t.effective_stat(&"defense"), 13, "10 × 1.25 rounded")


func test_sleep_skips_action_and_wears_off_on_hit() -> void:
	var sleeper: Combatant = _target()
	var attacker: Combatant = BattleFixtures.hero(StatBlock.create(100, 0, 40, 10, 0, 0, 10))
	var party: Array[Combatant] = [attacker]
	var enemies: Array[Combatant] = [sleeper]
	var resolver: ActionResolver = ActionResolver.new(party, enemies, BattleFixtures.rng())
	StatusEffects.apply(sleeper, _load("sleep"), BattleFixtures.rng())
	assert_false(sleeper.can_act())
	var skipped: Array[BattleEvent] = resolver.resolve(BattleAction.attack(sleeper, attacker))
	assert_eq(skipped.size(), 1)
	assert_eq(skipped[0].type, BattleEvent.Type.ACTION_SKIPPED)
	assert_eq(attacker.hp, 100, "no damage while asleep")
	var hit: Array[BattleEvent] = resolver.resolve(BattleAction.attack(attacker, sleeper))
	assert_false(sleeper.has_status(&"sleep"), "woken by the hit")
	assert_eq(BattleFixtures.count(hit, BattleEvent.Type.STATUS_REMOVED), 1)


func test_sleep_duration_is_rolled_in_range() -> void:
	var rng: RandomNumberGenerator = BattleFixtures.rng(8)
	var seen: Dictionary[int, bool] = {}
	for i: int in 200:
		seen[StatusEffects.roll_duration(_load("sleep"), rng)] = true
	assert_eq(seen.keys().size(), 3, "2, 3 and 4 all occur")
	for turns: int in seen:
		assert_true(turns >= 2 and turns <= 4)


func test_stun_applied_after_acting_costs_next_turn() -> void:
	var t: Combatant = _target()
	StatusEffects.apply(t, _load("stun"), BattleFixtures.rng())
	StatusEffects.tick_round_end([t])  # applied this round after t acted: kept
	assert_true(t.has_status(&"stun"), "still stunned for the next round")
	StatusEffects.blocking_status(t).blocked_this_round = true  # next round: turn lost
	StatusEffects.tick_round_end([t])
	assert_false(t.has_status(&"stun"))


func test_stun_applied_before_acting_lasts_one_turn() -> void:
	var t: Combatant = _target()
	StatusEffects.apply(t, _load("stun"), BattleFixtures.rng())
	StatusEffects.blocking_status(t).blocked_this_round = true
	StatusEffects.tick_round_end([t])
	assert_false(t.has_status(&"stun"))


func test_reapplying_refreshes_not_stacks() -> void:
	var t: Combatant = _target(100)
	var bleed: StatusEffectData = _load("bleed")
	StatusEffects.apply(t, bleed, BattleFixtures.rng())
	StatusEffects.tick_round_end([t])
	assert_eq(t.get_status(&"bleed").turns_left, 2)
	var events: Array[BattleEvent] = StatusEffects.apply(t, bleed, BattleFixtures.rng())
	assert_true(events[0].get_value(&"refreshed") as bool)
	assert_eq(t.statuses.size(), 1, "one bleed only")
	assert_eq(t.get_status(&"bleed").turns_left, 3, "duration refreshed")
	var hp_before: int = t.hp
	StatusEffects.tick_round_end([t])
	assert_eq(hp_before - t.hp, 5, "damage is not doubled")


func test_dot_can_defeat() -> void:
	var t: Combatant = _target(100)
	t.hp = 3
	StatusEffects.apply(t, _load("bleed"), BattleFixtures.rng())
	var events: Array[BattleEvent] = StatusEffects.tick_round_end([t])
	assert_false(t.is_alive())
	assert_eq(BattleFixtures.count(events, BattleEvent.Type.DEFEATED), 1)
	assert_true(t.statuses.is_empty(), "statuses cleared on defeat")


func test_cure_removes_listed_statuses() -> void:
	var t: Combatant = _target()
	StatusEffects.apply(t, _load("bleed"), BattleFixtures.rng())
	StatusEffects.apply(t, _load("curse"), BattleFixtures.rng())
	StatusEffects.cure(t, [_load("bleed")])
	assert_false(t.has_status(&"bleed"))
	assert_true(t.has_status(&"curse"))
	StatusEffects.cure(t, [])
	assert_true(t.statuses.is_empty())
