class_name StatBar
extends Control
## A HP / MP / XP bar (PROJECT_PLAN.md Phase 5). Party bars use the dfgui ×2 party-HUD atlas: a
## gold-capped frame with a red, blue or purple fill inside its tube and a "112/130" label.
## Enemy bars use Gimble's bar frame with its tiled red fill, so the two sides read differently.
## The fill is a NinePatchRect sized to the value: the frame's tube is opaque, so the fill is drawn
## over it (not under it as `TextureProgressBar.texture_over` would need).

enum Style { PARTY_HP, PARTY_MP, PARTY_XP, ENEMY_HP }

const PARTY_ATLAS: Texture2D = preload("res://assets/vendor/dfgui/2x/dfgui_partyhud.png")
## Regions of the ×2 party-HUD atlas (measured on dfgui_partyhud.png).
const PARTY_FRAME_REGION: Rect2 = Rect2(116, 46, 290, 40)
const PARTY_FILL_REGIONS: Dictionary[Style, Rect2] = {
	Style.PARTY_HP: Rect2(116, 88, 250, 30),
	Style.PARTY_MP: Rect2(116, 180, 118, 24),
	Style.PARTY_XP: Rect2(116, 154, 118, 24),
}
## Width of the frame's gold end caps; the tube between them is 250 px.
const PARTY_CAP: int = 20
## Unstretched ends of the party fills (their rounded shading).
const PARTY_FILL_END: int = 6

const ENEMY_FRAME: Texture2D = preload("res://assets/vendor/gimbles/ui/2x/bars/bar_frame_9slice.png")
const ENEMY_FILL: Texture2D = preload("res://assets/vendor/gimbles/ui/2x/bars/fill_red_segmented.png")
const ENEMY_EMPTY: Texture2D = preload("res://assets/vendor/gimbles/ui/2x/bars/fill_red_empty.png")
## Gimble's bar at 2×: 8 px end slices; the fill sits 6 px in from each side, 12 px tall.
const ENEMY_SLICE: int = 8
const ENEMY_FILL_INSET: int = 6
const ENEMY_SIZE: Vector2 = Vector2(192, 24)

## Seconds for the fill to slide to a new value when animated.
const FILL_TWEEN_SECONDS: float = 0.35

@export var style: Style = Style.PARTY_HP:
	set(new_style):
		style = new_style
		if is_node_ready():
			_apply_style()
@export var show_label: bool = true:
	set(on):
		show_label = on
		if is_node_ready():
			_label.visible = on

var value: int = 1
var max_value: int = 1
## Fill fraction currently drawn (follows `value / max_value`, tweened when animated).
var shown_ratio: float = 1.0:
	set(r):
		shown_ratio = clampf(r, 0.0, 1.0)
		_layout_fill()

var _tween: Tween

@onready var _frame: NinePatchRect = %Frame
@onready var _empty: NinePatchRect = %Empty
@onready var _fill: NinePatchRect = %Fill
@onready var _label: Label = %Value


func _ready() -> void:
	_apply_style()
	_label.visible = show_label
	resized.connect(_layout_fill)
	set_values(value, max_value)


## Shows `new_value` / `new_max`. `animate` slides the fill; the label changes at once.
func set_values(new_value: int, new_max: int, animate: bool = false) -> void:
	max_value = maxi(1, new_max)
	value = clampi(new_value, 0, max_value)
	if _label != null:
		_label.text = "%d/%d" % [value, max_value]
	var target: float = float(value) / max_value
	if _tween != null:
		_tween.kill()
	if animate and is_inside_tree():
		_tween = create_tween()
		_tween.tween_property(self, ^"shown_ratio", target, FILL_TWEEN_SECONDS)
	else:
		shown_ratio = target


func ratio() -> float:
	return float(value) / max_value


## Rect of the fill at 100%, in local coordinates.
func inner_rect() -> Rect2:
	if style == Style.ENEMY_HP:
		return Rect2(ENEMY_FILL_INSET, ENEMY_FILL_INSET, size.x - 2 * ENEMY_FILL_INSET, size.y - 2 * ENEMY_FILL_INSET)
	var fill_height: float = PARTY_FILL_REGIONS[style].size.y
	return Rect2(PARTY_CAP, (size.y - fill_height) / 2.0, size.x - 2 * PARTY_CAP, fill_height)


func _apply_style() -> void:
	if style == Style.ENEMY_HP:
		custom_minimum_size = ENEMY_SIZE
		_setup_patch(_frame, ENEMY_FRAME, Rect2(), ENEMY_SLICE, true)
		_setup_patch(_empty, ENEMY_EMPTY, Rect2(), 0, true)
		_setup_patch(_fill, ENEMY_FILL, Rect2(), 0, true)
		_empty.visible = true
	else:
		custom_minimum_size = PARTY_FRAME_REGION.size
		_setup_patch(_frame, PARTY_ATLAS, PARTY_FRAME_REGION, PARTY_CAP, false)
		_setup_patch(_fill, PARTY_ATLAS, PARTY_FILL_REGIONS[style], PARTY_FILL_END, false)
		_empty.visible = false
	_layout_fill()


static func _setup_patch(patch: NinePatchRect, texture: Texture2D, region: Rect2, side: int, tile: bool) -> void:
	patch.texture = texture
	patch.region_rect = region
	patch.patch_margin_left = side
	patch.patch_margin_right = side
	patch.patch_margin_top = 0
	patch.patch_margin_bottom = 0
	var mode: NinePatchRect.AxisStretchMode = (NinePatchRect.AXIS_STRETCH_MODE_TILE if tile
			else NinePatchRect.AXIS_STRETCH_MODE_STRETCH)
	patch.axis_stretch_horizontal = mode
	patch.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH


func _layout_fill() -> void:
	if _fill == null:
		return
	var inner: Rect2 = inner_rect()
	_empty.position = inner.position
	_empty.size = inner.size
	var width: float = roundf(inner.size.x * shown_ratio)
	# Below twice its end slices a nine-patch fill would fold over itself.
	var min_width: float = 2.0 * _fill.patch_margin_left
	_fill.visible = shown_ratio > 0.0
	_fill.position = inner.position
	_fill.size = Vector2(maxf(width, min_width), inner.size.y)
