class_name BattleMessage
extends PanelContainer
## The message line at the top of the battle screen ("A Wolf appears!", "Knight uses Ember!").


@onready var _text: Label = %Text


func _ready() -> void:
	clear()


func show_text(message: String) -> void:
	_text.text = message
	visible = not message.is_empty()


func clear() -> void:
	_text.text = ""
	visible = false


func get_text() -> String:
	return _text.text
