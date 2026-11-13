extends Node
## Autoload `SaveManager`: JSON save slots in user://saves/. Implemented in Phase 11.
## Method names avoid `load()`/`save()` so they never shadow the global functions.

signal saved(slot: int)
signal loaded(slot: int)

const SLOT_COUNT: int = 3
const SAVE_DIR: String = "user://saves"


func save_slot(_slot: int) -> Error:
	return ERR_UNAVAILABLE


func load_slot(_slot: int) -> Error:
	return ERR_UNAVAILABLE


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


func list_slots() -> Array[int]:
	var result: Array[int] = []
	for slot: int in SLOT_COUNT:
		if has_save(slot):
			result.append(slot)
	return result


func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]
