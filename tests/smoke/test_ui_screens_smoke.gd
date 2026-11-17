extends TestCase
## The Phase 7 screens instantiate headless with the main theme and offer a focusable control;
## the pause menu pauses and resumes; Game Over returns to the title.

const SCREENS: Dictionary[String, String] = {
	"title": "res://scenes/ui/title_screen.tscn",
	"pause": "res://scenes/ui/pause_menu.tscn",
	"settings": "res://scenes/ui/menus/settings_menu.tscn",
	"dialogue": "res://scenes/ui/dialogue_box.tscn",
	"game_over": "res://scenes/ui/game_over.tscn",
	"intro": "res://scenes/ui/intro_card.tscn",
	"hud": "res://scenes/ui/exploration_hud.tscn",
}
const VILLAGE: String = "res://scenes/world/maps/village_01.tscn"

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _nodes: Array[Node] = []


func before_each() -> void:
	SceneManager.instant_transitions = true


func after_each() -> void:
	_tree.paused = false
	for node: Node in _nodes:
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	_nodes.clear()
	var scene: Node = _tree.current_scene
	if scene != null and is_instance_valid(scene):
		_tree.root.remove_child(scene)
		scene.free()
	_tree.current_scene = null
	SceneManager.instant_transitions = false
	AudioManager.music.stop(0.0)


func _add(path: String) -> Node:
	var node: Node = (load(path) as PackedScene).instantiate()
	if node is TitleScreen:
		(node as TitleScreen).show_backdrop = false
	_tree.root.add_child(node)
	_nodes.append(node)
	return node


func _focusables(root: Node) -> Array[Control]:
	var out: Array[Control] = []
	for node: Node in root.find_children("*", "Control", true, false):
		var control: Control = node as Control
		if control.focus_mode != Control.FOCUS_NONE and not (control is Label):
			out.append(control)
	return out


func test_every_screen_instantiates_with_the_theme_and_a_focusable_control() -> void:
	var theme_path: String = str(ProjectSettings.get_setting("gui/theme/custom"))
	assert_eq(theme_path, "res://scenes/ui/theme/main_theme.tres")
	var theme: Theme = load(theme_path) as Theme
	assert_true(theme.has_stylebox("slider", "HSlider"), "slider style in the theme")
	assert_true(theme.has_icon("checked", "CheckBox"), "check box style in the theme")
	assert_true(theme.has_stylebox("tab_selected", "TabBar"), "tab style in the theme")
	for key: String in SCREENS:
		var node: Node = _add(SCREENS[key])
		assert_not_null(node, "%s instantiates" % key)
		if key == "hud":
			assert_not_null((node as ExplorationHud).menu_button, "MENU button")
			continue
		if key == "dialogue":
			var box: DialogueBox = node as DialogueBox
			box.show_line("Elder Maren", "Hello.", null, PackedStringArray(["Yes", "No"]))
			box.finish_typing()
			assert_eq(box.get_choice_buttons().size(), 2)
		assert_true(_focusables(node).size() >= 1, "%s has a focusable control" % key)


func test_title_buttons_and_live_backdrop() -> void:
	var title: TitleScreen = (load(SCREENS["title"]) as PackedScene).instantiate() as TitleScreen
	_tree.root.add_child(title)
	_nodes.append(title)
	await _tree.process_frame
	assert_not_null(title.backdrop, "the graveyard backdrop is built")
	assert_true(title.backdrop.backdrop)
	assert_null(title.backdrop.player, "no player in the backdrop")
	assert_null(title.backdrop.pause_menu, "no pause menu in the backdrop")
	var texts: Array[String] = []
	for control: Control in _focusables(title):
		if control is Button and control.is_visible_in_tree():
			texts.append((control as Button).text)
	for expected: String in ["New Game", "Settings", "Quit"]:
		assert_true(expected in texts, "%s button (have %s)" % [expected, texts])
	title.settings_menu.open()
	assert_true(title.settings_menu.visible, "settings reachable from the title")
	title.settings_menu.save_path = "user://test_settings_title.cfg"
	title.settings_menu.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_settings_title.cfg"))


func test_pause_menu_pauses_and_resumes_in_the_village() -> void:
	var map: Map = _add(VILLAGE) as Map
	await _tree.process_frame
	assert_not_null(map.pause_menu)
	assert_not_null(map.hud)
	assert_true(map.open_pause_menu(), "opens while the player can act")
	assert_true(_tree.paused, "the game is paused")
	assert_true(map.pause_menu.is_open())
	assert_true("Knight" in map.pause_menu.summary_text(), "party summary")
	assert_false(map.open_pause_menu(), "not twice")
	map.pause_menu.close()
	assert_false(_tree.paused, "resumed")
	map.hud.menu_pressed.emit()
	assert_true(map.pause_menu.is_open(), "the MENU button opens it too")
	map.pause_menu.settings_menu.save_path = "user://test_settings_pause.cfg"
	map.pause_menu.settings_menu.open()
	map.pause_menu.settings_menu.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_settings_pause.cfg"))
	map.pause_menu.close()
	DialogueManager.start(&"examine_notice_board")
	assert_false(map.open_pause_menu(), "not during a dialogue")
	DialogueTestUtil.close_dialogue()


func test_game_over_returns_to_the_title() -> void:
	var over: GameOverScreen = (load(SCREENS["game_over"]) as PackedScene).instantiate() as GameOverScreen
	_tree.root.add_child(over)
	_tree.current_scene = over
	await _tree.process_frame
	var button: Button = over.get_node(^"%TitleButton") as Button
	button.pressed.emit()
	for i: int in 5:
		await _tree.process_frame
	assert_not_null(_tree.current_scene)
	if _tree.current_scene != null:
		assert_eq(_tree.current_scene.scene_file_path, SceneManager.TITLE_SCENE)
