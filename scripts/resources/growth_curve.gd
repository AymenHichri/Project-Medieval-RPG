class_name GrowthCurve
extends Resource
## XP requirements and stat gains per level (applied by Progression, PROJECT_PLAN.md §6.4).
## XP from level L to L+1 = round(xp_base × L^xp_exponent).

@export var xp_base: int = 12
@export var xp_exponent: float = 1.6
## Stats added on each level-up (± 1 per stat, rolled by Progression).
@export var stat_gain_per_level: StatBlock
@export_range(1, 99) var max_level: int = 30


## Total XP needed to reach `level` (0 for level 1).
func xp_for_level(level: int) -> int:
	return Progression.total_xp_for_level(self, level)
