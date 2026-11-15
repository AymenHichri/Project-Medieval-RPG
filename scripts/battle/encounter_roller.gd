class_name EncounterRoller
extends RefCounted
## Pure random-encounter rules (PROJECT_PLAN.md §6.2): whether a step starts a battle, which
## group is met, and the BattleSetup for it. No nodes, RNG passed in.


## Rolls for a battle on a step. `steps_since_last` counts this step (1 = the first step after
## a reset), so the first `table.grace_steps` steps never roll. Chance per step =
## `base_chance_per_step × multiplier`.
static func should_trigger(steps_since_last: int, table: EncounterTable, multiplier: float,
		rng: RandomNumberGenerator) -> bool:
	if table == null or steps_since_last <= table.grace_steps:
		return false
	var chance: float = table.base_chance_per_step * maxf(0.0, multiplier)
	if chance <= 0.0:
		return false
	return rng.randf() < chance


## The groups of `table` the flags allow.
static func eligible_groups(table: EncounterTable, flags: Dictionary[StringName, Variant]) -> Array[EncounterGroup]:
	var out: Array[EncounterGroup] = []
	if table == null:
		return out
	for group: EncounterGroup in table.groups:
		if group != null and group.is_eligible(flags):
			out.append(group)
	return out


## Weighted random pick among the eligible groups; null when none is eligible.
static func pick_group(table: EncounterTable, flags: Dictionary[StringName, Variant],
		rng: RandomNumberGenerator) -> EncounterGroup:
	var groups: Array[EncounterGroup] = eligible_groups(table, flags)
	var total: int = 0
	for group: EncounterGroup in groups:
		total += group.weight
	if total <= 0:
		return null
	var roll: int = rng.randi_range(0, total - 1)
	for group: EncounterGroup in groups:
		roll -= group.weight
		if roll < 0:
			return group
	return groups[groups.size() - 1]


## The BattleSetup for meeting `group` in a zone using `table`.
static func make_setup(group: EncounterGroup, table: EncounterTable) -> BattleSetup:
	var setup: BattleSetup = BattleSetup.new()
	setup.enemies = group.enemies.duplicate()
	setup.can_flee = group.can_flee
	setup.is_rare = group.is_rare
	setup.intro_text = group.intro_text
	if table != null:
		setup.background = table.background
		setup.music = table.music
	return setup
