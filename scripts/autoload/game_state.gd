extends Node
## Autoload `GameState`: the data of the current play session.
## Phase 1 skeleton: flags and gold. Party, inventory, quests and serialisation arrive in later phases.

signal flag_changed(flag: StringName, value: Variant)
signal gold_changed(gold: int)

var gold: int = 0
var flags: Dictionary[StringName, Variant] = {}
var current_map: String = ""
var play_time: float = 0.0


func new_game() -> void:
	gold = 0
	flags.clear()
	current_map = ""
	play_time = 0.0


func set_flag(flag: StringName, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(flag, default)


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	gold_changed.emit(gold)
