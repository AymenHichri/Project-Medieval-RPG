class_name QuestStage
extends Resource
## One step of a QuestData (PROJECT_PLAN.md §6.4): the journal text shown while it is the current
## stage, and the GameState flags that finish it (all of them; e.g. three graves searched).

## Journal text while this is the current stage.
@export_multiline var text: String = ""
## The stage is done once every one of these flags is set (truthy). Never empty.
@export var flags: Array[StringName] = []
## Shown after the text while more than one flag is needed ("Graves searched").
@export var progress_label: String = ""
## The quest giver is waiting for the player at this stage: their NPC shows the quest marker.
@export var turn_in: bool = false


## How many of `flags` are set in `state_flags`.
func flags_done(state_flags: Dictionary[StringName, Variant]) -> int:
	var done: int = 0
	for flag: StringName in flags:
		if bool(state_flags.get(flag, false)):
			done += 1
	return done


func is_done(state_flags: Dictionary[StringName, Variant]) -> bool:
	return not flags.is_empty() and flags_done(state_flags) == flags.size()
