extends TestCase
## Settings (Phase 7): values round-trip through the cfg file and reach the audio buses through
## linear_to_db; the settings menu applies slider moves at once and saves on close.

const PATH: String = "user://test_settings.cfg"
const MENU: String = "res://scenes/ui/menus/settings_menu.tscn"

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _volumes: Dictionary[StringName, float] = {}
var _fullscreen: bool = false
var _speed: Settings.TextSpeed


func before_each() -> void:
	_volumes = Settings.volumes.duplicate()
	_fullscreen = Settings.fullscreen
	_speed = Settings.text_speed
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Settings.volumes = _volumes
	Settings.fullscreen = _fullscreen
	Settings.text_speed = _speed
	Settings.apply()


func _bus_db(bus: StringName) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))


func test_values_round_trip_through_the_file() -> void:
	Settings.reset_to_defaults()
	Settings.set_volume(&"Master", 0.9)
	Settings.set_volume(&"Music", 0.25)
	Settings.set_volume(&"SFX", 0.5)
	Settings.set_volume(&"Ambience", 0.0)
	Settings.fullscreen = true
	Settings.set_text_speed(Settings.TextSpeed.FAST)
	assert_eq(Settings.save(PATH), OK)
	Settings.reset_to_defaults()
	assert_almost_eq(Settings.volume(&"Music"), Settings.DEFAULT_VOLUME, 0.001, "reset")
	Settings.load_and_apply(PATH)
	assert_almost_eq(Settings.volume(&"Master"), 0.9, 0.001)
	assert_almost_eq(Settings.volume(&"Music"), 0.25, 0.001)
	assert_almost_eq(Settings.volume(&"SFX"), 0.5, 0.001)
	assert_almost_eq(Settings.volume(&"Ambience"), 0.0, 0.001)
	assert_true(Settings.fullscreen)
	assert_eq(Settings.text_speed, Settings.TextSpeed.FAST)


func test_volumes_are_applied_to_the_buses_with_linear_to_db() -> void:
	Settings.reset_to_defaults()
	Settings.set_volume(&"Music", 0.25)
	Settings.set_volume(&"SFX", 0.5)
	Settings.set_volume(&"Ambience", 0.7)
	assert_almost_eq(_bus_db(&"Music"), linear_to_db(0.25), 0.01)
	assert_almost_eq(_bus_db(&"SFX"), linear_to_db(0.5), 0.01)
	assert_almost_eq(_bus_db(&"UI"), linear_to_db(0.5), 0.01, "the SFX slider also drives UI sounds")
	assert_almost_eq(_bus_db(&"Ambience"), linear_to_db(0.7), 0.01)
	Settings.set_volume(&"Music", 3.0)
	assert_almost_eq(Settings.volume(&"Music"), 1.0, 0.001, "clamped to 0..1")


func test_missing_or_broken_file_gives_defaults() -> void:
	Settings.load_and_apply("user://no_such_settings.cfg")
	assert_almost_eq(Settings.volume(&"Music"), Settings.DEFAULT_VOLUME, 0.001)
	assert_eq(Settings.text_speed, Settings.TextSpeed.NORMAL)
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("[game]\ntext_speed=99\n[audio]\nMusic=-4.0\n")
	file.close()
	Settings.load_and_apply(PATH)
	assert_eq(Settings.text_speed, Settings.TextSpeed.INSTANT, "out-of-range speed clamped")
	assert_almost_eq(Settings.volume(&"Music"), 0.0, 0.001, "negative volume clamped")


func test_text_speeds_are_ordered() -> void:
	var previous: float = 0.0
	for speed: int in [Settings.TextSpeed.SLOW, Settings.TextSpeed.NORMAL, Settings.TextSpeed.FAST]:
		Settings.text_speed = speed as Settings.TextSpeed
		assert_true(Settings.chars_per_second() > previous)
		previous = Settings.chars_per_second()
	Settings.text_speed = Settings.TextSpeed.INSTANT
	assert_eq(Settings.chars_per_second(), 0.0, "instant")


func test_menu_slider_applies_at_once_and_close_saves() -> void:
	Settings.reset_to_defaults()
	var menu: SettingsMenu = (load(MENU) as PackedScene).instantiate() as SettingsMenu
	menu.save_path = PATH
	_tree.root.add_child(menu)
	menu.open()
	assert_true(menu.visible)
	assert_almost_eq(menu.slider(&"Music").value, Settings.DEFAULT_VOLUME, 0.001, "shows the current value")
	menu.slider(&"Music").value = 0.35
	assert_almost_eq(_bus_db(&"Music"), linear_to_db(0.35), 0.01, "applied immediately")
	var closed: Array[bool] = [false]
	menu.closed.connect(func() -> void: closed[0] = true)
	menu.close()
	assert_true(closed[0])
	assert_false(menu.visible)
	assert_true(FileAccess.file_exists(PATH), "saved on close")
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)
	assert_almost_eq(float(config.get_value("audio", "Music")), 0.35, 0.001)
	_tree.root.remove_child(menu)
	menu.free()
