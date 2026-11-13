class_name DialogueBox
extends CanvasLayer
## Message box at the bottom of the screen (PROJECT_PLAN.md §6.5), owned by DialogueManager.
## Shows one line at a time; `accept` asks the manager for the next line. While open it
## swallows `accept`, so the press that closes it never reaches the player's InteractionProbe.

signal advance_requested

## Process frame on which the box opened: the press that opened it must not also advance it.
var _opened_frame: int = -1

@onready var _panel: PanelContainer = %Panel
@onready var _speaker: Label = %Speaker
@onready var _text: Label = %Text


func _ready() -> void:
	close()


## Shows a line. An empty speaker hides the name (examine texts).
func show_line(speaker: String, text: String) -> void:
	_speaker.text = speaker
	_speaker.visible = not speaker.is_empty()
	_text.text = text
	if not _panel.visible:
		_opened_frame = Engine.get_process_frames()
	_panel.visible = true


func close() -> void:
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible


func get_text() -> String:
	return _text.text


func get_speaker() -> String:
	return _speaker.text


func _unhandled_input(event: InputEvent) -> void:
	if not _panel.visible or not event.is_action_pressed(&"accept") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if Engine.get_process_frames() != _opened_frame:
		advance_requested.emit()
