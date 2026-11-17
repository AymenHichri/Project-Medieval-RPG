class_name TitleScreen
extends Node2D
## Final title screen (PROJECT_PLAN.md Phase 7, UI_ASSET_CATALOG.md): a live in-engine background
## (the graveyard at night, with fog, under a slowly drifting camera), the Cinzel title over a
## dark gradient on the left, and red buttons New Game / Settings / Quit. Plays `music`.

const BACKDROP_MAP: String = "res://scenes/world/maps/graveyard_01.tscn"
const BACKDROP_PRESET: StringName = &"night"
## Camera drift: from the start view, this far and back, over this many seconds each way.
const DRIFT: Vector2 = Vector2(260, -60)
const DRIFT_SECONDS: float = 24.0

## Title music (`mus_menu`; null = silent until the slice audio is sourced).
@export var music: MusicTrack
## Builds the live background (off in tests that only check the menu).
@export var show_backdrop: bool = true

var backdrop: Map

@onready var _backdrop_slot: Node2D = %BackdropSlot
@onready var _camera: Camera2D = %Camera
@onready var _menu: Control = %Menu
@onready var _new_game: Button = %NewGameButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit: Button = %QuitButton
@onready var settings_menu: SettingsMenu = %SettingsMenu


func _ready() -> void:
	if show_backdrop:
		backdrop = (load(BACKDROP_MAP) as PackedScene).instantiate() as Map
		backdrop.backdrop = true
		backdrop.ambience_preset = BACKDROP_PRESET
		_backdrop_slot.add_child(backdrop)
	_camera.make_current()
	_start_drift()
	AudioManager.music.play(music)
	_new_game.pressed.connect(_on_new_game_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit.pressed.connect(_on_quit_pressed)
	settings_menu.closed.connect(_on_settings_closed)
	UiSounds.attach(_menu)
	_new_game.grab_focus()


func _start_drift() -> void:
	var start: Vector2 = _camera.position
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_camera, "position", start + DRIFT, DRIFT_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_camera, "position", start, DRIFT_SECONDS).set_trans(Tween.TRANS_SINE)


func _on_new_game_pressed() -> void:
	_set_buttons_disabled(true)
	# Not awaited past this point: this screen is freed during the change.
	SceneManager.start_new_game()


func _on_settings_pressed() -> void:
	_menu.visible = false
	settings_menu.open()


func _on_settings_closed() -> void:
	_menu.visible = true
	_settings_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _set_buttons_disabled(disabled: bool) -> void:
	for button: Button in [_new_game, _settings_button, _quit]:
		button.disabled = disabled
