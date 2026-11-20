class_name Inventory
extends RefCounted
## What the party carries (PROJECT_PLAN.md §6.4, Phase 9): item stacks by `ItemData.id` (at most
## MAX_STACK each), key items in their own list (one of each, never sold or used up), and gold.
## Gear that is not worn is an ordinary stack; worn gear lives on the PartyMember.
## Picking up Gold Coins (an item whose effect is GOLD) adds their value in gold instead.
## Owned by GameState (`GameState.inventory`); Shop and PartyMember work on it.

## Contents changed (stacks or key items).
signal changed
signal gold_changed(gold: int)

const MAX_STACK: int = 99
const MAX_GOLD: int = 999999
## Item ids are the file names in these folders (consumables and key items, then gear).
const ITEM_DIRS: Array[String] = ["res://data/items", "res://data/equipment"]

var gold: int = 0:
	set(value):
		gold = clampi(value, 0, MAX_GOLD)
		gold_changed.emit(gold)

## Item id → count (> 0), in the order first picked up.
var _stacks: Dictionary[StringName, int] = {}
var _key_items: Array[StringName] = []


## Adds `amount` of an item; returns how many were added (fewer when the stack is full, 1 at most
## for a key item, 0 for an unknown id). GOLD items turn into gold.
func add(id: StringName, amount: int = 1) -> int:
	if amount <= 0:
		return 0
	var data: ItemData = item_data(id)
	if data == null:
		return 0
	if data.effect == ItemData.Effect.GOLD and not data.is_equipment():
		add_gold(data.amount * amount)
		return amount
	if data.is_key_item:
		if id in _key_items:
			return 0
		_key_items.append(id)
		changed.emit()
		return 1
	var added: int = mini(amount, MAX_STACK - count(id))
	if added <= 0:
		return 0
	_stacks[id] = count(id) + added
	changed.emit()
	return added


## Removes `amount` of an item. False (and nothing removed) when there are fewer than that.
func remove(id: StringName, amount: int = 1) -> bool:
	if amount <= 0 or count(id) < amount:
		return false
	if id in _key_items:
		_key_items.erase(id)
	elif _stacks[id] == amount:
		_stacks.erase(id)
	else:
		_stacks[id] -= amount
	changed.emit()
	return true


func count(id: StringName) -> int:
	if id in _key_items:
		return 1
	return _stacks.get(id, 0) as int


func has(id: StringName, amount: int = 1) -> bool:
	return count(id) >= amount


## One more of this item would fit (its stack is below MAX_STACK; a key item not yet held).
func has_room(id: StringName) -> bool:
	return count(id) < (1 if id in _key_items else MAX_STACK)


func is_key_item(id: StringName) -> bool:
	return id in _key_items


## Stacked item ids, in pick-up order (key items not included).
func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_stacks.keys())
	return out


func key_items() -> Array[StringName]:
	return _key_items.duplicate()


func is_empty() -> bool:
	return _stacks.is_empty() and _key_items.is_empty()


## The stacks as ItemData → count, keeping those `filter` accepts (`func(item: ItemData) -> bool`;
## invalid = all). Key items are included when `with_key_items`.
func entries(filter: Callable = Callable(), with_key_items: bool = false) -> Dictionary[ItemData, int]:
	var out: Dictionary[ItemData, int] = {}
	var all: Array[StringName] = ids()
	if with_key_items:
		all.append_array(_key_items)
	for id: StringName in all:
		var data: ItemData = item_data(id)
		if data != null and (not filter.is_valid() or filter.call(data) as bool):
			out[data] = count(id)
	return out


## The items usable in battle and their counts (the battle's Items menu).
func battle_items() -> Dictionary[ItemData, int]:
	return entries(func(item: ItemData) -> bool: return item.usable_in_battle and item.is_consumable())


func add_gold(amount: int) -> void:
	gold += amount


## Pays `amount`. False (nothing paid) when there is not enough gold.
func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	return true


func clear() -> void:
	_stacks.clear()
	_key_items.clear()
	gold = 0
	changed.emit()


## The ItemData of an id (`data/items/<id>.tres` or `data/equipment/<id>.tres`), or null.
static func item_data(id: StringName) -> ItemData:
	for dir: String in ITEM_DIRS:
		var path: String = dir.path_join(String(id) + ".tres")
		if ResourceLoader.exists(path):
			return load(path) as ItemData
	push_warning("Inventory: unknown item '%s'" % id)
	return null
