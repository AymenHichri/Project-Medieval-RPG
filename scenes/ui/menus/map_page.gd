class_name MapPage
extends HBoxContainer
## The pause menu's Map tab (PROJECT_PLAN.md Phase 10): one button per visited map; for the chosen
## map its sepia-graded picture (MapAtlas, captured on the first visit) with dfgui map icons for
## the player (current map only), exits, rest points (save points from Phase 11), the current quest
## targets and the boss door, plus a legend. Without a picture (headless runs) the markers are drawn
## on a plain panel. Reads GameState; never changes it.

const ICONS: Texture2D = preload("res://assets/vendor/dfgui/2x/dfgui_mapicons.png")
const SEPIA: Shader = preload("res://scenes/ui/menus/sepia.gdshader")
const PALETTE: UIPalette = preload("res://scenes/ui/theme/ui_palette.tres")
## One icon of the dfgui atlas (2×): 3 columns × 4 rows.
const ICON_CELL: Vector2 = Vector2(98, 86)
## Atlas index per marker kind: party, flag, "?", shrine, crypt.
const ICON_INDEX: Dictionary[MapAtlas.Kind, int] = {
	MapAtlas.Kind.PLAYER: 6, MapAtlas.Kind.EXIT: 9, MapAtlas.Kind.QUEST: 7,
	MapAtlas.Kind.REST: 2, MapAtlas.Kind.BOSS: 1,
}
const LEGEND: Dictionary[MapAtlas.Kind, String] = {
	MapAtlas.Kind.PLAYER: "You", MapAtlas.Kind.EXIT: "Exit", MapAtlas.Kind.QUEST: "Quest",
	MapAtlas.Kind.REST: "Rest", MapAtlas.Kind.BOSS: "Danger",
}
## Size of a marker on the page (the 1× icon size).
const MARKER_SIZE: Vector2 = Vector2(49, 43)
## The largest the picture is shown.
const VIEW_SIZE: Vector2 = Vector2(900, 560)
const NO_PICTURE_TEXT: String = "The map has not been drawn yet."
## Auto-exposure: a picture's mean brightness is lifted to this before the sepia grade (night maps
## are much darker than dusk ones), within the gain limits.
const TARGET_LUMA: float = 0.32
const MAX_GAIN: float = 5.0

## Scene path of the map shown ("" when none has been visited).
var shown_path: String = ""
## The markers drawn for the shown map (tests).
var shown_markers: Array[Dictionary] = []

var _buttons: Dictionary[String, Button] = {}

@onready var _maps: VBoxContainer = %Maps
@onready var _name: Label = %MapName
@onready var _canvas: Control = %Canvas
@onready var _paper: ColorRect = %Paper
@onready var _picture: TextureRect = %Picture
@onready var _markers: Control = %Markers
@onready var _no_picture: Label = %NoPicture
@onready var _legend: HFlowContainer = %Legend


func _ready() -> void:
	_paper.color = PALETTE.panel_slate
	var sepia: ShaderMaterial = ShaderMaterial.new()
	sepia.shader = SEPIA
	sepia.set_shader_parameter(&"dark_tone", PALETTE.bg_abyss)
	sepia.set_shader_parameter(&"light_tone", PALETTE.parchment)
	_picture.material = sepia
	_build_legend()


## Rebuilds the map list from GameState.visited_maps and shows the current map (else the first).
func refresh() -> void:
	for button: Button in _buttons.values():
		_maps.remove_child(button)
		button.queue_free()
	_buttons.clear()
	for path: String in GameState.visited_maps:
		var info: Dictionary = MapAtlas.load_info(path)
		var button: Button = Button.new()
		button.text = str(info.get("name", MapAtlas.map_id_of(path).capitalize()))
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_entered.connect(show_map.bind(path))
		button.pressed.connect(show_map.bind(path))
		_maps.add_child(button)
		_buttons[path] = button
	if GameState.visited_maps.is_empty():
		shown_path = ""
		_name.text = ""
		_clear_markers()
		return
	var wanted: String = GameState.current_map if GameState.current_map in GameState.visited_maps else shown_path
	show_map(wanted if wanted in GameState.visited_maps else GameState.visited_maps[0])


