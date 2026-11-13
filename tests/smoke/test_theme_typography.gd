extends TestCase
## Theme typography matches FONT_CATALOG.md and the palette tokens are complete.

const VARIATIONS: Array[StringName] = [
	&"TitleLabel", &"HeaderLabel", &"NameLabel", &"BodyLabel",
	&"LoreLabel", &"SmallLabel", &"NumericLabel", &"DamageNumber",
]

var theme: Theme


func before_each() -> void:
	theme = load("res://scenes/ui/theme/main_theme.tres") as Theme


func test_theme_is_project_default() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom"), "res://scenes/ui/theme/main_theme.tres")
	assert_not_null(theme)


func test_type_variations_exist() -> void:
	for variation: StringName in VARIATIONS:
		assert_true(theme.is_type_variation(variation, &"Label"), "%s is not a Label variation" % variation)
		assert_true(theme.has_font(&"font", variation), "%s has no font" % variation)
		assert_true(theme.has_font_size(&"font_size", variation), "%s has no size" % variation)


func test_minimum_sizes() -> void:
	assert_true(theme.default_font_size >= 28, "body size must be >= 28")
	assert_true(theme.get_font_size(&"font_size", &"BodyLabel") >= 28, "BodyLabel must be >= 28")
	assert_true(theme.get_font_size(&"font_size", &"SmallLabel") >= 22, "SmallLabel must be >= 22")


func test_numeric_font_uses_lining_tabular_figures() -> void:
	var font: FontVariation = theme.get_font(&"font", &"NumericLabel") as FontVariation
	assert_not_null(font, "NumericLabel font must be a FontVariation")
	if font == null:
		return
	var ts: TextServer = TextServerManager.get_primary_interface()
	assert_eq(int(font.opentype_features.get(ts.name_to_tag("lnum"), 0)), 1, "lnum")
	assert_eq(int(font.opentype_features.get(ts.name_to_tag("tnum"), 0)), 1, "tnum")


func test_palette_tokens_are_opaque() -> void:
	var palette: UIPalette = load("res://scenes/ui/theme/ui_palette.tres") as UIPalette
	assert_not_null(palette)
	if palette == null:
		return
	assert_eq(UIPalette.TOKENS.size(), 20)
	for token: StringName in UIPalette.TOKENS:
		assert_eq(palette.token(token).a, 1.0, "token %s" % token)
