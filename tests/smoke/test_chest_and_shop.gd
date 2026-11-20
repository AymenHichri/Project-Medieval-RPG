extends TestCase
## Chests and the merchant (Phase 9): the village chest gives the Worn Longsword once and stays open
## after leaving and returning (flag in GameState.flags), the graveyard chests hold a Soul Gem and
## 50 gold, a locked chest needs its key; the merchant greets, then opens the shop, which buys with
## enough gold, refuses without, and sells at half price (no key items listed).

const VILLAGE: String = "res://scenes/world/maps/village_01.tscn"
const GRAVEYARD: String = "res://scenes/world/maps/graveyard_01.tscn"

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _map: Map
var _saved_inventory: Inventory
var _saved_flags: Dictionary[StringName, Variant]
var _saved_party: Party


func before_each() -> void:
	_saved_inventory = GameState.inventory
	_saved_flags = GameState.flags
	_saved_party = GameState.party
	GameState.inventory = Inventory.new()
	GameState.flags = {}
	GameState.party = Party.new()
	GameState.ensure_party()


func after_each() -> void:
	DialogueTestUtil.close_dialogue()
	_free_map()
	_tree.paused = false
	GameState.inventory = _saved_inventory
	GameState.flags = _saved_flags
	GameState.party = _saved_party


func _open(path: String) -> void:
	_free_map()
	_map = (load(path) as PackedScene).instantiate() as Map
	_tree.root.add_child(_map)
	_map.place_player(&"start" if path == VILLAGE else &"from_village")
	await _tree.process_frame


func _free_map() -> void:
	if is_instance_valid(_map):
		_tree.root.remove_child(_map)
		_map.free()
	_map = null


func _world(node_name: String) -> Node:
	return _map.get_node_or_null(NodePath("World/" + node_name))


## Runs `call` (an interaction) and clicks through any dialogue it opens.
func _through_dialogue(call: Callable) -> void:
	var done: Array[bool] = [false]
	var run: Callable = func() -> void:
		await call.call()
		done[0] = true
	run.call()
	var guard: int = 0
	while DialogueManager.is_active and guard < 50:
		guard += 1
		DialogueManager.advance()
		await _tree.process_frame
	for i: int in 3:
		await _tree.process_frame


func test_village_chest_opens_once_and_stays_open() -> void:
	await _open(VILLAGE)
	var chest: Chest = _world("ChestLongsword") as Chest
	assert_not_null(chest, "the village chest")
	assert_eq(chest.item, Inventory.item_data(&"worn_longsword"))
	assert_false(chest.is_opened())
	assert_eq(chest.sprite.animation, &"intact")
	await _through_dialogue(func() -> void: await chest.interact(_map.player))
	assert_eq(GameState.item_count(&"worn_longsword"), 1, "the sword is taken")
	assert_true(GameState.get_flag(&"chest_village_longsword") as bool, "flag set")
	assert_true(chest.is_opened())
	assert_eq(chest.sprite.animation, &"broken")
	await _through_dialogue(func() -> void: await chest.interact(_map.player))
	assert_eq(GameState.item_count(&"worn_longsword"), 1, "nothing more")
	await _open(GRAVEYARD)
	await _open(VILLAGE)
	chest = _world("ChestLongsword") as Chest
	assert_true(chest.is_opened(), "still open after leaving and coming back")
	assert_eq(chest.sprite.animation, &"broken")
	assert_true(chest.open_chest().is_empty())


func test_graveyard_chests() -> void:
	await _open(GRAVEYARD)
	var gem: Chest = _world("ChestSoulGem") as Chest
	var coins: Chest = _world("ChestCoins") as Chest
	assert_not_null(gem)
	assert_not_null(coins)
	assert_eq(gem.open_chest(), PackedStringArray(["Found Soul Gem."]))
	assert_eq(GameState.item_count(&"soul_gem"), 1)
	assert_eq(coins.open_chest(), PackedStringArray(["Found 50 gold."]))
	assert_eq(GameState.gold, 50)
	assert_ne(gem.opened_flag, coins.opened_flag, "each chest has its own flag")


func test_locked_chest_needs_its_key() -> void:
	await _open(GRAVEYARD)
	var chest: Chest = (load("res://scenes/world/components/chest.tscn") as PackedScene).instantiate() as Chest
	chest.item = Inventory.item_data(&"mana_potion")
	chest.count = 2
	chest.opened_flag = &"test_locked_chest"
	chest.required_key = Inventory.item_data(&"skull_key")
	_map.add_child(chest)
	assert_true(chest.is_locked())
	assert_true(chest.open_chest().is_empty(), "stays shut")
	assert_eq(GameState.item_count(&"mana_potion"), 0)
	GameState.add_item(&"skull_key")
	assert_eq(chest.open_chest(), PackedStringArray(["Found 2 Mana Potion."]))
	assert_true(GameState.inventory.has(&"skull_key"), "the key is kept")


func test_merchant_opens_the_shop() -> void:
	await _open(VILLAGE)
	var merchant: ShopNpc = _world("Merchant") as ShopNpc
	assert_not_null(merchant, "the merchant at the market stall")
	assert_true(Inventory.item_data(&"minor_potion") in merchant.stock)
	assert_true(Inventory.item_data(&"warding_torch") in merchant.stock)
	assert_eq(merchant.dialogue_id, &"merchant_greeting")
	var talk: Callable = func() -> void: await merchant.interact(_map.player)
	talk.call()
	var guard: int = 0
	while DialogueManager.is_active and guard < 20:
		guard += 1
		DialogueManager.advance()
		await _tree.process_frame
	await _tree.process_frame
	assert_true(GameState.get_flag(&"met_merchant") as bool)
	var shop: ShopMenu = merchant.shop_menu
	assert_not_null(shop)
	assert_true(shop.is_open(), "the shop opens after the greeting")
	assert_true(_tree.paused, "and pauses the game")
	assert_eq(shop.listed_items(), merchant.stock)
	shop.close()
	assert_false(_tree.paused)


func test_buy_and_sell() -> void:
	await _open(VILLAGE)
	var merchant: ShopNpc = _world("Merchant") as ShopNpc
	merchant.open_shop()
	var shop: ShopMenu = merchant.shop_menu
	var potion: ItemData = Inventory.item_data(&"minor_potion")
	assert_eq(shop.buy(potion), Shop.Result.NOT_ENOUGH_GOLD, "no gold yet")
	assert_eq(shop.message(), "Not enough gold.")
	GameState.add_gold(50)
	assert_eq(shop.buy(potion), Shop.Result.OK)
	assert_eq(GameState.gold, 50 - potion.price)
	assert_eq(GameState.item_count(&"minor_potion"), 1)
	GameState.add_item(&"skull_key")
	GameState.add_item(&"worn_longsword")
	shop.show_mode(ShopMenu.Mode.SELL)
	var listed: Array[ItemData] = shop.listed_items()
	assert_false(Inventory.item_data(&"skull_key") in listed, "key items are not offered")
	assert_true(Inventory.item_data(&"worn_longsword") in listed)
	var gold_before: int = GameState.gold
	assert_eq(shop.sell(Inventory.item_data(&"worn_longsword")), Shop.Result.OK)
	assert_eq(GameState.gold, gold_before + 30, "half of 60")
	assert_false(Inventory.item_data(&"worn_longsword") in shop.listed_items())
	shop.close()
