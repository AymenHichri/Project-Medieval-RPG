extends TestCase
## Items outside battle (Phase 9, FieldItems + GameState.use_item): potions heal the living and are
## refused at full HP, the Soul Gem only raises the fallen, Mana Potions restore MP, battle-only
## items (Holy Water) and gear can't be used, and an item is spent only when it did something.

var _saved_inventory: Inventory
var _saved_party: Party
var knight: PartyMember


func before_each() -> void:
	_saved_inventory = GameState.inventory
	_saved_party = GameState.party
	GameState.inventory = Inventory.new()
	GameState.party = Party.new()
	GameState.ensure_party()
	knight = GameState.party.leader()


func after_each() -> void:
	GameState.inventory = _saved_inventory
	GameState.party = _saved_party


func _item(id: StringName) -> ItemData:
	return Inventory.item_data(id)


func test_new_item_data() -> void:
	var mana: ItemData = _item(&"mana_potion")
	assert_eq(mana.effect, ItemData.Effect.HEAL_MP)
	var gem: ItemData = _item(&"soul_gem")
	assert_eq(gem.effect, ItemData.Effect.REVIVE)
	assert_true(gem.usable_in_battle and gem.usable_in_field)
	var water: ItemData = _item(&"holy_water")
	assert_eq(water.element, Elements.Element.HOLY)
	assert_true(water.foe_damage > 0 and water.can_target_foes())
	assert_false(water.usable_in_field, "statuses end with the battle")
	for id: StringName in [&"minor_potion", &"mana_potion", &"holy_water", &"soul_gem", &"warding_torch", &"gold_coins", &"skull_key"]:
		assert_not_null(_item(id).icon, "%s has an icon" % id)


func test_potion_heals_and_is_spent() -> void:
	GameState.add_item(&"minor_potion", 2)
	knight.combatant.hp = 10
	assert_true(GameState.use_item(_item(&"minor_potion"), knight))
	assert_eq(knight.combatant.hp, 50)
	assert_eq(GameState.item_count(&"minor_potion"), 1)


func test_potion_at_full_hp_is_refused_and_kept() -> void:
	GameState.add_item(&"minor_potion")
	assert_false(FieldItems.can_use_on(_item(&"minor_potion"), knight.combatant))
	assert_false(GameState.use_item(_item(&"minor_potion"), knight))
	assert_eq(GameState.item_count(&"minor_potion"), 1, "not wasted")


func test_soul_gem_only_on_the_fallen() -> void:
	GameState.add_item(&"soul_gem")
	var gem: ItemData = _item(&"soul_gem")
	assert_false(GameState.use_item(gem, knight), "the Knight is standing")
	knight.combatant.take_damage(9999)
	assert_false(FieldItems.can_use_on(_item(&"minor_potion"), knight.combatant), "no potion on the fallen")
	assert_true(GameState.use_item(gem, knight))
	assert_eq(knight.combatant.hp, 50)
	assert_eq(GameState.item_count(&"soul_gem"), 0)


func test_mana_potion() -> void:
	GameState.add_item(&"mana_potion")
	knight.combatant.mp = 0
	assert_true(GameState.use_item(_item(&"mana_potion"), knight))
	assert_eq(knight.combatant.mp, mini(15, knight.combatant.max_mp()))


func test_battle_only_items_and_gear_are_refused() -> void:
	GameState.add_item(&"holy_water")
	GameState.add_item(&"worn_longsword")
	assert_false(GameState.use_item(_item(&"holy_water"), knight))
	assert_false(GameState.use_item(_item(&"worn_longsword"), knight))
	assert_eq(GameState.item_count(&"holy_water"), 1)
	assert_eq(GameState.item_count(&"worn_longsword"), 1)
