extends Control
## Placeholder title screen. Replaced by the final title screen in Phase 7.

const SPECIMEN_SCENE: String = "res://scenes/ui/debug/typography_specimen.tscn"
## First map of a new game and its spawn.
const START_MAP: String = "res://scenes/world/maps/village_01.tscn"
const START_SPAWN: StringName = &"start"

@onready var _new_game_button: Button = %NewGameButton
@onready var _specimen_button: Button = %SpecimenButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_specimen_button.pressed.connect(_on_specimen_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	GameState.new_game()
	# Not awaited: this title screen is freed during the change.
	SceneManager.change_map(START_MAP, START_SPAWN)


func _on_specimen_pressed() -> void:
	await SceneManager.fade_out()
	get_tree().change_scene_to_file(SPECIMEN_SCENE)
	await SceneManager.fade_in()


func _on_quit_pressed() -> void:
	get_tree().quit()
