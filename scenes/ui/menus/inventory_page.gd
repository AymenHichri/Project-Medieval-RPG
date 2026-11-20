class_name InventoryPage
extends VBoxContainer
## The pause menu's Items tab (PROJECT_PLAN.md Phase 9): category buttons (Items / Equipment / Key
## Items), a scrollable grid of Gimble's slots with the party's items and counts, and the focused
## item's name and description. Pressing a usable item uses it in the field (GameState.use_item):
## a Warding Torch at once, a potion or Soul Gem after choosing a party member (members it would do
## nothing for are greyed). `cancel` while choosing a member steps back to the grid
## (`handle_cancel`, called by the PauseMenu).

enum Category { ITEMS, EQUIPMENT, KEY_ITEMS }

const CATEGORY_NAMES: PackedStringArray = ["Items", "Equipment", "Key Items"]
const GRID_COLUMNS: int = 8

var category: Category = Category.ITEMS
## The item whose target is being chosen (null = not choosing).
var choosing: ItemData

var _category_buttons: Array[Button] = []
var _slots: Array[ItemSlot] = []
var _target_buttons: Array[Button] = []

@onready var _categories: HBoxContainer = %Categories
@onready var _grid: GridContainer = %Grid
@onready var _item_name: Label = %ItemName
@onready var _description: Label = %ItemDescription
@onready var _info: Label = %ItemInfo
@onready var _targets_box: VBoxContainer = %TargetsBox
@onready var _targets: VBoxContainer = %Targets
@onready var _message: Label = %Message


func _ready() -> void:
	_grid.columns = GRID_COLUMNS
	for i: int in CATEGORY_NAMES.size():
		var button: Button = Button.new()
		button.text = CATEGORY_NAMES[i]
		button.toggle_mode = true
		button.pressed.connect(show_category.bind(i))
		_categories.add_child(button)
		_category_buttons.append(button)
	_targets_box.visible = false


## Rebuilds the page from GameState (keeps the category; the message is cleared).
func refresh() -> void:
	_message.text = ""
	_close_targets()
	show_category(category)


## Lists one category's items.
func show_category(value: int) -> void:
	category = value as Category
	for i: int in _category_buttons.size():
		_category_buttons[i].set_pressed_no_signal(i == value)
	_fill_grid()


## The focusable control to start on (the first slot, else the category buttons).
func first_focus() -> Control:
	return _slots[0] if not _slots.is_empty() else _category_buttons[category]


## The items listed in the current category, in order (tests).
func listed_items() -> Array[ItemData]:
	var out: Array[ItemData] = []
	for slot: ItemSlot in _slots:
		out.append(slot.item)
	return out


func slots() -> Array[ItemSlot]:
	return _slots


func target_buttons() -> Array[Button]:
	return _target_buttons


func message() -> String:
	return _message.text


## Steps back from choosing a member. True when it did (the PauseMenu then stays open).
func handle_cancel() -> bool:
	if choosing == null:
		return false
	var item: ItemData = choosing
	_close_targets()
	_focus_item(item)
	return true


## Presses an item's slot (what the player does with `accept`): uses it, or opens the member choice.
func activate(item: ItemData) -> void:
	_describe(item)
	if not item.usable_in_field or not item.is_consumable():
		_deny("%s can't be used here." % item.display_name)
		return
	if not FieldItems.needs_target(item):
		_use(item, null)
		return
	var any: bool = false
	for member: PartyMember in GameState.party.members:
		any = any or FieldItems.can_use_on(item, member.combatant)
	if not any:
		_deny("It would have no effect.")
		return
	_open_targets(item)


## Uses the item being chosen on `member` (what pressing a member button does).
func use_on(member: PartyMember) -> bool:
	if choosing == null:
		return false
	return _use(choosing, member)


# --- grid -----------------------------------------------------------------------------------

