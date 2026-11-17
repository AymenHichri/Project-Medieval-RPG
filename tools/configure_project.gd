extends SceneTree
## Writes the project settings defined in PROJECT_PLAN.md §3 into project.godot.
##   godot --headless --path <project> -s res://tools/configure_project.gd
## Idempotent: re-running it resets these settings to the documented values.

const AUTOLOADS: Array[Array] = [
	["GameState", "res://scripts/autoload/game_state.gd"],
	["AudioManager", "res://scripts/autoload/audio_manager.gd"],
	["SaveManager", "res://scripts/autoload/save_manager.gd"],
	["DialogueManager", "res://scripts/autoload/dialogue_manager.gd"],
	["SceneManager", "res://scripts/autoload/scene_manager.gd"],
]

const PHYSICS_LAYERS: Array[String] = ["world_solid", "water", "player", "interactables", "triggers"]


func _initialize() -> void:
	var s: Dictionary[String, Variant] = {
		"application/config/name": "Dark Fantasy JRPG",
		"application/config/features": PackedStringArray(["4.7", "Forward Plus"]),
		"application/run/main_scene": "res://scenes/ui/title_screen.tscn",
		"rendering/renderer/rendering_method": "forward_plus",
		"display/window/size/viewport_width": 1920,
		"display/window/size/viewport_height": 1080,
		"display/window/stretch/mode": "canvas_items",
		"display/window/stretch/aspect": "expand",
		# Linear with mipmaps: painted world art downscaled by the camera (ART_GUIDELINES.md §2).
		"rendering/textures/canvas_textures/default_texture_filter": 3,
		"gui/theme/custom": "res://scenes/ui/theme/main_theme.tres",
		"audio/buses/default_bus_layout": "res://default_bus_layout.tres",
		# Generate mipmaps for every imported texture by default; pixel UI folders are switched off
		# afterwards by tools/apply_import_settings.py.
		"importer_defaults/texture": {"mipmaps/generate": true},
		"debug/gdscript/warnings/untyped_declaration": 2,
		"debug/gdscript/warnings/unsafe_property_access": 1,
		"debug/gdscript/warnings/unsafe_method_access": 1,
		"debug/gdscript/warnings/unsafe_cast": 1,
		"debug/gdscript/warnings/unsafe_call_argument": 1,
		"debug/gdscript/warnings/exclude_addons": true,
	}
	for key: String in s:
		ProjectSettings.set_setting(key, s[key])
	for i: int in PHYSICS_LAYERS.size():
		ProjectSettings.set_setting("layer_names/2d_physics/layer_%d" % (i + 1), PHYSICS_LAYERS[i])
	for entry: Array in AUTOLOADS:
		ProjectSettings.set_setting("autoload/%s" % entry[0], "*" + entry[1])
	_inputs()
	var err: Error = ProjectSettings.save()
	print("configure_project: ", "saved" if err == OK else error_string(err))
	quit(0 if err == OK else 1)


func _inputs() -> void:
	_action("move_up", [_key(KEY_W), _key(KEY_UP), _pad_button(JOY_BUTTON_DPAD_UP), _pad_axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("move_down", [_key(KEY_S), _key(KEY_DOWN), _pad_button(JOY_BUTTON_DPAD_DOWN), _pad_axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action("move_left", [_key(KEY_A), _key(KEY_LEFT), _pad_button(JOY_BUTTON_DPAD_LEFT), _pad_axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("move_right", [_key(KEY_D), _key(KEY_RIGHT), _pad_button(JOY_BUTTON_DPAD_RIGHT), _pad_axis(JOY_AXIS_LEFT_X, 1.0)])
	_action("accept", [_key(KEY_ENTER), _key(KEY_KP_ENTER), _key(KEY_SPACE), _key(KEY_E), _pad_button(JOY_BUTTON_A)])
	_action("cancel", [_key(KEY_ESCAPE), _key(KEY_BACKSPACE), _pad_button(JOY_BUTTON_B)])
	_action("menu", [_key(KEY_TAB), _key(KEY_M), _pad_button(JOY_BUTTON_START)])


func _action(action_name: String, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		event.device = -1  # all devices, as the editor does
	ProjectSettings.set_setting("input/" + action_name, {"deadzone": 0.5, "events": events})


func _key(code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	return event


func _pad_button(button: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	return event


func _pad_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event
