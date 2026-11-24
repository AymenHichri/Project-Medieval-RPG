extends TestCase
## Pause menu Items and Equipment tabs (Phase 9), in the village: the tabs open their pages, the
## Items page lists items by category in Gimble's slots, uses a potion on a wounded member (and
## refuses one that would do nothing), lights a Warding Torch; the Equipment page equips a sword
## (ATK changes in the page and in the member's stats), previews with ▲/▼, steps back on cancel,
## and disables the slots a character can't use.

const VILLAGE: String = "res://scenes/world/maps/village_01.tscn"

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _map: Map
var _saved_inventory: Inventory
var _saved_party: Party
var _saved_mods: Dictionary[StringName, RateModifier]


func before_each() -> void:
	_saved_inventory = GameState.inventory
	_saved_party = GameState.party
	_saved_mods = GameState.encounter_rate_modifiers
	GameState.inventory = Inventory.new()
	GameState.party = Party.new()
	GameState.encounter_rate_modifiers = {}
	GameState.ensure_party()
	_map = (load(VILLAGE) as PackedScene).instantiate() as Map
	_tree.root.add_child(_map)
	_map.place_player(&"start")
	await _tree.process_frame


func after_each() -> void:
	if is_instance_valid(_map):
		_map.pause_menu.close()
		_tree.root.remove_child(_map)
		_map.free()
	_map = null
	_tree.paused = false
	GameState.inventory = _saved_inventory
	GameState.party = _saved_party
	GameState.encounter_rate_modifiers = _saved_mods


func _menu() -> PauseMenu:
	assert_true(_map.open_pause_menu(), "the pause menu opens")
	return _map.pause_menu


func test_tabs_switch_pages() -> void:
	var menu: PauseMenu = _menu()
	assert_eq(menu.current_tab(), PauseMenu.TAB_PARTY)
	assert_true(menu.status_page.visible)
	menu.show_tab(PauseMenu.TAB_ITEMS)
	assert_true(menu.inventory_page.visible and not menu.status_page.visible)
	menu.show_tab(PauseMenu.TAB_EQUIPMENT)
	assert_true(menu.equipment_page.visible and not menu.inventory_page.visible)
	var tabs: TabBar = menu.get_node("%Tabs") as TabBar
	assert_false(tabs.is_tab_disabled(PauseMenu.TAB_ITEMS))
	assert_false(tabs.is_tab_disabled(PauseMenu.TAB_EQUIPMENT))
	assert_false(tabs.is_tab_disabled(PauseMenu.TAB_JOURNAL), "Journal since Phase 10")
	assert_false(tabs.is_tab_disabled(PauseMenu.TAB_MAP))


func test_items_page_lists_by_category() -> void:
	GameState.add_item(&"minor_potion", 3)
	GameState.add_item(&"worn_longsword")
	GameState.add_item(&"skull_key")
	var menu: PauseMenu = _menu()
	menu.show_tab(PauseMenu.TAB_ITEMS)
	var page: InventoryPage = menu.inventory_page
	assert_eq(page.listed_items(), [Inventory.item_data(&"minor_potion")] as Array[ItemData])
	var slot: ItemSlot = page.slots()[0]
	assert_eq(slot.icon, Inventory.item_data(&"minor_potion").icon, "the item's icon in the slot")
	assert_eq(slot.count_text(), "3")
	assert_eq(slot.custom_minimum_size, ItemSlot.SLOT_SIZE)
	page.show_category(InventoryPage.Category.EQUIPMENT)
	assert_eq(page.listed_items(), [Inventory.item_data(&"worn_longsword")] as Array[ItemData])
	page.show_category(InventoryPage.Category.KEY_ITEMS)
	assert_eq(page.listed_items(), [Inventory.item_data(&"skull_key")] as Array[ItemData])


