class_name ExplorationHud
extends CanvasLayer
## Minimal exploration HUD (PROJECT_PLAN.md §6.5): the dfgui MENU button in the top-right corner,
## which opens the pause menu (as does the `menu` action). Mouse only: the keyboard and gamepad
## use `menu`.

signal menu_pressed

@onready var menu_button: TextureButton = %MenuButton


func _ready() -> void:
	menu_button.pressed.connect(menu_pressed.emit)
	UiSounds.attach(menu_button)
