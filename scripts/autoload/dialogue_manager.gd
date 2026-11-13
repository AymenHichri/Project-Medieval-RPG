extends Node
## Autoload `DialogueManager`: runs JSON dialogues (`data/dialogue/*.json`) and drives the
## dialogue box. Any node can call `start(id)`; the player can't move or interact while
## `is_active` is true (see `PlayerController.can_act()`).
## Phase 3: lines are shown in order (examine texts). Flags, items, goto and choices: Phase 7.

signal dialogue_started(dialogue_id: StringName)
signal dialogue_finished(dialogue_id: StringName)
## Emitted when the box asks for the next line.
signal _advanced

const DIALOGUE_BOX: PackedScene = preload("res://scenes/ui/dialogue_box.tscn")

var is_active: bool = false

var _box: DialogueBox


func _ready() -> void:
	_box = DIALOGUE_BOX.instantiate() as DialogueBox
	add_child(_box)
	_box.advance_requested.connect(advance)


## Run a dialogue by id and return when it is closed. Ignored while another one runs.
func start(dialogue_id: StringName) -> void:
	if is_active:
		push_warning("DialogueManager: '%s' ignored, a dialogue is already open" % dialogue_id)
		return
	var data: Dictionary = DialogueData.load_dialogue(dialogue_id)
	if data.is_empty():
		return
	is_active = true
	dialogue_started.emit(dialogue_id)
	for value: Variant in data["lines"] as Array:
		var line: Dictionary = value as Dictionary
		_box.show_line(str(line.get("speaker", "")), str(line["text"]))
		await _advanced
	_box.close()
	is_active = false
	dialogue_finished.emit(dialogue_id)


## Moves to the next line (the box calls this on `accept`; tests call it directly).
func advance() -> void:
	if is_active:
		_advanced.emit()


## The dialogue box (read-only use: tests and debugging).
func get_box() -> DialogueBox:
	return _box
