extends TestCase
## TurnOrder: priority (Flee, Defend), agility, stable ties, determinism.


func _unit(agility: int) -> Combatant:
	return BattleFixtures.foe(StatBlock.create(10, 0, 1, 1, 0, 0, agility))


func test_higher_agility_first_without_variance() -> void:
	var slow: Combatant = _unit(5)
	var fast: Combatant = _unit(20)
	var mid: Combatant = _unit(10)
	var actions: Array[BattleAction] = [BattleAction.attack(slow, fast), BattleAction.attack(fast, slow), BattleAction.attack(mid, slow)]
	var sorted: Array[BattleAction] = TurnOrder.sort(actions, BattleFixtures.rng(), false)
	assert_eq(sorted[0].actor, fast)
	assert_eq(sorted[1].actor, mid)
	assert_eq(sorted[2].actor, slow)


func test_defend_always_first() -> void:
	var slow: Combatant = _unit(1)
	var fast: Combatant = _unit(999)
	for seed_value: int in 20:
		var actions: Array[BattleAction] = [BattleAction.attack(fast, slow), BattleAction.defend(slow)]
		var sorted: Array[BattleAction] = TurnOrder.sort(actions, BattleFixtures.rng(seed_value))
		assert_eq(sorted[0].kind, BattleAction.Kind.DEFEND, "seed %d" % seed_value)


func test_flee_before_defend() -> void:
	var a: Combatant = _unit(1)
	var b: Combatant = _unit(50)
	var actions: Array[BattleAction] = [BattleAction.defend(b), BattleAction.flee(a)]
	assert_eq(TurnOrder.sort(actions, BattleFixtures.rng(), false)[0].kind, BattleAction.Kind.FLEE)


func test_stable_tie_break() -> void:
	var units: Array[Combatant] = [_unit(10), _unit(10), _unit(10), _unit(10)]
	var actions: Array[BattleAction] = []
	for u: Combatant in units:
		actions.append(BattleAction.defend(u))
	var sorted: Array[BattleAction] = TurnOrder.sort(actions, BattleFixtures.rng(), false)
	for i: int in units.size():
		assert_eq(sorted[i].actor, units[i], "tie keeps submission order at %d" % i)


func test_same_seed_same_order() -> void:
	var units: Array[Combatant] = []
	for agi: int in [10, 11, 12, 13, 14, 15]:
		units.append(_unit(agi))
	var actions: Array[BattleAction] = []
	for u: Combatant in units:
		actions.append(BattleAction.attack(u, units[0]))
	var first_order: Array[BattleAction] = TurnOrder.sort(actions, BattleFixtures.rng(99))
	var second_order: Array[BattleAction] = TurnOrder.sort(actions, BattleFixtures.rng(99))
	assert_eq(first_order, second_order)


func test_input_is_not_modified() -> void:
	var a: Combatant = _unit(1)
	var b: Combatant = _unit(2)
	var actions: Array[BattleAction] = [BattleAction.attack(a, b), BattleAction.attack(b, a)]
	TurnOrder.sort(actions, BattleFixtures.rng(), false)
	assert_eq(actions[0].actor, a)
