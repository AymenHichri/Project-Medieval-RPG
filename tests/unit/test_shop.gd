extends TestCase
## Shop (Phase 9): buying needs enough gold and room, selling pays half the price rounded down,
## key items and price-0 items can't be sold, and a failed trade changes nothing.

var inv: Inventory


func before_each() -> void:
	inv = Inventory.new()


func _item(id: StringName) -> ItemData:
	return Inventory.item_data(id)


func _priced(price: int) -> ItemData:
	var item: ItemData = ItemData.new()
	item.id = &"test_priced"
	item.price = price
	return item


func test_buy_with_insufficient_gold_is_rejected() -> void:
	var potion: ItemData = _item(&"minor_potion")
	inv.gold = potion.price - 1
	assert_eq(Shop.buy(inv, potion), Shop.Result.NOT_ENOUGH_GOLD)
	assert_eq(inv.gold, potion.price - 1, "no gold taken")
	assert_eq(inv.count(&"minor_potion"), 0, "no potion given")
	assert_eq(Shop.buy(inv, potion, 0), Shop.Result.INVALID)


func test_buy() -> void:
	var potion: ItemData = _item(&"minor_potion")
	inv.gold = 100
	assert_eq(Shop.buy(inv, potion, 3), Shop.Result.OK)
	assert_eq(inv.gold, 100 - 3 * potion.price)
	assert_eq(inv.count(&"minor_potion"), 3)


func test_buy_into_a_full_stack_is_rejected() -> void:
	var potion: ItemData = _item(&"minor_potion")
	inv.add(&"minor_potion", 99)
	inv.gold = 1000
	assert_eq(Shop.buy(inv, potion), Shop.Result.BAG_FULL)
	assert_eq(inv.gold, 1000, "no gold taken")
	assert_eq(Shop.max_buyable(inv, potion), 0)


func test_max_buyable() -> void:
	var potion: ItemData = _item(&"minor_potion")
	inv.gold = potion.price * 4 + 3
	assert_eq(Shop.max_buyable(inv, potion), 4)
	inv.gold = 999999
	assert_eq(Shop.max_buyable(inv, potion), 99, "capped by the stack")


func test_sell_price_rounding() -> void:
	assert_eq(Shop.sell_price(_priced(25)), 12, "half of 25 rounds down")
	assert_eq(Shop.sell_price(_priced(20)), 10)
	assert_eq(Shop.sell_price(_priced(1)), 0, "half of 1 is nothing")
	assert_false(Shop.can_sell(_priced(1)))
	assert_false(Shop.can_sell(_priced(0)))
	assert_eq(Shop.sell_price(_item(&"battle_axe")), 90)


func test_sell() -> void:
	inv.add(&"battle_axe")
	inv.add(&"holy_water", 2)
	assert_eq(Shop.sell(inv, _item(&"battle_axe")), Shop.Result.OK)
	assert_eq(inv.gold, 90)
	assert_eq(inv.count(&"battle_axe"), 0)
	assert_eq(Shop.sell(inv, _item(&"holy_water"), 2), Shop.Result.OK)
	assert_eq(inv.gold, 90 + 2 * 15)


func test_sell_more_than_held_is_rejected() -> void:
	inv.add(&"holy_water")
	assert_eq(Shop.sell(inv, _item(&"holy_water"), 2), Shop.Result.NOT_ENOUGH_ITEMS)
	assert_eq(inv.count(&"holy_water"), 1)
	assert_eq(inv.gold, 0)


func test_key_items_and_coins_cannot_be_sold() -> void:
	inv.add(&"skull_key")
	assert_eq(Shop.sell(inv, _item(&"skull_key")), Shop.Result.CANNOT_SELL)
	assert_eq(Shop.buy(inv, _item(&"skull_key")), Shop.Result.INVALID, "nor bought")
	assert_false(Shop.can_sell(_item(&"gold_coins")))
