class_name IntroCard
extends Control
## The short text card between Title → New Game and the first map (PROJECT_PLAN.md Phase 7).
## The lines fade in one after another; `accept` shows them all at once. Then the Continue button
## (focused) leads to the village. `finish()` does the same from code (tests).

signal finished

## Seconds each line takes to fade in, and the pause before the next one.
const LINE_FADE_SECONDS: float = 1.2
const LINE_GAP_SECONDS: float = 0.6

var _done: bool = false
var _tween: Tween

@onready var _lines: VBoxContainer = %Lines
@onready var _continue: Button = %Continue


func _ready() -> void:
	_continue.pressed.connect(finish)
	UiSounds.attach(_continue)
	_continue.modulate.a = 0.0
	_tween = create_tween()
	for child: Node in _lines.get_children():
		var line: Control = child as Control
		line.modulate.a = 0.0
		_tween.tween_property(line, "modulate:a", 1.0, LINE_FADE_SECONDS)
		_tween.tween_interval(LINE_GAP_SECONDS)
	_tween.tween_property(_continue, "modulate:a", 1.0, 0.4)
	_tween.tween_callback(_continue.grab_focus)


func all_lines_shown() -> bool:
	return _tween == null or not _tween.is_running()


## Shows every line at once.
func show_all() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	for child: Node in _lines.get_children():
		(child as Control).modulate.a = 1.0
	_continue.modulate.a = 1.0
	_continue.grab_focus()


## Leaves the card for the first map (once).
func finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	SceneManager.enter_world()


func _unhandled_input(event: InputEvent) -> void:
	if not (event.is_action_pressed(&"accept") or event.is_action_pressed(&"ui_accept")) or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if all_lines_shown():
		# Keys mapped to `accept` but not `ui_accept` (E); Enter/Space press the focused button.
		_continue.pressed.emit()
	else:
		show_all()
