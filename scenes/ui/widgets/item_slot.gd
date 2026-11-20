class_name ItemSlot
extends Button
## One item slot (PROJECT_PLAN.md Phase 9): Gimble's 36 px slot at 2× (72 px, theme variation
## `SlotButton`; `slot_selected` when focused) showing the item's 64 px icon and, for a stack, its
## count in the corner. Focusable and pressable like any button (UiSounds.attach gives it sounds).
## Built in code: `ItemSlot.new()`, then `show_item(item, count)`.

const SLOT_SIZE: Vector2 = Vector2(72, 72)

## The item shown (null = an empty slot).
var item: ItemData

var _count: Label


func _init() -> void:
	theme_type_variation = &"SlotButton"
	custom_minimum_size = SLOT_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	focus_mode = Control.FOCUS_ALL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_count = Label.new()
	_count.theme_type_variation = &"SlotCountLabel"
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_count.offset_right = -6
	_count.offset_bottom = -2
	add_child(_count)


## Shows `shown` (null = empty) with `count` in the corner (hidden below 2).
func show_item(shown: ItemData, count: int = 1) -> void:
	item = shown
	icon = shown.icon if shown != null else null
	tooltip_text = shown.display_name if shown != null else ""
	_count.text = str(count) if count > 1 else ""


## The count text in the corner (tests).
func count_text() -> String:
	return _count.text