func _items_in_category() -> Dictionary[ItemData, int]:
	match category:
		Category.EQUIPMENT:
			return GameState.inventory.entries(func(item: ItemData) -> bool: return item.is_equipment())
		Category.KEY_ITEMS:
			return GameState.inventory.entries(func(item: ItemData) -> bool: return item.is_key_item, true)
	return GameState.inventory.entries(func(item: ItemData) -> bool: return not item.is_equipment())


func _fill_grid() -> void:
	for slot: ItemSlot in _slots:
		_grid.remove_child(slot)
		slot.queue_free()
	_slots.clear()
	var items: Dictionary[ItemData, int] = _items_in_category()
	for item: ItemData in items:
		var slot: ItemSlot = ItemSlot.new()
		slot.show_item(item, items[item])
		slot.focus_entered.connect(_describe.bind(item))
		slot.pressed.connect(activate.bind(item))
		_grid.add_child(slot)
		_slots.append(slot)
	UiSounds.attach(self)
	if _slots.is_empty():
		_describe(null)
	else:
		_describe(_slots[0].item)


func _describe(item: ItemData) -> void:
	if item == null:
		_item_name.text = "Nothing here"
		_description.text = ""
		_info.text = ""
		return
	_item_name.text = item.display_name
	_description.text = item.description
	var notes: PackedStringArray = []
	if not item.is_key_item:
		notes.append("Owned %d" % GameState.inventory.count(item.id))
	if item.is_equipment():
		notes.append(EquipmentData.category_name((item as EquipmentData).category))
	elif item.is_key_item:
		notes.append("Key item")
	else:
		if item.usable_in_field:
			notes.append("Field")
		if item.usable_in_battle:
			notes.append("Battle")
	_info.text = "  ·  ".join(notes)


func _focus_item(item: ItemData) -> void:
	for slot: ItemSlot in _slots:
		if slot.item == item:
			slot.grab_focus()
			return
	if is_inside_tree():
		first_focus().grab_focus()


# --- targets --------------------------------------------------------------------------------

func _open_targets(item: ItemData) -> void:
	choosing = item
	_targets_box.visible = true
	_fill_targets()
	for button: Button in _target_buttons:
		if not button.disabled:
			button.grab_focus()
			break


func _fill_targets() -> void:
	for button: Button in _target_buttons:
		_targets.remove_child(button)
		button.queue_free()
	_target_buttons.clear()
	for member: PartyMember in GameState.party.members:
		var c: Combatant = member.combatant
		var button: Button = Button.new()
		button.text = "%s   HP %d/%d   MP %d/%d" % [member.display_name(), c.hp, c.max_hp(), c.mp, c.max_mp()]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not FieldItems.can_use_on(choosing, c)
		button.pressed.connect(use_on.bind(member))
		_targets.add_child(button)
		_target_buttons.append(button)
	UiSounds.attach(_targets)


func _close_targets() -> void:
	choosing = null
	if _targets_box != null:
		_targets_box.visible = false


func _use(item: ItemData, member: PartyMember) -> bool:
	if not GameState.use_item(item, member):
		_deny("It would have no effect.")
		return false
	AudioManager.sfx.play_ui_named(&"reward_item")
	if item.effect == ItemData.Effect.WARD:
		_message.text = "The %s burns. Fewer foes for %d steps." % [item.display_name, item.amount]
	elif member != null:
		_message.text = "Used %s on %s." % [item.display_name, member.display_name()]
	else:
		_message.text = "Used %s." % item.display_name
	var left: bool = GameState.inventory.has(item.id)
	_fill_grid()
	_describe(item if left else null)
	if choosing != null and left:
		_fill_targets()
		var still_useful: Button = null
		for button: Button in _target_buttons:
			if not button.disabled:
				still_useful = button
				break
		if still_useful != null:
			still_useful.grab_focus()
			return true
	_close_targets()
	if left:
		_focus_item(item)
	elif is_inside_tree():
		first_focus().grab_focus()
	return true


func _deny(text: String) -> void:
	_message.text = text
	AudioManager.sfx.play_ui_named(&"denied")
