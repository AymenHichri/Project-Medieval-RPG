class_name EquipmentPage
extends VBoxContainer
## The pause menu's Equipment tab (PROJECT_PLAN.md Phase 9): one button per member, the member's
## four slots (Weapon / Shield / Helm / Accessory, Gimble's slots with the worn item's icon) and
## their stats. Pressing a slot lists the gear in the Inventory the member can wear there, plus
## "Remove"; focusing a choice previews every stat it changes (▲ in `heal`, ▼ in `blood`), and
## pressing it equips it (PartyMember.equip_from / unequip_to). A slot the character can't use
## (the Hexblade's shield) is disabled. `cancel` while choosing steps back (`handle_cancel`).

const PALETTE: UIPalette = preload("res://scenes/ui/theme/ui_palette.tres")
const STAT_LABELS: Dictionary[StringName, String] = {
	&"max_hp": "Max HP", &"max_mp": "Max MP", &"attack": "Attack", &"defense": "Defense",
	&"magic": "Magic", &"spirit": "Spirit", &"agility": "Agility", &"luck": "Luck",
}
const UP: String = "▲"
const DOWN: String = "▼"

## The member shown.
var shown: PartyMember
## The slot whose choices are listed (-1 = not choosing).
var choosing_slot: int = -1

var _member_buttons: Array[Button] = []
var _slot_rows: Array[ItemRow] = []
var _choice_rows: Array[ItemRow] = []
## Stat name → [current Label, arrow Label, new Label].
var _stat_cells: Dictionary[StringName, Array] = {}

@onready var _members: HBoxContainer = %Members
@onready var _slots_box: VBoxContainer = %Slots
@onready var _choices_box: VBoxContainer = %ChoicesBox
@onready var _choices: VBoxContainer = %Choices
@onready var _stats: GridContainer = %Stats
@onready var _description: Label = %Description


func _ready() -> void:
	for stat: StringName in STAT_LABELS:
		var label: Label = Label.new()
		label.text = STAT_LABELS[stat]
		label.theme_type_variation = &"SmallLabel"
		_stats.add_child(label)
		var cells: Array[Label] = []
		for i: int in 3:
			var cell: Label = Label.new()
			cell.theme_type_variation = &"NumericLabel"
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			cell.custom_minimum_size = Vector2(56 if i != 1 else 32, 0)
			_stats.add_child(cell)
			cells.append(cell)
		_stat_cells[stat] = cells
	for category: EquipmentData.Category in EquipmentData.Category.values():
		var row: ItemRow = ItemRow.create(null, "", "", 1, EquipmentData.category_name(category))
		row.slot.focus_entered.connect(_on_slot_focused.bind(category))
		row.slot.pressed.connect(open_choices.bind(category))
		_slots_box.add_child(row)
		_slot_rows.append(row)
	_choices_box.visible = false
	UiSounds.attach(self)


## Rebuilds the member buttons and shows `member` (default: the one shown, else the first).
func refresh(member: PartyMember = null) -> void:
	for button: Button in _member_buttons:
		_members.remove_child(button)
		button.queue_free()
	_member_buttons.clear()
	var members: Array[PartyMember] = GameState.party.members
	for m: PartyMember in members:
		var button: Button = Button.new()
		button.text = m.display_name()
		button.toggle_mode = true
		button.focus_entered.connect(show_member.bind(m))
		button.pressed.connect(show_member.bind(m))
		_members.add_child(button)
		_member_buttons.append(button)
	UiSounds.attach(_members)
	if members.is_empty():
		shown = null
		return
	if member == null:
		member = shown
	show_member(member if member in members else members[0])


## Shows one member's slots and stats.
func show_member(member: PartyMember) -> void:
	shown = member
	_close_choices()
	var members: Array[PartyMember] = GameState.party.members
	for i: int in _member_buttons.size():
		_member_buttons[i].set_pressed_no_signal(i < members.size() and members[i] == member)
	for i: int in _slot_rows.size():
		var category: EquipmentData.Category = i as EquipmentData.Category
		var row: ItemRow = _slot_rows[i]
		var worn: EquipmentData = member.equipped(category)
		row.slot.show_item(worn)
		var allowed: bool = category in member.data.allowed_equipment
		row.slot.disabled = not allowed
		row.set_dimmed(not allowed)
		row.name_label.text = worn.display_name if worn != null else ("—" if allowed else "Can't use")
	var weapon: EquipmentData.Category = EquipmentData.Category.WEAPON
	_show_stats(member.stats_with(weapon, member.equipped(weapon)))
	_description.text = ""


