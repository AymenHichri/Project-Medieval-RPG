class_name DamageCalculator
extends RefCounted
## Damage and healing formulas (PROJECT_PLAN.md §6.3). Pure static functions; the RNG is passed in.
## Order: base → variance → critical → element → Defend → round → clamp.

## Physical: share of the attacker's stat that becomes damage.
const PHYS_ATTACK_FACTOR: float = 0.5
## Physical: share of the target's defence subtracted.
const PHYS_DEFENSE_FACTOR: float = 0.25
## Physical base never falls below this before multipliers.
const PHYS_MIN_BASE: float = 1.0
## Random spread applied to physical and magic damage.
const VARIANCE_MIN: float = 0.875
const VARIANCE_MAX: float = 1.125
## Critical chance = CRIT_BASE_CHANCE + luck / CRIT_LUCK_DIVISOR.
const CRIT_BASE_CHANCE: float = 1.0 / 32.0
const CRIT_LUCK_DIVISOR: float = 512.0
## Criticals ignore defence and multiply damage by this.
const CRIT_MULTIPLIER: float = 1.5
## Magic: share of the caster's magic added to the spell power.
const MAG_MAGIC_FACTOR: float = 0.5
## Magic: share of the target's spirit subtracted.
const MAG_SPIRIT_FACTOR: float = 0.25
## Magic base never falls below this fraction of the spell power.
const MAG_MIN_POWER_FRACTION: float = 0.25
## Damage multiplier on a defending target.
const DEFEND_MULTIPLIER: float = 0.5
const MAX_DAMAGE: int = 9999
## Healing: share of the caster's magic added to the spell power.
const HEAL_MAGIC_FACTOR: float = 0.4
## Healing spread (±10%).
const HEAL_VARIANCE: float = 0.1


## Physical damage. `power_mult` scales the base (a skill with power 150 → 1.5).
static func physical(attack: int, defense: int, rng: RandomNumberGenerator, critical: bool = false,
		power_mult: float = 1.0, element_mult: float = 1.0, defending: bool = false) -> int:
	var defense_part: float = 0.0 if critical else defense * PHYS_DEFENSE_FACTOR
	var base: float = maxf(PHYS_MIN_BASE, attack * PHYS_ATTACK_FACTOR - defense_part) * power_mult
	if critical:
		base *= CRIT_MULTIPLIER
	return _finish(base * variance(rng), element_mult, defending)


## Magic damage of a spell with `power`.
static func magical(power: int, magic: int, spirit: int, rng: RandomNumberGenerator,
		element_mult: float = 1.0, defending: bool = false) -> int:
	var base: float = maxf(power * MAG_MIN_POWER_FRACTION,
			power + magic * MAG_MAGIC_FACTOR - spirit * MAG_SPIRIT_FACTOR)
	return _finish(base * variance(rng), element_mult, defending)


## HP restored by a healing spell. `received_mult` comes from the target's statuses (Curse 0.5).
static func heal(power: int, magic: int, rng: RandomNumberGenerator, received_mult: float = 1.0) -> int:
	var amount: float = (power + magic * HEAL_MAGIC_FACTOR) * rng.randf_range(1.0 - HEAL_VARIANCE, 1.0 + HEAL_VARIANCE)
	return clampi(roundi(amount * received_mult), 0, MAX_DAMAGE)


static func crit_chance(luck: int) -> float:
	return CRIT_BASE_CHANCE + luck / CRIT_LUCK_DIVISOR


static func is_critical(luck: int, rng: RandomNumberGenerator) -> bool:
	return rng.randf() < crit_chance(luck)


## Multiplier `target` takes from `element`.
static func element_multiplier(target: Combatant, element: Elements.Element) -> float:
	return target.affinity(element)


static func variance(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(VARIANCE_MIN, VARIANCE_MAX)


static func _finish(amount: float, element_mult: float, defending: bool) -> int:
	amount *= element_mult
	if defending:
		amount *= DEFEND_MULTIPLIER
	return clampi(roundi(amount), 0, MAX_DAMAGE)
