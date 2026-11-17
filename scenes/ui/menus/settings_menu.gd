class_name SettingsMenu
extends Control
## Settings screen (PROJECT_PLAN.md Phase 7), reachable from the title and pause menus: Master /
## Music / SFX / Ambience sliders (applied immediately), fullscreen, text speed. Closing (Back or
## `cancel`) saves to `user://settings.cfg` and emits `closed`.

signal closed

## Where `close()` saves (tests point it elsewhere).
var save_path: String = Settings.PATH

var _sliders: Dictionary[StringName, HSlider] = {}

@onready var _grid: GridContainer = %Grid
@onready var _fullscreen: CheckBox = %Fullscreen
@onready var _text_speed: OptionButton = %TextSpeed
@onready var _back: Button = %Back


func _ready() -> void:
	visible = false
	for bus: StringName in Settings.VOLUME_BUSES:
		var label: Label = Label.new()
		label.text = String(bus)
		label.theme_type_variation = &"BodyLabel"
		var slider: HSlider = HSlider.new()
		slider.name = "%sSlider" % bus
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.custom_minimum_size = Vector2(420, 40)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.value_changed.connect(_on_volume_changed.bind(bus))
		_grid.add_child(label)
		_grid.add_child(slider)
		_sliders[bus] = slider
	# Fullscreen and text speed rows sit after the sliders.
	_grid.move_child(%FullscreenLabel, -1)
	_grid.move_child(_fullscreen, -1)
	_grid.move_child(%TextSpeedLabel, -1)
	_grid.move_child(_text_speed, -1)
	for i: int in Settings.TEXT_SPEED_NAMES.size():
		_text_speed.add_item(Settings.TEXT_SPEED_NAMES[i], i)
	_fullscreen.toggled.connect(Settings.set_fullscreen)
	_text_speed.item_selected.connect(_on_text_speed_selected)
	_back.pressed.connect(close)
	UiSounds.attach(self)


## Shows the current values and focuses the first slider.
func open() -> void:
	for bus: StringName in _sliders:
		_sliders[bus].set_value_no_signal(Settings.volume(bus))
	_fullscreen.set_pressed_no_signal(Settings.fullscreen)
	_text_speed.select(int(Settings.text_speed))
	visible = true
	_sliders[Settings.VOLUME_BUSES[0]].grab_focus()


func close() -> void:
	if not visible:
		return
	Settings.save(save_path)
	visible = false
	closed.emit()


func slider(bus: StringName) -> HSlider:
	return _sliders.get(bus) as HSlider


func _on_volume_changed(value: float, bus: StringName) -> void:
	Settings.set_volume(bus, value)


func _on_text_speed_selected(index: int) -> void:
	Settings.set_text_speed(index as Settings.TextSpeed)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		UiSounds.cancel()
		close()
