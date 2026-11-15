class_name RateModifier
extends RefCounted
## A multiplier on the random-encounter rate (PROJECT_PLAN.md §6.2): an item ("Warding Torch
## ×0.25 for 200 steps"), an accessory, a story event or a difficulty mode. Kept by id in
## `GameState.encounter_rate_modifiers`; the EncounterTracker ticks them once per step.

## Multiplier applied to the per-step chance (0 = no encounters).
var mult: float = 1.0
## Steps before it expires; -1 = permanent.
var steps_left: int = -1


func _init(p_mult: float = 1.0, p_steps_left: int = -1) -> void:
	mult = maxf(0.0, p_mult)
	steps_left = p_steps_left


func is_permanent() -> bool:
	return steps_left < 0


## Product of all multipliers (1.0 when there are none).
static func product(modifiers: Dictionary[StringName, RateModifier]) -> float:
	var total: float = 1.0
	for id: StringName in modifiers:
		total *= modifiers[id].mult
	return total


## One step: counts down every timed modifier and removes the ones that reach 0.
## Returns the ids removed.
static func tick(modifiers: Dictionary[StringName, RateModifier]) -> Array[StringName]:
	var expired: Array[StringName] = []
	for id: StringName in modifiers:
		var modifier: RateModifier = modifiers[id]
		if modifier.is_permanent():
			continue
		modifier.steps_left -= 1
		if modifier.steps_left <= 0:
			expired.append(id)
	for id: StringName in expired:
		modifiers.erase(id)
	return expired
