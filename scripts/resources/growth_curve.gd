class_name GrowthCurve
extends Resource
## XP requirements and stat gains per level (applied by Progression in Phase 8).

@export var xp_base: int = 20
@export var xp_exponent: float = 1.5
## Stats added on each level-up.
@export var stat_gain_per_level: StatBlock
@export_range(1, 99) var max_level: int = 30


## Total XP needed to reach `level` (0 for level 1).
func xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	return roundi(xp_base * pow(level - 1, xp_exponent))
