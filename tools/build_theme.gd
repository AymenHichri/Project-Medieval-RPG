extends SceneTree
## Builds the project-wide UI theme, the typography FontVariations and the UI palette resource.
##   godot --headless --path <project> -s res://tools/build_theme.gd
## Source of truth for UI styling: edit THIS script (not the generated .tres files), then re-run it.
## Fonts: if the Alegreya / Cinzel TTFs are not yet in assets/fonts/, the FontVariations are saved
## without a base font and Godot's default font is used until the files are added and this is re-run.

const THEME_PATH: String = "res://scenes/ui/theme/main_theme.tres"
const PALETTE_PATH: String = "res://scenes/ui/theme/ui_palette.tres"
const FONT_DIR: String = "res://scenes/ui/theme/fonts"
const GIMBLES_UI: String = "res://assets/vendor/gimbles/ui/2x"
## Gimble's 9-slice margins are for 1x files; we use the 2x files.
const UI_SCALE: int = 2

const BODY_SIZE: int = 30
const BUTTON_SIZE: int = 26

var palette: UIPalette
var _ts: TextServer = TextServerManager.get_primary_interface()
var missing_fonts: Array[String] = []


func _initialize() -> void:
	palette = UIPalette.new()
	_save(palette, PALETTE_PATH)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FONT_DIR))

	var alegreya_dir: String = "res://assets/fonts/alegreya"
	var cinzel_dir: String = "res://assets/fonts/cinzel"
	var fonts: Dictionary[String, FontVariation] = {
		"font_title": _variation(cinzel_dir, ["Bold", "Variable", "Regular"], 700, false),
		"font_heading": _variation(cinzel_dir, ["SemiBold", "Variable", "Regular"], 600, false),
		"font_name": _variation(cinzel_dir, ["Regular", "Variable"], 400, false),
		"font_damage": _variation(cinzel_dir, ["Black", "Variable", "Bold"], 900, false),
		"font_body": _variation(alegreya_dir, ["Regular", "Variable"], 400, false),
		"font_body_italic": _variation(alegreya_dir, ["Italic"], 400, false),
		"font_numeric": _variation(alegreya_dir, ["Medium", "Variable", "Regular"], 500, true),
	}
	for key: String in fonts:
		_save(fonts[key], "%s/%s.tres" % [FONT_DIR, key])
		# Reload so the theme references the saved files instead of embedding copies.
		fonts[key] = load("%s/%s.tres" % [FONT_DIR, key]) as FontVariation

	var theme: Theme = Theme.new()
	theme.default_font = fonts["font_body"]
	theme.default_font_size = BODY_SIZE
	_labels(theme, fonts)
	_panels(theme)
	_buttons(theme, fonts)
	_save(theme, THEME_PATH)

	if missing_fonts.is_empty():
		print("build_theme: all fonts found")
	else:
		print("build_theme: MISSING FONTS (Godot default font used for now): ", ", ".join(missing_fonts))
	print("build_theme: wrote %s" % THEME_PATH)
	quit(0)


func _labels(theme: Theme, fonts: Dictionary[String, FontVariation]) -> void:
	theme.set_color("font_color", "Label", palette.parchment)
	# name, font key, size, colour, outline size
	var specs: Array[Array] = [
		["TitleLabel", "font_title", 112, palette.gold, 0],
		["HeaderLabel", "font_heading", 48, palette.gold, 0],
		["NameLabel", "font_name", 32, palette.gold_muted, 0],
		["BodyLabel", "font_body", BODY_SIZE, palette.parchment, 0],
		["LoreLabel", "font_body_italic", 28, palette.parchment_dim, 0],
		["SmallLabel", "font_body", 24, palette.parchment_dim, 0],
		["NumericLabel", "font_numeric", 28, palette.parchment, 0],
		["DamageNumber", "font_damage", 48, Color.WHITE, 6],
	]
	for spec: Array in specs:
		var type_name: String = spec[0]
		theme.set_type_variation(type_name, "Label")
		theme.set_font("font", type_name, fonts[spec[1]])
		theme.set_font_size("font_size", type_name, spec[2])
		theme.set_color("font_color", type_name, spec[3])
		if spec[4] > 0:
			theme.set_constant("outline_size", type_name, spec[4])
			theme.set_color("font_outline_color", type_name, palette.bg_abyss)
	theme.set_font("normal_font", "RichTextLabel", fonts["font_body"])
	theme.set_font("italics_font", "RichTextLabel", fonts["font_body_italic"])
	theme.set_font("mono_font", "RichTextLabel", fonts["font_numeric"])
	theme.set_color("default_color", "RichTextLabel", palette.parchment)


