class_name Settings
extends RefCounted
## Player settings (PROJECT_PLAN.md Phase 7, AUDIO_GUIDELINES.md §5): bus volumes as linear 0..1,
## fullscreen and text speed. Stored in `user://settings.cfg`, applied to the audio buses with
## `linear_to_db` and to the window. Static: there is one set of settings per game, and keeping it
## out of the autoloads keeps the autoload count at five. SceneManager loads it on start-up.

enum TextSpeed { SLOW, NORMAL, FAST, INSTANT }

const PATH: String = "user://settings.cfg"
## The sliders of the settings menu: bus name → label. SFX also drives the UI bus.
const VOLUME_BUSES: Array[StringName] = [&"Master", &"Music", &"SFX", &"Ambience"]
const DEFAULT_VOLUME: float = 0.8
const TEXT_SPEED_NAMES: PackedStringArray = ["Slow", "Normal", "Fast", "Instant"]
## Typewriter speed in characters per second (0 = the whole line at once).
const CHARS_PER_SECOND: Array[float] = [30.0, 60.0, 120.0, 0.0]

static var volumes: Dictionary[StringName, float] = {}
static var fullscreen: bool = false
static var text_speed: TextSpeed = TextSpeed.NORMAL


static func reset_to_defaults() -> void:
	volumes.clear()
	for bus: StringName in VOLUME_BUSES:
		volumes[bus] = DEFAULT_VOLUME if bus != &"Master" else 1.0
	fullscreen = false
	text_speed = TextSpeed.NORMAL


static func volume(bus: StringName) -> float:
	if volumes.is_empty():
		reset_to_defaults()
	return volumes.get(bus, 1.0) as float


## Sets and applies one bus volume (linear 0..1).
static func set_volume(bus: StringName, linear: float) -> void:
	if volumes.is_empty():
		reset_to_defaults()
	volumes[bus] = clampf(linear, 0.0, 1.0)
	_apply_volume(bus)


static func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_window()


static func set_text_speed(speed: TextSpeed) -> void:
	text_speed = speed


## Characters per second of the dialogue typewriter (0 = instant).
static func chars_per_second() -> float:
	return CHARS_PER_SECOND[text_speed]


## Reads `path` (missing or unreadable → defaults) and applies everything.
static func load_and_apply(path: String = PATH) -> void:
	reset_to_defaults()
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) == OK:
		for bus: StringName in VOLUME_BUSES:
			volumes[bus] = clampf(float(config.get_value("audio", String(bus), volumes[bus])), 0.0, 1.0)
		fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
		text_speed = clampi(int(config.get_value("game", "text_speed", text_speed)), 0, TextSpeed.size() - 1) as TextSpeed
	apply()


static func save(path: String = PATH) -> Error:
	if volumes.is_empty():
		reset_to_defaults()
	var config: ConfigFile = ConfigFile.new()
	for bus: StringName in VOLUME_BUSES:
		config.set_value("audio", String(bus), volumes[bus])
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("game", "text_speed", int(text_speed))
	return config.save(path)


static func apply() -> void:
	for bus: StringName in VOLUME_BUSES:
		_apply_volume(bus)
	_apply_window()


static func _apply_volume(bus: StringName) -> void:
	_set_bus(bus, volumes[bus])
	if bus == &"SFX":
		_set_bus(&"UI", volumes[bus])


static func _set_bus(bus: StringName, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(linear))


static func _apply_window() -> void:
	# Headless runs (tests) have no real window to change.
	if DisplayServer.get_name() == "headless":
		return
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