## The focusable control to start on (the first member button).
func first_focus() -> Control:
	return _member_buttons[0] if not _member_buttons.is_empty() else _slot_rows[0].slot


## Lists what `category` can hold: the member's wearable gear in the Inventory and "Remove".
func open_choices(category: EquipmentData.Category) -> void:
	if shown == null:
		return
	choosing_slot = category
	for row: ItemRow in _choice_rows:
		_choices.remove_child(row)
		row.queue_free()
	_choice_rows.clear()
	var gear: Dictionary[ItemData, int] = GameState.inventory.entries(func(item: ItemData) -> bool:
		return item is EquipmentData and (item as EquipmentData).category == category)
	for item: ItemData in gear:
		var piece: EquipmentData = item as EquipmentData
		var row: ItemRow = ItemRow.create(piece, piece.display_name, "×%d" % gear[item])
		var wearable: bool = shown.can_equip(piece)
		row.set_dimmed(not wearable)
		row.slot.disabled = not wearable
		_add_choice(row, piece)
	if shown.equipped(category) != null:
		_add_choice(ItemRow.create(null, "Remove"), null)
	_choices_box.visible = true
	for row: ItemRow in _choice_rows:
		if not row.slot.disabled:
			row.slot.grab_focus()
			return
	_description.text = "Nothing to wear here."
	AudioManager.sfx.play_ui_named(&"denied")
	_close_choices()


## Wears `item` in the slot being chosen (null = take it off). True when something changed.
func choose(item: EquipmentData) -> bool:
	if shown == null or choosing_slot < 0:
		return false
	var slot: EquipmentData.Category = choosing_slot as EquipmentData.Category
	var done: bool = false
	if item == null:
		done = shown.unequip_to(GameState.inventory, slot)
	else:
		done = shown.equip_from(GameState.inventory, item)
	AudioManager.sfx.play_ui_named(&"equip" if done else &"denied")
	show_member(shown)
	if is_inside_tree():
		_slot_rows[slot].slot.grab_focus()
	return done


## Steps back from the choice list. True when it did (the PauseMenu then stays open).
func handle_cancel() -> bool:
	if choosing_slot < 0:
		return false
	var slot: EquipmentData.Category = choosing_slot as EquipmentData.Category
	_close_choices()
	_show_stats(shown.stats_with(slot, shown.equipped(slot)))
	_slot_rows[slot].slot.grab_focus()
	return true


## The text of one stat's cells: "current", "arrow" and "new" (tests).
func stat_cells(stat: StringName) -> PackedStringArray:
	var cells: Array = _stat_cells[stat]
	return [(cells[0] as Label).text, (cells[1] as Label).text, (cells[2] as Label).text]


func slot_rows() -> Array[ItemRow]:
	return _slot_rows


func choice_rows() -> Array[ItemRow]:
	return _choice_rows


func member_buttons() -> Array[Button]:
	return _member_buttons


func _add_choice(row: ItemRow, item: EquipmentData) -> void:
	row.slot.focus_entered.connect(_preview.bind(item))
	row.slot.pressed.connect(choose.bind(item))
	_choices.add_child(row)
	_choice_rows.append(row)
	UiSounds.attach(row)


func _close_choices() -> void:
	choosing_slot = -1
	for row: ItemRow in _choice_rows:
		_choices.remove_child(row)
		row.queue_free()
	_choice_rows.clear()
	if _choices_box != null:
		_choices_box.visible = false


func _on_slot_focused(category: EquipmentData.Category) -> void:
	if shown == null or choosing_slot >= 0:
		return
	var worn: EquipmentData = shown.equipped(category)
	_description.text = worn.description if worn != null else ""
	_show_stats(shown.stats_with(category, worn))


## Stats with `item` in the slot being chosen, against the current ones.
func _preview(item: EquipmentData) -> void:
	if shown == null or choosing_slot < 0:
		return
	_description.text = item.description if item != null else "Take it off."
	_show_stats(shown.stats_with(choosing_slot as EquipmentData.Category, item))


func _show_stats(after: Dictionary[StringName, int]) -> void:
	for stat: StringName in _stat_cells:
		var cells: Array = _stat_cells[stat]
		var now: int = shown.combatant.stat(stat)
		var then: int = after[stat]
		(cells[0] as Label).text = str(now)
		var arrow: Label = cells[1] as Label
		var value: Label = cells[2] as Label
		if then == now:
			arrow.text = ""
			value.text = ""
			continue
		arrow.text = UP if then > now else DOWN
		value.text = str(then)
		var color: Color = PALETTE.heal if then > now else PALETTE.blood_bright
		arrow.add_theme_color_override(&"font_color", color)
		value.add_theme_color_override(&"font_color", color)