func test_use_a_potion_from_the_items_page() -> void:
	GameState.add_item(&"minor_potion", 2)
	var knight: PartyMember = GameState.party.leader()
	var menu: PauseMenu = _menu()
	menu.show_tab(PauseMenu.TAB_ITEMS)
	var page: InventoryPage = menu.inventory_page
	var potion: ItemData = Inventory.item_data(&"minor_potion")
	page.activate(potion)
	assert_null(page.choosing, "at full HP there is no one to use it on")
	assert_eq(page.message(), "It would have no effect.")
	knight.combatant.hp = 20
	page.activate(potion)
	assert_eq(page.choosing, potion, "choosing a member")
	assert_eq(page.target_buttons().size(), 1)
	assert_false(page.target_buttons()[0].disabled)
	assert_true(page.handle_cancel(), "cancel steps back to the grid")
	assert_null(page.choosing)
	assert_false(page.handle_cancel(), "a second cancel closes the menu instead")
	page.activate(potion)
	assert_true(page.use_on(knight))
	assert_eq(knight.combatant.hp, 60)
	assert_eq(GameState.item_count(&"minor_potion"), 1)
	assert_eq(page.slots()[0].count_text(), "", "one left: no count shown")


func test_light_a_warding_torch() -> void:
	GameState.add_item(&"warding_torch")
	var menu: PauseMenu = _menu()
	menu.show_tab(PauseMenu.TAB_ITEMS)
	menu.inventory_page.activate(Inventory.item_data(&"warding_torch"))
	assert_almost_eq(GameState.get_encounter_multiplier(), 0.25, 0.001)
	assert_eq(GameState.item_count(&"warding_torch"), 0)
	assert_true(menu.inventory_page.listed_items().is_empty())


func test_equip_a_sword_from_the_equipment_page() -> void:
	GameState.add_item(&"worn_longsword")
	var knight: PartyMember = GameState.party.leader()
	var base: int = knight.stats.attack
	var menu: PauseMenu = _menu()
	menu.show_tab(PauseMenu.TAB_EQUIPMENT)
	var page: EquipmentPage = menu.equipment_page
	assert_eq(page.shown, knight)
	assert_eq(page.stat_cells(&"attack"), PackedStringArray([str(base), "", ""]))
	page.open_choices(EquipmentData.Category.WEAPON)
	assert_eq(page.choice_rows().size(), 1, "the sword, and no Remove for an empty slot")
	page._preview(Inventory.item_data(&"worn_longsword") as EquipmentData)
	assert_eq(page.stat_cells(&"attack"), PackedStringArray([str(base), EquipmentPage.UP, str(base + 6)]))
	assert_true(page.handle_cancel(), "cancel steps back to the slots")
	page.open_choices(EquipmentData.Category.WEAPON)
	assert_true(page.choose(Inventory.item_data(&"worn_longsword") as EquipmentData))
	assert_eq(knight.combatant.stat(&"attack"), base + 6, "ATK raised")
	assert_eq(page.stat_cells(&"attack")[0], str(base + 6), "and shown")
	assert_eq(page.slot_rows()[EquipmentData.Category.WEAPON].name_label.text, "Worn Longsword")
	menu.show_tab(PauseMenu.TAB_PARTY)
	assert_eq(menu.status_page.stat_text(&"attack"), str(base + 6), "the Party tab agrees")
	menu.show_tab(PauseMenu.TAB_EQUIPMENT)
	page.open_choices(EquipmentData.Category.WEAPON)
	assert_eq(page.choice_rows().size(), 1, "only Remove now")
	page._preview(null)
	assert_eq(page.stat_cells(&"attack")[1], EquipmentPage.DOWN)
	assert_true(page.choose(null))
	assert_eq(knight.combatant.stat(&"attack"), base)
	assert_eq(GameState.item_count(&"worn_longsword"), 1)


func test_hexblade_shield_slot_is_disabled() -> void:
	GameState.recruit(load("res://data/characters/hexblade.tres") as CharacterData)
	var menu: PauseMenu = _menu()
	menu.show_tab(PauseMenu.TAB_EQUIPMENT)
	var page: EquipmentPage = menu.equipment_page
	page.show_member(GameState.party.members[1])
	var shield: ItemRow = page.slot_rows()[EquipmentData.Category.SHIELD]
	assert_true(shield.slot.disabled)
	assert_eq(shield.name_label.text, "Can't use")
	assert_false(page.slot_rows()[EquipmentData.Category.WEAPON].slot.disabled)
