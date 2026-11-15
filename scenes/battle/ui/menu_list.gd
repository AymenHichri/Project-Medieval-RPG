class_name MenuList
extends VBoxContainer
## A vertical battle menu: rows of [cursor][icon] text … detail. Keyboard and gamepad through the
## project actions (`move_up/down`, `accept`, `cancel`, plus the built-in `ui_*` ones); the mouse
## can hover and click. The selected row shows Gimble's gauntlet cursor; disabled rows are greyed
## and cannot be chosen.
##
##   menu.set_entries([MenuList.entry("Attack", &"attack", sword_icon), …])
##   var value: Variant = await menu.pick()   # null = cancelled

signal picked(value: Variant)
signal highlighted(value: Variant)

const CURSOR: Texture2D = preload("res://assets/vendor/gimbles/ui/2x/cursors/cursor_gauntlet_16.png")
const PALETTE: UIPalette = preload("res://scenes/ui/theme/ui_palette.tres")
## The gauntlet points up in the art: turned a quarter clockwise it points at the row.
const CURSOR_ROTATION: float = PI / 2.0
const CURSOR_SIZE: Vector2 = Vector2(32, 32)
## dfgui icons at ×2.
const ICON_SIZE: Vector2 = Vector2(52, 52)
const ROW_MIN_HEIGHT: float = 48.0
const ROW_SEPARATION: int = 12

## When false, `cancel` does nothing (the first party member's command menu).
var allow_cancel: bool = true

var _entries: Array[Dictionary] = []
var _rows: Array[HBoxContainer] = []
var _cursors: Array[Control] = []
var _texts: Array[Label] = []
var _index: int = 0
var _active: bool = false


## One menu row. `value` is what `pick()` returns for it (must not be null).
static func entry(text: String, value: Variant, icon: Texture2D = null, detail: String = "",
		enabled: bool = true) -> Dictionary:
	return {&"text": text, &"value": value, &"icon": icon, &"detail": detail, &"enabled": enabled}


func set_entries(entries: Array[Dictionary]) -> void:
	for row: HBoxContainer in _rows:
		remove_child(row)
		row.queue_free()
	_rows.clear()
	_cursors.clear()
	_texts.clear()
	_entries = entries.duplicate()
	var any_icon: bool = false
	for e: Dictionary in entries:
		any_icon = any_icon or e[&"icon"] != null
	for i: int in entries.size():
		_add_row(i, entries[i], any_icon)
	_index = 0
	if not is_enabled(0):
		_index = _next_enabled(0, 1)
	_refresh()


## Waits for the player to choose a row (its value) or cancel (null).
func pick(start_index: int = -1) -> Variant:
	if start_index >= 0:
		select(start_index)
	_active = true
	_refresh()
	var value: Variant = await picked
	return value


func is_active() -> bool:
	return _active


func entry_count() -> int:
	return _entries.size()


func selected_index() -> int:
	return _index


func selected_value() -> Variant:
	return _entries[_index][&"value"] if _index < _entries.size() else null


func is_enabled(index: int) -> bool:
	return index >= 0 and index < _entries.size() and _entries[index][&"enabled"] as bool


func index_of(value: Variant) -> int:
	for i: int in _entries.size():
		if _entries[i][&"value"] == value:
			return i
	return -1


func entry_text(index: int) -> String:
	return _entries[index][&"text"] as String


func select(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	_index = index
	_refresh()
	highlighted.emit(selected_value())


## Applies a menu action as if pressed (`move_up`, `move_down`, `accept`, `cancel`).
## Used by the input handler and by tests.
func press(action: StringName) -> void:
	if not _active:
		return
	match action:
		&"move_up":
			select(_next_enabled(_index, -1))
		&"move_down":
			select(_next_enabled(_index, 1))
		&"accept":
			if is_enabled(_index):
				_close(selected_value())
		&"cancel":
			if allow_cancel:
				_close(null)


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not is_visible_in_tree():
		return
	var action: StringName = _action_of(event)
	if action == &"":
		return
	get_viewport().set_input_as_handled()
	press(action)


static func _action_of(event: InputEvent) -> StringName:
	if event.is_action_pressed(&"move_up", true) or event.is_action_pressed(&"ui_up", true):
		return &"move_up"
	if event.is_action_pressed(&"move_down", true) or event.is_action_pressed(&"ui_down", true):
		return &"move_down"
	if event.is_action_pressed(&"accept") or event.is_action_pressed(&"ui_accept"):
		return &"accept"
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"ui_cancel"):
		return &"cancel"
	return &""


func _close(value: Variant) -> void:
	_active = false
	_refresh()
	picked.emit(value)


## Next enabled row from `from` in direction `step` (wraps); `from` itself if none.
func _next_enabled(from: int, step: int) -> int:
	var count: int = _entries.size()
	for i: int in range(1, count + 1):
		var candidate: int = posmod(from + step * i, count)
		if is_enabled(candidate):
			return candidate
	return from


func _add_row(i: int, e: Dictionary, any_icon: bool) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_MIN_HEIGHT)
	row.add_theme_constant_override(&"separation", ROW_SEPARATION)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_entered.connect(func() -> void:
		if _active and is_enabled(i):
			select(i))
	row.gui_input.connect(func(event: InputEvent) -> void:
		var click: InputEventMouseButton = event as InputEventMouseButton
		if _active and click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			select(i)
			press(&"accept"))
	add_child(row)

	var slot: Control = Control.new()
	slot.custom_minimum_size = CURSOR_SIZE
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(slot)
	var cursor: TextureRect = TextureRect.new()
	cursor.texture = CURSOR
	cursor.size = CURSOR_SIZE
	cursor.pivot_offset = CURSOR_SIZE / 2.0
	cursor.rotation = CURSOR_ROTATION
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(cursor)
	_cursors.append(slot)

	if any_icon:
		var icon: TextureRect = TextureRect.new()
		icon.texture = e[&"icon"] as Texture2D
		icon.custom_minimum_size = ICON_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)

	var text: Label = Label.new()
	text.text = e[&"text"] as String
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	_texts.append(text)

	var detail_text: String = e[&"detail"] as String
	if not detail_text.is_empty():
		var detail: Label = Label.new()
		detail.text = detail_text
		detail.theme_type_variation = &"NumericLabel"
		detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(detail)
	_rows.append(row)


func _refresh() -> void:
	for i: int in _rows.size():
		_cursors[i].modulate.a = 1.0 if i == _index else 0.0
		if i == _index and not _active:
			_cursors[i].modulate.a = 0.35
		var color: Color = PALETTE.parchment
		if not is_enabled(i):
			color = PALETTE.parchment_dim
		elif i == _index and _active:
			color = PALETTE.gold
		_texts[i].add_theme_color_override(&"font_color", color)
		_rows[i].modulate = Color.WHITE if is_enabled(i) else Color(1, 1, 1, 0.6)
