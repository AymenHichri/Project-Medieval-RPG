class_name GameOverScreen
extends Control
## Shown when the whole party falls (PROJECT_PLAN.md Phase 7). "Return to Title" is the only way
## on until saving exists (Phase 11 adds "Load last save"). SceneManager plays `jng_gameover`.

@onready var _title_button: Button = %TitleButton


func _ready() -> void:
	_title_button.pressed.connect(_on_title_pressed)
	UiSounds.attach(self)
	_title_button.grab_focus()


func _on_title_pressed() -> void:
	_title_button.disabled = true
	SceneManager.to_title()
