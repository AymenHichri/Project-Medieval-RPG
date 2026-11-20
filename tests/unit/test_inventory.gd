extends TestCase
## Inventory (Phase 9): stacks capped at 99, removing more than held is rejected, key items in
## their own list (never stacked or sold), Gold Coins become gold, and the signals fire.

var inv: Inventory
var _changes: int = 0


func before_each() -> void:
	inv = Inventory.new()
	_changes = 0
	inv.changed.connect(func() -> void: _changes += 1)


func test_add_and_count() -> void:
	assert_eq(inv.add(&"minor_potion", 3), 3)
	assert_eq(inv.count(&"minor_potion"), 3)
	assert_true(inv.has(&"minor_potion", 3))
	assert_false(inv.has(&"minor_potion", 4))
	assert_eq(inv.ids(), [&"minor_potion"] as Array[StringName])
	assert_eq(_changes, 1, "changed fires once per add")


func test_stack_cap_is_99() -> void:
	assert_eq(inv.add(&"minor_potion", 120), Inventory.MAX_STACK, "only 99 fit")
	assert_eq(inv.count(&"minor_potion"), 99)
	assert_eq(inv.add(&"minor_potion"), 0, "a full stack takes no more")
	assert_false(inv.has_room(&"minor_potion"))
	inv.remove(&"minor_potion", 2)
	assert_eq(inv.add(&"minor_potion", 5), 2, "fills up to 99 again")


func test_remove_below_zero_is_rejected() -> void:
	inv.add(&"mana_potion", 3)
	assert_false(inv.remove(&"mana_potion", 5), "can't remove more than held")
	assert_eq(inv.count(&"mana_potion"), 3, "nothing removed")
	assert_false(inv.remove(&"holy_water"), "none held")
	assert_false(inv.remove(&"mana_potion", 0), "a zero amount is rejected")
	assert_true(inv.remove(&"mana_potion", 3))
	assert_eq(inv.count(&"mana_potion"), 0)
	assert_false(&"mana_potion" in inv.ids(), "an empty stack is dropped")


func test_key_items_are_kept_apart_once() -> void:
	assert_eq(inv.add(&"skull_key", 3), 1, "one of a key item")
	assert_eq(inv.add(&"skull_key"), 0, "never a second")
	assert_true(inv.is_key_item(&"skull_key"))
	assert_eq(inv.count(&"skull_key"), 1)
	assert_eq(inv.key_items(), [&"skull_key"] as Array[StringName])
	assert_true(inv.ids().is_empty(), "not among the stacks")
	assert_false(inv.has_room(&"skull_key"))


func test_key_items_cannot_be_sold() -> void:
	inv.add(&"skull_key")
	var key: ItemData = Inventory.item_data(&"skull_key")
	assert_false(Shop.can_sell(key))
	assert_eq(Shop.sell(inv, key), Shop.Result.CANNOT_SELL)
	assert_true(inv.has(&"skull_key"), "still held")
	assert_eq(inv.gold, 0, "no gold paid")


func test_gold_coins_turn_into_gold() -> void:
	var gold_seen: Array[int] = []
	inv.gold_changed.connect(func(value: int) -> void: gold_seen.append(value))
	assert_eq(inv.add(&"gold_coins", 2), 2)
	assert_eq(inv.gold, 50, "2 × 25 gold")
	assert_eq(inv.count(&"gold_coins"), 0, "no coin stack")
	assert_eq(gold_seen, [50] as Array[int])


func test_gold_spend_and_limits() -> void:
	inv.add_gold(30)
	assert_false(inv.spend_gold(31), "not enough")
	assert_eq(inv.gold, 30)
	assert_true(inv.spend_gold(30))
	inv.add_gold(-5)
	assert_eq(inv.gold, 0, "never below 0")
	inv.gold = Inventory.MAX_GOLD + 10
	assert_eq(inv.gold, Inventory.MAX_GOLD)


func test_unknown_items_are_refused() -> void:
	assert_eq(inv.add(&"no_such_item"), 0)
	assert_true(inv.is_empty())


func test_entries_and_battle_items() -> void:
	inv.add(&"minor_potion", 2)
	inv.add(&"warding_torch")
	inv.add(&"worn_longsword")
	inv.add(&"skull_key")
	var battle: Dictionary[ItemData, int] = inv.battle_items()
	assert_eq(battle.size(), 1, "only the potion is a battle item")
	assert_eq(battle[Inventory.item_data(&"minor_potion")], 2)
	var gear: Dictionary[ItemData, int] = inv.entries(func(item: ItemData) -> bool: return item.is_equipment())
	assert_eq(gear.size(), 1)
	assert_true(gear.keys()[0] is EquipmentData)
	assert_eq(inv.entries().size(), 3, "key items left out by default")
	assert_eq(inv.entries(Callable(), true).size(), 4)


func test_clear() -> void:
	inv.add(&"minor_potion")
	inv.add(&"skull_key")
	inv.add_gold(10)
	inv.clear()
	assert_true(inv.is_empty())
	assert_eq(inv.gold, 0)


func test_game_state_delegates_to_its_inventory() -> void:
	var saved: Inventory = GameState.inventory
	var events: Array[int] = []
	GameState.inventory = Inventory.new()
	var on_items: Callable = func() -> void: events.append(1)
	GameState.items_changed.connect(on_items)
	GameState.add_item(&"minor_potion", 2)
	GameState.add_gold(40)
	assert_eq(GameState.item_count(&"minor_potion"), 2)
	assert_eq(GameState.gold, 40)
	assert_eq(GameState.inventory.gold, 40, "gold lives in the inventory")
	GameState.add_item(&"minor_potion", -5)
	assert_eq(GameState.item_count(&"minor_potion"), 0, "negative amounts remove, never below 0")
	assert_eq(events.size(), 2, "items_changed relayed")
	GameState.items_changed.disconnect(on_items)
	GameState.inventory = saved
