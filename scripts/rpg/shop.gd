class_name Shop
extends RefCounted
## Buying and selling (PROJECT_PLAN.md §6.4, Phase 9): pure rules on an Inventory (which holds the
## gold). Items are bought at `ItemData.price` and sold back for half of it, rounded down. Key
## items and items with no price cannot be sold. A failed trade changes nothing.

enum Result { OK, NOT_ENOUGH_GOLD, BAG_FULL, NOT_ENOUGH_ITEMS, CANNOT_SELL, INVALID }

## Share of the price paid back when selling.
const SELL_RATE: float = 0.5


## Price of `count` of an item.
static func buy_price(item: ItemData, count: int = 1) -> int:
	return item.price * count


## What one `item` sells for: half its price, rounded down (0 = cannot be sold).
static func sell_price(item: ItemData) -> int:
	if item == null or item.is_key_item:
		return 0
	return floori(item.price * SELL_RATE)


static func can_sell(item: ItemData) -> bool:
	return sell_price(item) > 0


## Buys `count` of `item`: pays and adds them, or fails without changing anything.
static func buy(inventory: Inventory, item: ItemData, count: int = 1) -> Result:
	if item == null or count <= 0 or item.is_key_item:
		return Result.INVALID
	if inventory.gold < buy_price(item, count):
		return Result.NOT_ENOUGH_GOLD
	if inventory.count(item.id) + count > Inventory.MAX_STACK:
		return Result.BAG_FULL
	inventory.spend_gold(buy_price(item, count))
	inventory.add(item.id, count)
	return Result.OK


## Sells `count` of `item` for `sell_price` each, or fails without changing anything.
static func sell(inventory: Inventory, item: ItemData, count: int = 1) -> Result:
	if item == null or count <= 0:
		return Result.INVALID
	if not can_sell(item):
		return Result.CANNOT_SELL
	if not inventory.remove(item.id, count):
		return Result.NOT_ENOUGH_ITEMS
	inventory.add_gold(sell_price(item) * count)
	return Result.OK


## How many of `item` the gold and the bag allow.
static func max_buyable(inventory: Inventory, item: ItemData) -> int:
	if item == null or item.is_key_item:
		return 0
	var room: int = Inventory.MAX_STACK - inventory.count(item.id)
	if item.price <= 0:
		return room
	return clampi(inventory.gold / item.price, 0, room)
