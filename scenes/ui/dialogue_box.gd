class_name DialogueBox
extends CanvasLayer
## Message box at the bottom of the screen (PROJECT_PLAN.md §6.5, UI_ASSET_CATALOG.md), owned by
## DialogueManager: Gimble's panel, framed 256 px portrait (when the speaker has one), dfgui name
## plate with the Cinzel speaker name, Alegreya body text revealed by a typewriter (speed from
## Settings, throttled tick sound), a bobbing gauntlet continue indicator, and choice buttons.
## `accept` first completes a line still typing, then asks the manager for the next line. While
## open it swallows `accept`, so the press that closes it never reaches the player's probe.

signal advance_requested
signal choice_selected(index: int)

## The typewriter plays the tick sound every this many revealed characters.
const TICK_EVERY_CHARS: int = 3
## Continue indicator bob: pixels and seconds per cycle (2-frame step, not a smooth slide).
const BOB_PIXELS: float = 6.0
const BOB_SECONDS: float = 0.5

## Process frame on which the box opened: the press that opened it must not also advance it.
var _opened_frame: int = -1
## Characters revealed so far (fractional while typing).
var _revealed: float = 0.0
var _total_chars: int = 0
var _last_tick_chars: int = 0
var _choice_texts: PackedStringArray = []
var _bob_time: float = 0.0
## The continue indicator's anchor offsets at rest (it bobs by shifting them, so it stays
## anchored to the right edge whatever the box's width).
var _continue_top: float = 0.0
var _continue_bottom: float = 0.0

@onready var _panel: PanelContainer = %Panel
@onready var _portrait_frame: Control = %PortraitFrame
@onready var _portrait: TextureRect = %Portrait
@onready var _name_plate: Control = %NamePlate
@onready var _speaker: Label = %Speaker
@onready var _text: Label = %Text
@onready var _choices: VBoxContainer = %Choices
@onready var _continue: TextureRect = %Continue


func _ready() -> void:
	_continue_top = _continue.offset_top
	_continue_bottom = _continue.offset_bottom
	close()


## Shows a line. An empty speaker hides the name plate (examine texts); a null portrait hides the
## portrait. `choices` (if any) appear as buttons once the text has finished typing.
func show_line(speaker: String, text: String, portrait: Texture2D = null,
		choices: PackedStringArray = []) -> void:
	_speaker.text = speaker
	_name_plate.visible = not speaker.is_empty()
	_portrait.texture = portrait
	_portrait_frame.visible = portrait != null
	_text.text = text
	_total_chars = _text.get_total_character_count()
	_choice_texts = choices
	_clear_choices()
	if not _panel.visible:
		_opened_frame = Engine.get_process_frames()
	_panel.visible = true
	_revealed = 0.0
	_last_tick_chars = 0
	if Settings.chars_per_second() <= 0.0:
		finish_typing()
	else:
		_text.visible_characters = 0
		_continue.visible = false


## Reveals the rest of the line at once (and shows its choices).
func finish_typing() -> void:
	_revealed = _total_chars
	_text.visible_characters = -1
	if not _choice_texts.is_empty() and _choices.get_child_count() == 0:
		_build_choices()
	_continue.visible = _choice_texts.is_empty()


func is_typing() -> bool:
	return _panel.visible and _text.visible_characters >= 0 and _text.visible_characters < _total_chars


func close() -> void:
	_panel.visible = false
	_clear_choices()
	_choice_texts = []


func is_open() -> bool:
	return _panel.visible


func get_text() -> String:
	return _text.text


func get_speaker() -> String:
	return _speaker.text


func get_portrait() -> Texture2D:
	return _portrait.texture if _portrait_frame.visible else null


## The choice buttons currently shown (empty while typing or on a line without choices).
func get_choice_buttons() -> Array[Button]:
	var out: Array[Button] = []
	for child: Node in _choices.get_children():
		if child is Button and not child.is_queued_for_deletion():
			out.append(child as Button)
	return out


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	if is_typing():
		_revealed += delta * Settings.chars_per_second()
		var shown: int = mini(floori(_revealed), _total_chars)
		_text.visible_characters = shown
		if shown - _last_tick_chars >= TICK_EVERY_CHARS:
			_last_tick_chars = shown
			UiSounds.tick()
		if shown >= _total_chars:
			finish_typing()
	if _continue.visible:
		_bob_time = fmod(_bob_time + delta, BOB_SECONDS)
		var lift: float = BOB_PIXELS if _bob_time < BOB_SECONDS / 2.0 else 0.0
		_continue.offset_top = _continue_top - lift
		_continue.offset_bottom = _continue_bottom - lift


func _unhandled_input(event: InputEvent) -> void:
	if not _panel.visible or not event.is_action_pressed(&"accept") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if Engine.get_process_frames() == _opened_frame:
		return
	if is_typing():
		finish_typing()
		return
	if not _choice_texts.is_empty():
		# Keys mapped to `accept` but not `ui_accept` (E) still pick the focused choice.
		for button: Button in get_choice_buttons():
			if button.has_focus():
				button.pressed.emit()
				return
		return
	advance_requested.emit()


func _build_choices() -> void:
	for i: int in _choice_texts.size():
		var button: Button = Button.new()
		button.text = _choice_texts[i]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_choice_pressed.bind(i))
		_choices.add_child(button)
	UiSounds.attach(_choices)
	_choices.visible = true
	_focus_first_choice.call_deferred()


func _focus_first_choice() -> void:
	var buttons: Array[Button] = get_choice_buttons()
	if not buttons.is_empty() and buttons[0].is_inside_tree() and buttons[0].is_visible_in_tree():
		buttons[0].grab_focus()


func _clear_choices() -> void:
	for child: Node in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	_choices.visible = false


func _on_choice_pressed(index: int) -> void:
	if _choice_texts.is_empty():
		return
	_choice_texts = []
	_clear_choices()
	choice_selected.emit(index)
