class_name EncounterGroup
extends Resource
## One possible random-encounter line-up in an EncounterTable (PROJECT_PLAN.md §6.2).

@export var enemies: Array[EnemyData] = []
## Relative pick weight among the eligible groups of the table (0 = never picked).
@export_range(0, 1000) var weight: int = 10
## A rare group: an ordinary group with a low weight; the battle intro marks it as special.
@export var is_rare: bool = false
## Only eligible while this GameState flag is set (empty = always).
@export var required_flag: StringName = &""
## Not eligible while this GameState flag is set (empty = never blocked).
@export var forbidden_flag: StringName = &""
@export var can_flee: bool = true
## Intro line for the battle. Empty = generated ("Wolf A and Wolf B appear!").
@export var intro_text: String = ""


## True when the flags allow this group (a flag counts as set when its value is truthy).
func is_eligible(flags: Dictionary[StringName, Variant]) -> bool:
	if weight <= 0 or enemies.is_empty():
		return false
	if not required_flag.is_empty() and not bool(flags.get(required_flag, false)):
		return false
	if not forbidden_flag.is_empty() and bool(flags.get(forbidden_flag, false)):
		return false
	return true