## Shows one visited map with its markers.
func show_map(map_path: String) -> void:
	shown_path = map_path
	for path: String in _buttons:
		_buttons[path].set_pressed_no_signal(path == map_path)
	var info: Dictionary = MapAtlas.load_info(map_path)
	_name.text = str(info.get("name", ""))
	var bounds: Rect2 = _bounds(info)
	var view: Vector2 = fit(bounds.size, VIEW_SIZE)
	_canvas.custom_minimum_size = view
	_picture.texture = MapAtlas.load_picture(map_path)
	_no_picture.visible = _picture.texture == null
	if _picture.texture != null:
		(_picture.material as ShaderMaterial).set_shader_parameter(&"gain", exposure_gain(_picture.texture.get_image()))
	shown_markers = MapAtlas.visible_markers(info, GameState.quests, GameState.flags)
	var map: Map = _live_map(map_path)
	if map != null and map.player != null:
		var at: Vector2 = MapAtlas.fraction(bounds, map.player.global_position)
		shown_markers.append({"kind": MapAtlas.Kind.PLAYER, "x": at.x, "y": at.y})
	_draw_markers(view)


## The largest size with the aspect of `content` that fits in `box`.
static func fit(content: Vector2, box: Vector2) -> Vector2:
	if content.x <= 0.0 or content.y <= 0.0:
		return box
	var factor: float = minf(box.x / content.x, box.y / content.y)
	return (content * factor).floor()


## The gain that brings `image`'s mean brightness to TARGET_LUMA (1.0 … MAX_GAIN).
static func exposure_gain(image: Image) -> float:
	if image == null or image.is_empty():
		return 1.0
	var small: Image = image.duplicate() as Image
	small.resize(16, 12, Image.INTERPOLATE_BILINEAR)
	var total: float = 0.0
	for y: int in small.get_height():
		for x: int in small.get_width():
			var c: Color = small.get_pixel(x, y)
			total += c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	var mean: float = total / (small.get_width() * small.get_height())
	return clampf(TARGET_LUMA / maxf(mean, 0.01), 1.0, MAX_GAIN)


## The atlas region of a marker kind.
static func icon_for(kind: int) -> AtlasTexture:
	var index: int = ICON_INDEX[kind as MapAtlas.Kind]
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = ICONS
	atlas.region = Rect2(Vector2(index % 3, index / 3) * ICON_CELL, ICON_CELL)
	return atlas


## The visited-map buttons in list order (tests).
func map_buttons() -> Array[Button]:
	var out: Array[Button] = []
	out.assign(_buttons.values())
	return out


## The kinds of the markers drawn (tests).
func shown_kinds() -> Array[int]:
	var kinds: Array[int] = []
	for marker: Dictionary in shown_markers:
		kinds.append(int(marker["kind"]))
	return kinds


func _draw_markers(view: Vector2) -> void:
	_clear_markers()
	for marker: Dictionary in shown_markers:
		var icon: TextureRect = TextureRect.new()
		icon.texture = icon_for(int(marker["kind"]))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = MARKER_SIZE
		var at: Vector2 = Vector2(float(marker["x"]), float(marker["y"])).clamp(Vector2.ZERO, Vector2.ONE)
		icon.position = (at * view - MARKER_SIZE / 2.0).round()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_markers.add_child(icon)


func _clear_markers() -> void:
	for child: Node in _markers.get_children():
		_markers.remove_child(child)
		child.queue_free()


func _build_legend() -> void:
	for kind: MapAtlas.Kind in LEGEND:
		var icon: TextureRect = TextureRect.new()
		icon.texture = icon_for(kind)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = MARKER_SIZE * 0.75
		_legend.add_child(icon)
		var label: Label = Label.new()
		label.text = LEGEND[kind]
		label.theme_type_variation = &"SmallLabel"
		_legend.add_child(label)


static func _bounds(info: Dictionary) -> Rect2:
	var values: Array = info.get("bounds", [0, 0, 1, 1]) as Array
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))


## The map scene running now if it is `map_path` (the current scene, or the one waiting for a battle).
func _live_map(map_path: String) -> Map:
	for node: Node in [get_tree().current_scene, SceneManager.detached_world()]:
		var map: Map = node as Map
		if map != null and map.scene_file_path == map_path:
			return map
	# The pause menu lives inside the map.
	var owner_map: Node = get_parent()
	while owner_map != null and not owner_map is Map:
		owner_map = owner_map.get_parent()
	var parent_map: Map = owner_map as Map
	return parent_map if parent_map != null and parent_map.scene_file_path == map_path else null