func _panels(theme: Theme) -> void:
	var panel: StyleBoxTexture = _nine_slice("panels/panel_iron_9slice.png", 16, 16, 16, 16)
	panel.set_content_margin_all(16 * UI_SCALE + 8)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	var tooltip: StyleBoxTexture = _nine_slice("panels/panel_iron_tooltip_9slice.png", 8, 8, 8, 8)
	tooltip.set_content_margin_all(8 * UI_SCALE + 6)
	theme.set_stylebox("panel", "TooltipPanel", tooltip)
	theme.set_type_variation("TooltipPanelContainer", "PanelContainer")
	theme.set_stylebox("panel", "TooltipPanelContainer", tooltip)
	theme.set_color("font_color", "TooltipLabel", palette.parchment)
	theme.set_font_size("font_size", "TooltipLabel", 24)


func _buttons(theme: Theme, fonts: Dictionary[String, FontVariation]) -> void:
	var states: Dictionary[String, String] = {
		"normal": "normal", "hover": "hover", "pressed": "pressed",
		"disabled": "disabled", "hover_pressed": "pressed",
	}
	for state: String in states:
		var box: StyleBoxTexture = _nine_slice("buttons/button_red_%s_9slice.png" % states[state], 8, 8, 0, 0)
		box.content_margin_left = 28
		box.content_margin_right = 28
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		theme.set_stylebox(state, "Button", box)
	var focus: StyleBoxFlat = StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(2)
	focus.border_color = palette.gold
	focus.set_expand_margin_all(3)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_font("font", "Button", fonts["font_name"])
	theme.set_font_size("font_size", "Button", BUTTON_SIZE)
	theme.set_color("font_color", "Button", palette.parchment)
	theme.set_color("font_hover_color", "Button", palette.parchment_light)
	theme.set_color("font_focus_color", "Button", palette.parchment_light)
	theme.set_color("font_pressed_color", "Button", palette.gold)
	theme.set_color("font_hover_pressed_color", "Button", palette.gold)
	theme.set_color("font_disabled_color", "Button", palette.parchment_dim)


## 9-slice StyleBox from a Gimble's 2x texture; margins given in 1x pixels (ui_index.json).
func _nine_slice(file: String, left: int, right: int, top: int, bottom: int) -> StyleBoxTexture:
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = load("%s/%s" % [GIMBLES_UI, file]) as Texture2D
	box.texture_margin_left = left * UI_SCALE
	box.texture_margin_right = right * UI_SCALE
	box.texture_margin_top = top * UI_SCALE
	box.texture_margin_bottom = bottom * UI_SCALE
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE if top > 0 else StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return box


## FontVariation over the first font file in `dir` whose name contains one of `keywords` (in order).
func _variation(dir: String, keywords: Array[String], weight: int, numeric: bool) -> FontVariation:
	var variation: FontVariation = FontVariation.new()
	var file: String = _find_font_file(dir, keywords)
	if file.is_empty():
		missing_fonts.append("%s (%s)" % [dir.get_file(), keywords[0]])
	else:
		var base: FontFile = load(file) as FontFile
		variation.base_font = base
		if "Variable" in file.get_file() or "[wght]" in file.get_file():
			variation.variation_opentype = {_ts.name_to_tag("wght"): weight}
	if numeric:
		variation.opentype_features = {_ts.name_to_tag("lnum"): 1, _ts.name_to_tag("tnum"): 1}
	return variation


func _find_font_file(dir: String, keywords: Array[String]) -> String:
	# Accepts files directly in `dir` or in one subfolder (Google Fonts downloads put statics in static/).
	var files: Array[String] = []
	var access: DirAccess = DirAccess.open(dir)
	if access == null:
		return ""
	for file_name: String in access.get_files():
		files.append(dir.path_join(file_name))
	for sub: String in access.get_directories():
		var sub_access: DirAccess = DirAccess.open(dir.path_join(sub))
		if sub_access != null:
			for file_name: String in sub_access.get_files():
				files.append(dir.path_join(sub).path_join(file_name))
	for keyword: String in keywords:
		for path: String in files:
			var lower: String = path.get_file().to_lower()
			if not (lower.ends_with(".ttf") or lower.ends_with(".otf")):
				continue
			if keyword != "Italic" and "italic" in lower:
				continue
			var is_match: bool
			if keyword == "Variable":
				is_match = "variable" in lower or "[wght]" in lower
			else:
				# Exact style token, so "Bold" does not match "SemiBold".
				is_match = ("-%s." % keyword.to_lower()) in lower
			if is_match:
				return path
	return ""


func _save(resource: Resource, path: String) -> void:
	var err: Error = ResourceSaver.save(resource, path)
	if err != OK:
		push_error("build_theme: could not save %s (%s)" % [path, error_string(err)])
