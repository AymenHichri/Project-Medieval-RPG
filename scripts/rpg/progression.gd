class_name Progression
extends RefCounted
## Experience and level rules (PROJECT_PLAN.md §6.4). Stateless: PartyMember holds the level and
## XP, GrowthCurve the numbers.
##   xp_to_next(L) = round(xp_base × L^xp_exponent)
##   each stat gain = stat_gain_per_level ± 1 (never below 0)


## XP needed to go from `level` to `level + 1` (0 at or above the curve's max level).
static func xp_to_next(growth: GrowthCurve, level: int) -> int:
	if growth == null or level >= growth.max_level:
		return 0
	return maxi(1, roundi(growth.xp_base * pow(maxi(1, level), growth.xp_exponent)))


## Total XP needed to reach `level` from level 1 (0 for level 1).
static func total_xp_for_level(growth: GrowthCurve, level: int) -> int:
	var total: int = 0
	for l: int in range(1, mini(level, growth.max_level if growth != null else 1)):
		total += xp_to_next(growth, l)
	return total


## The level a character with `total_xp` has reached (capped at the curve's max level).
static func level_for_xp(growth: GrowthCurve, total_xp: int) -> int:
	if growth == null:
		return 1
	var level: int = 1
	var needed: int = 0
	while level < growth.max_level:
		needed += xp_to_next(growth, level)
		if total_xp < needed:
			break
		level += 1
	return level


## The stats gained on one level-up: the curve's gain ± 1 per stat (never negative).
static func roll_gains(growth: GrowthCurve, rng: RandomNumberGenerator) -> StatBlock:
	var base: StatBlock = growth.stat_gain_per_level if growth != null else null
	var gains: StatBlock = StatBlock.new()
	for stat: StringName in StatBlock.NAMES:
		var value: int = base.get_stat(stat) if base != null else 0
		gains.set(stat, maxi(0, value + rng.randi_range(-1, 1)))
	return gains


## Skills `data` learns on reaching exactly `level`.
static func skills_learned_at(data: CharacterData, level: int) -> Array[SkillData]:
	var out: Array[SkillData] = []
	if data == null:
		return out
	for unlock: SkillUnlock in data.skill_unlocks:
		if unlock != null and unlock.skill != null and unlock.level == level:
			out.append(unlock.skill)
	return out
