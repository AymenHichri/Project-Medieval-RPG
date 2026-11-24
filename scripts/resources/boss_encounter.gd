class_name BossEncounter
extends Resource
## A fixed (non-random) fight started by a BossTrigger (Phase 10). Never fleeable. The second
## form of a boss lives on its EnemyData (`phase_two`).

@export var group: EncounterGroup
## All of these flags must be set for the fight to be available.
@export var required_flags: Array[StringName] = []
## Set on victory; while it is set the fight is not available again.
@export var defeated_flag: StringName = &""
@export var background: PackedScene
@export var music: MusicTrack


## True when the required flags are set and the boss has not been defeated yet.
func is_available(flags: Dictionary[StringName, Variant]) -> bool:
	if group == null:
		return false
	if not defeated_flag.is_empty() and bool(flags.get(defeated_flag, false)):
		return false
	for flag: StringName in required_flags:
		if not bool(flags.get(flag, false)):
			return false
	return true


## The BattleSetup for this fight: no fleeing, boss rules.
func make_setup() -> BattleSetup:
	var setup: BattleSetup = BattleSetup.new()
	setup.enemies = group.enemies.duplicate()
	setup.background = background
	setup.music = music
	setup.can_flee = false
	setup.is_boss = true
	setup.intro_text = group.intro_text
	setup.victory_flag = defeated_flag
	return setup
