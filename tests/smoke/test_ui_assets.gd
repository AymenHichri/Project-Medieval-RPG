extends TestCase
## UI kit files are at the expected integer scales and the theme uses the vendor 9-slice margins.

const GIMBLES: String = "res://assets/vendor/gimbles/ui"
const DFGUI: String = "res://assets/vendor/dfgui"


func _image_size(path: String) -> Vector2i:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	return Vector2i.ZERO if image == null else image.get_size()


func test_gimbles_2x_pieces_match_index() -> void:
	var text: String = FileAccess.get_file_as_string(GIMBLES + "/ui_index.json")
	var index: Dictionary = JSON.parse_string(text) as Dictionary
	assert_not_null(index, "ui_index.json did not parse")
	if index == null:
		return
	var pieces: Dictionary = index["pieces"] as Dictionary
	assert_true(pieces.size() >= 13, "expected at least 13 pieces")
	for file: String in pieces:
		var size_1x: Array = (pieces[file] as Dictionary)["size"] as Array
		var expected: Vector2i = Vector2i(int(size_1x[0]) * 2, int(size_1x[1]) * 2)
		assert_eq(_image_size(GIMBLES + "/2x/" + file), expected, file)


func test_theme_panel_margins_are_2x_vendor_values() -> void:
	var theme: Theme = load("res://scenes/ui/theme/main_theme.tres") as Theme
	assert_not_null(theme)
	if theme == null:
		return
	var panel: StyleBoxTexture = theme.get_stylebox("panel", "PanelContainer") as StyleBoxTexture
	assert_not_null(panel, "PanelContainer panel must be a StyleBoxTexture")
	if panel != null:
		assert_eq(panel.texture_margin_left, 32.0)
		assert_eq(panel.texture_margin_top, 32.0)
		assert_eq(panel.axis_stretch_horizontal, StyleBoxTexture.AXIS_STRETCH_MODE_TILE)
	var button: StyleBoxTexture = theme.get_stylebox("normal", "Button") as StyleBoxTexture
	assert_not_null(button, "Button normal must be a StyleBoxTexture")
	if button != null:
		assert_eq(button.texture_margin_left, 16.0)
		assert_eq(button.texture_margin_top, 0.0)


func test_dfgui_2x_copies_are_exactly_double() -> void:
	var dir: DirAccess = DirAccess.open(DFGUI + "/1x")
	assert_not_null(dir, "dfgui/1x missing")
	if dir == null:
		return
	var count: int = 0
	for file: String in dir.get_files():
		if not file.ends_with(".png"):
			continue
		count += 1
		var src: Vector2i = _image_size(DFGUI + "/1x/" + file)
		assert_eq(_image_size(DFGUI + "/2x/" + file), src * 2, file)
	assert_eq(count, 38, "expected the 38 dfgui PNGs")
