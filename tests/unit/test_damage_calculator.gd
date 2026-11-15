extends TestCase
## DamageCalculator formulas (PROJECT_PLAN.md §6.3).

const SAMPLES: int = 500


func test_physical_minimum_is_one() -> void:
	var rng: RandomNumberGenerator = BattleFixtures.rng(3)
	for i: int in SAMPLES:
		assert_eq(DamageCalculator.physical(2, 200, rng), 1, "a hopeless attack still deals 1")


func test_physical_variance_bounds() -> void:
	var rng: RandomNumberGenerator = BattleFixtures.rng(7)
	# base = 40 × 0.5 − 20 × 0.25 = 15 → [13.125, 16.875] → rounded [13, 17]
	var low: int = 9999
	var high: int = 0
	for i: int in SAMPLES:
		var dmg: int = DamageCalculator.physical(40, 20, rng)
		low = mini(low, dmg)
		high = maxi(high, dmg)
	assert_true(low >= 13 and high <= 17, "range %d..%d outside 13..17" % [low, high])
	assert_true(high > low, "variance produces different values")


func test_critical_ignores_defense() -> void:
	var a: int = DamageCalculator.physical(40, 1000, BattleFixtures.rng(5), true)
	var b: int = DamageCalculator.physical(40, 0, BattleFixtures.rng(5), true)
	assert_eq(a, b, "defence has no effect on a critical")
	var normal: int = DamageCalculator.physical(40, 0, BattleFixtures.rng(5), false)
	assert_almost_eq(float(b), normal * DamageCalculator.CRIT_MULTIPLIER, 1.0, "critical ×1.5")


func test_crit_chance_formula() -> void:
	assert_almost_eq(DamageCalculator.crit_chance(0), 1.0 / 32.0, 0.0001)
	assert_almost_eq(DamageCalculator.crit_chance(64), 1.0 / 32.0 + 0.125, 0.0001)


func test_element_multipliers() -> void:
	var normal: int = DamageCalculator.physical(60, 0, BattleFixtures.rng(9))
	var weak: int = DamageCalculator.physical(60, 0, BattleFixtures.rng(9), false, 1.0, Elements.WEAK)
	var resist: int = DamageCalculator.physical(60, 0, BattleFixtures.rng(9), false, 1.0, Elements.RESIST)
	var immune: int = DamageCalculator.physical(60, 0, BattleFixtures.rng(9), false, 1.0, Elements.IMMUNE)
	assert_almost_eq(float(weak), normal * 2.0, 1.0, "weakness ×2")
	assert_almost_eq(float(resist), normal * 0.5, 1.0, "resistance ×0.5")
	assert_eq(immune, 0, "immunity deals 0")


func test_element_multiplier_reads_affinities() -> void:
	var target: Combatant = BattleFixtures.foe(StatBlock.create(10, 0, 1, 1))
	target.affinities = {Elements.Element.FIRE: Elements.WEAK}
	assert_eq(DamageCalculator.element_multiplier(target, Elements.Element.FIRE), 2.0)
	assert_eq(DamageCalculator.element_multiplier(target, Elements.Element.HOLY), 1.0, "missing = normal")


func test_defend_halves_damage() -> void:
	var normal: int = DamageCalculator.physical(60, 0, BattleFixtures.rng(11))
	var guarded: int = DamageCalculator.physical(60, 0, BattleFixtures.rng(11), false, 1.0, 1.0, true)
	assert_almost_eq(float(guarded), normal * 0.5, 1.0)


func test_damage_is_clamped() -> void:
	assert_eq(DamageCalculator.physical(99999, 0, BattleFixtures.rng(1), true, 10.0), DamageCalculator.MAX_DAMAGE)
	assert_eq(DamageCalculator.magical(99999, 9999, 0, BattleFixtures.rng(1), 2.0), DamageCalculator.MAX_DAMAGE)


func test_magic_formula_and_minimum() -> void:
	var rng: RandomNumberGenerator = BattleFixtures.rng(13)
	# base = 20 + 10 × 0.5 − 8 × 0.25 = 23
	for i: int in SAMPLES:
		var dmg: int = DamageCalculator.magical(20, 10, 8, rng)
		assert_true(dmg >= 20 and dmg <= 26, "magic %d outside 20..26" % dmg)
	# Huge spirit: floor of power × 0.25 = 10 → [8.75, 11.25]
	for i: int in SAMPLES:
		var low: int = DamageCalculator.magical(40, 0, 9999, rng)
		assert_true(low >= 9 and low <= 11, "minimum %d outside 9..11" % low)


func test_heal_formula() -> void:
	var rng: RandomNumberGenerator = BattleFixtures.rng(17)
	# 20 + 10 × 0.4 = 24, ±10% → [21.6, 26.4]
	for i: int in SAMPLES:
		var amount: int = DamageCalculator.heal(20, 10, rng)
		assert_true(amount >= 22 and amount <= 26, "heal %d outside 22..26" % amount)
	assert_almost_eq(float(DamageCalculator.heal(20, 10, BattleFixtures.rng(2), 0.5)),
			DamageCalculator.heal(20, 10, BattleFixtures.rng(2)) * 0.5, 1.0, "received multiplier")


func test_is_critical_is_deterministic_per_seed() -> void:
	var a: Array[bool] = []
	var b: Array[bool] = []
	var r1: RandomNumberGenerator = BattleFixtures.rng(21)
	var r2: RandomNumberGenerator = BattleFixtures.rng(21)
	for i: int in 50:
		a.append(DamageCalculator.is_critical(50, r1))
		b.append(DamageCalculator.is_critical(50, r2))
	assert_eq(a, b)
