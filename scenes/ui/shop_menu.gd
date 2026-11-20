class_name ShopMenu
extends CanvasLayer
## A merchant's shop (PROJECT_PLAN.md Phase 9), opened by a ShopNpc. Pauses the game. Gimble's panel
## with Buy / Sell / Leave, a list of item rows (slot, name, price) and the focused item's
## description and count owned. Buy lists the merchant's `stock` at full price; Sell lists the
## party's items at half price (Shop.sell_price; key items are not listed). Each press trades one.
## `cancel` steps back from the list to the buttons, then closes.
##
##   shop.open(stock, "Merchant")
##   await shop.closed

signal opened
signal closed

enum Mode { NONE, BUY, SELL }

var mode: Mode = Mode.NONE
var stock: Array[ItemData] = []

var _rows: Array[ItemRow] = []

@onready var _panel: Control = %Panel
@onready var _title: Label = %Title
@onready var _gold: Label = %Gold
@onready var _buy: Button = %BuyButton
@onready var _sell: Button = %SellButton
@onready var _leave: Button = %LeaveButton
@onready var _list: VBoxContainer = %List
@onready var _item_name: Label = %ItemName
@onready var _description: Label = %ItemDescription
@onready var _owned: Label = %Owned
@onready var _message: Label = %Message


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_buy.pressed.connect(show_mode.bind(Mode.BUY))
	_sell.pressed.connect(show_mode.bind(Mode.SELL))
	_leave.pressed.connect(close)
	UiSounds.attach(_panel)
	visible = false


func is_open() -> bool:
	return visible


## Opens on the Buy list's buttons and pauses the game.
func open(items: Array[ItemData], title: String = "Merchant") -> void:
	if visible:
		return
	stock = items.duplicate()
	_title.text = title
	_message.text = ""
	visible = true
	get_tree().paused = true
	AudioManager.sfx.play_ui_named(&"open")
	show_mode(Mode.BUY, false)
	_buy.grab_focus()
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	closed.emit()


## Lists what can be bought or sold. `focus_list` moves the focus to the first row.
func show_mode(value: Mode, focus_list: bool = true) -> void:
	mode = value
	_buy.set_pressed_no_signal(value == Mode.BUY)
	_sell.set_pressed_no_signal(value == Mode.SELL)
	_fill()
	if focus_list and not _rows.is_empty():
		_rows[0].slot.grab_focus()
	elif focus_list:
		_message.text = "You have nothing to sell." if value == Mode.SELL else "Nothing for sale."


## Buys one `item` (Buy list). Returns the Shop result.
func buy(item: ItemData) -> Shop.Result:
	var result: Shop.Result = Shop.buy(GameState.inventory, item)
	match result:
		Shop.Result.OK:
			_message.text = "Bought %s for %d gold." % [item.display_name, item.price]
			AudioManager.sfx.play_ui_named(&"buy")
		Shop.Result.NOT_ENOUGH_GOLD:
			_message.text = "Not enough gold."
			AudioManager.sfx.play_ui_named(&"denied")
		Shop.Result.BAG_FULL:
			_message.text = "You can't carry more."
			AudioManager.sfx.play_ui_named(&"denied")
		_:
			AudioManager.sfx.play_ui_named(&"denied")
	_after_trade(item)
	return result


## Sells one `item` (Sell list). Returns the Shop result.
func sell(item: ItemData) -> Shop.Result:
	var result: Shop.Result = Shop.sell(GameState.inventory, item)
	if result == Shop.Result.OK:
		_message.text = "Sold %s for %d gold." % [item.display_name, Shop.sell_price(item)]
		AudioManager.sfx.play_ui_named(&"sell")
	else:
		_message.text = "The merchant won't take that."
		AudioManager.sfx.play_ui_named(&"denied")
	_after_trade(item)
	return result


## The items listed, in order (tests).
func listed_items() -> Array[ItemData]:
	var out: Array[ItemData] = []
	for row: ItemRow in _rows:
		out.append(row.slot.item)
	return out


func rows() -> Array[ItemRow]:
	return _rows


func message() -> String:
	return _message.text


func _fill() -> void:
	for row: ItemRow in _rows:
		_list.remove_child(row)
		row.queue_free()
	_rows.clear()
	_refresh_gold()
	if mode == Mode.BUY:
		for item: ItemData in stock:
			var row: ItemRow = ItemRow.create(item, item.display_name, "%d g" % item.price)
			row.set_dimmed(GameState.gold < item.price)
			_add_row(row, item, buy)
	elif mode == Mode.SELL:
		var owned: Dictionary[ItemData, int] = GameState.inventory.entries(func(item: ItemData) -> bool: return Shop.can_sell(item))
		for item: ItemData in owned:
			var row: ItemRow = ItemRow.create(item, item.display_name, "%d g" % Shop.sell_price(item), owned[item])
			_add_row(row, item, sell)
	if _rows.is_empty():
		_describe(null)
	else:
		_describe(_rows[0].slot.item)


func _add_row(row: ItemRow, item: ItemData, action: Callable) -> void:
	row.slot.focus_entered.connect(_describe.bind(item))
	row.slot.pressed.connect(func() -> void: action.call(item))
	_list.add_child(row)
	_rows.append(row)
	UiSounds.attach(row)


## Rebuilds the list after a trade and keeps the focus on the same item (or the first row).
func _after_trade(item: ItemData) -> void:
	var text: String = _message.text
	_fill()
	_message.text = text
	for row: ItemRow in _rows:
		if row.slot.item == item:
			row.slot.grab_focus()
			_describe(item)
			return
	if not _rows.is_empty():
		_rows[0].slot.grab_focus()
	elif mode == Mode.SELL:
		_sell.grab_focus()


func _describe(item: ItemData) -> void:
	if item == null:
		_item_name.text = ""
		_description.text = ""
		_owned.text = ""
		return
	_item_name.text = item.display_name
	_description.text = item.description
	_owned.text = "Owned %d" % GameState.inventory.count(item.id)


func _refresh_gold() -> void:
	_gold.text = "Gold  %d" % GameState.gold


func _list_has_focus() -> bool:
	var focused: Control = get_viewport().gui_get_focus_owner()
	return focused != null and _list.is_ancestor_of(focused)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or event.is_echo() or not event.is_action_pressed(&"cancel"):
		return
	get_viewport().set_input_as_handled()
	UiSounds.cancel()
	if _list_has_focus():
		(_sell if mode == Mode.SELL else _buy).grab_focus()
		return
	close()
