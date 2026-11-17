extends Node
## Autoload `DialogueManager`: runs JSON dialogues (`data/dialogue/*.json`) through a
## DialogueRunner and drives the dialogue box. Any node can call `start(id)`; the player can't move
## or interact while `is_active` is true (see `PlayerController.can_act()`).
## Supports multi-line text, speaker names, an optional portrait (passed by the NPC), choices,
## `goto`, `set_flag`, `give_item` and conditional entry (`conditions.if_flag` → `use`).

signal dialogue_started(dialogue_id: StringName)
signal dialogue_finished(dialogue_id: StringName)
## Emitted when the box asks for the next line.
signal _advanced
## Emitted when a choice is picked.
signal _chosen(index: int)

const DIALOGUE_BOX: PackedScene = preload("res://scenes/ui/dialogue_box.tscn")

var is_active: bool = false
## The runner of the open dialogue (null when none).
var runner: DialogueRunner

var _box: DialogueBox


func _ready() -> void:
	_box = DIALOGUE_BOX.instantiate() as DialogueBox
	add_child(_box)
	_box.advance_requested.connect(advance)
	_box.choice_selected.connect(choose)


## Runs a dialogue by id and returns when it is closed. Ignored while another one runs.
## `portrait` is shown beside every line that has a speaker.
func start(dialogue_id: StringName, portrait: Texture2D = null) -> void:
	if is_active:
		push_warning("DialogueManager: '%s' ignored, a dialogue is already open" % dialogue_id)
		return
	runner = DialogueRunner.open(dialogue_id, GameState)
	if runner == null:
		return
	is_active = true
	dialogue_started.emit(runner.dialogue_id)
	while not runner.is_finished():
		var speaker: String = runner.speaker()
		var choices: PackedStringArray = runner.choices()
		_box.show_line(speaker, runner.text(), portrait if not speaker.is_empty() else null, choices)
		if choices.is_empty():
			await _advanced
			runner.advance()
		else:
			var index: int = await _chosen
			runner.choose(index)
	var played: StringName = runner.dialogue_id
	runner = null
	_box.close()
	is_active = false
	dialogue_finished.emit(played)


## Moves past the current line (the box calls this on `accept`; tests call it directly).
## Ignored on a line with choices.
func advance() -> void:
	if is_active and runner != null and not runner.has_choices():
		_advanced.emit()


## Picks a choice of the current line (the box's buttons call this; tests call it directly).
func choose(index: int) -> void:
	if is_active and runner != null and runner.has_choices():
		_chosen.emit(index)


## The dialogue box (read-only use: tests and debugging).
func get_box() -> DialogueBox:
	return _box
