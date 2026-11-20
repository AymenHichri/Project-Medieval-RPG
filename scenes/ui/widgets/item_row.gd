class_name ItemRow
extends HBoxContainer
## A list row for items (equipment slots and choices, the shop): an ItemSlot (the focusable,
## pressable part), an optional caption ("Weapon"), the item's name and a right-aligned detail
## (price, count). Built in code:
##   var row: ItemRow = ItemRow.create(item, "Minor Potion", "20 g")
##   row.slot.pressed.connect(...)

const NAME_WIDTH: float = 320.0
const CAPTION_WIDTH: float = 150.0
## Space kept clear on the right (a list's scroll bar).
const RIGHT_PAD: float = 20.0

var slot: ItemSlot
var caption_label: Label
var name_label: Label
var detail_label: Label


static func create(item: ItemData, text: String, detail: String = "", count: int = 1,
		caption: String = "") -> ItemRow:
	var row: ItemRow = ItemRow.new()
	row.add_theme_constant_override(&"separation", 16)
	row.slot = ItemSlot.new()
	row.slot.show_item(item, count)
	row.add_child(row.slot)
	if not caption.is_empty():
		row.caption_label = Label.new()
		row.caption_label.text = caption
		row.caption_label.theme_type_variation = &"SmallLabel"
		row.caption_label.custom_minimum_size = Vector2(CAPTION_WIDTH, 0)
		row.caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(row.caption_label)
	row.name_label = Label.new()
	row.name_label.text = text
	row.name_label.custom_minimum_size = Vector2(NAME_WIDTH, 0)
	row.name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(row.name_label)
	row.detail_label = Label.new()
	row.detail_label.text = detail
	row.detail_label.theme_type_variation = &"NumericLabel"
	row.detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(row.detail_label)
	var pad: Control = Control.new()
	pad.custom_minimum_size = Vector2(RIGHT_PAD, 0)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pad)
	return row


## Greys the name (the slot stays focusable so the description can still be read).
func set_dimmed(dimmed: bool) -> void:
	modulate = Color(1, 1, 1, 0.55) if dimmed else Color.WHITE
