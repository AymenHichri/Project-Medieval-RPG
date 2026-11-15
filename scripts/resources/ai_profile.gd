class_name AIProfile
extends Resource
## How an enemy picks its action each round (see EnemyAI).

enum TargetStrategy { RANDOM, LOWEST_HP, HIGHEST_ATTACK }

## Relative weight of a plain attack.
@export_range(0, 1000) var attack_weight: int = 1
## Relative weight of each skill (skills the enemy cannot afford are skipped).
@export var skill_weights: Dictionary[SkillData, int] = {}
## How single-target offensive actions choose a target.
@export var target_strategy: TargetStrategy = TargetStrategy.RANDOM
## When an ally (or itself) is below this HP fraction and a HEAL skill is affordable, heal it.
## 0 disables the rule.
@export_range(0.0, 1.0, 0.05) var heal_below_hp_pct: float = 0.0
