class_name EnemyData
extends Resource
## An enemy definition. Read-only at runtime: battles wrap it in a Combatant.

@export var id: StringName
@export var display_name: String = ""
@export var stats: StatBlock
## Damage multiplier per element (missing = 1.0). See Elements.
@export var affinities: Dictionary[Elements.Element, float] = {}
@export var skills: Array[SkillData] = []
## Null = plain attacks on random targets.
@export var ai: AIProfile
@export var xp: int = 0
@export var gold: int = 0
@export var drops: Array[DropEntry] = []
@export var visual: CombatantVisual
## Statuses that never stick to this enemy.
@export var status_immunities: Array[StatusEffectData] = []
## Actions it takes each round (Phase 10: the boss acts twice; each is chosen separately).
@export_range(1, 3) var actions_per_round: int = 1
## Second form the enemy switches to once its HP falls to `phase_two_at_hp_pct`.
@export var phase_two: EnemyData
@export_range(0.0, 1.0, 0.05) var phase_two_at_hp_pct: float = 0.5
