extends Control
## Typography specimen (FONT_CATALOG.md §2): every Theme type variation on Gimble's panels.
## F2 toggles 1920×1080 fullscreen / 1280×720 windowed. Esc (cancel) returns to the title screen.

const TITLE_SCENE: String = "res://scenes/ui/title_screen.tscn"
const SAMPLES: Array[Array] = [
	["TitleLabel", "The Hollow Bells"],
	["HeaderLabel", "Chapter I — Ashfall"],
	["NameLabel", "Elder Maren"],
	["BodyLabel", "The bells stopped ringing three nights ago. Since then the dead walk the old road, and no one sleeps."],
	["LoreLabel", "\"What the earth keeps, the earth remembers.\""],
	["SmallLabel", "Restores 50 HP to one ally. Cannot be used at full health."],
	["NumericLabel", "HP 112/130    MP 18/24    Gold 1,048"],
	["DamageNumber", "247"],
]

@onready var _list: VBoxContainer = %List
@onready var _mode_label: Label = %ModeLabel
var _hp_label: Label
var _hp: int = 130


func _ready() -> void:
	for sample: Array in SAMPLES:
		var caption: Label = Label.new()
		caption.theme_type_variation = &"SmallLabel"
		caption.text = sample[0]
		_list.add_child(caption)
		var label: Label = Label.new()
		label.theme_type_variation = StringName(sample[0])
		label.text = sample[1]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(label)
	var caption_hp: Label = Label.new()
	caption_hp.theme_type_variation = &"SmallLabel"
	caption_hp.text = "NumericLabel (changing value: width must not jitter)"
	_list.add_child(caption_hp)
	_hp_label = Label.new()
	_hp_label.theme_type_variation = &"NumericLabel"
	_list.add_child(_hp_label)
	var timer: Timer = Timer.new()
	timer.wait_time = 0.15
	timer.autostart = true
	timer.timeout.connect(_tick_hp)
	add_child(timer)
	_tick_hp()
	_update_mode_label()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_F2:
		_toggle_resolution()
	elif event.is_action_pressed(&"cancel"):
		get_tree().change_scene_to_file(TITLE_SCENE)


func _tick_hp() -> void:
	_hp = (_hp + 37) % 131
	_hp_label.text = "HP %3d/130" % _hp


func _toggle_resolution() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_mode_label.call_deferred()


func _update_mode_label() -> void:
	var size: Vector2i = DisplayServer.window_get_size()
	_mode_label.text = "Window %d×%d — F2: toggle 1080p fullscreen / 720p windowed — Esc: back" % [size.x, size.y]
