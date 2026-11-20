extends SceneTree
## Generates the Phase 9 items (data/items/) and equipment (data/equipment/), each with its Gimble's
## 64 px icon (the Pilgrim's Chalice uses the dfgui ×2 goblet). Minor Potion and Holy Water stay in
## tools/build_battle_data.gd (enemies drop them); run that one first.
##   godot --headless --path <project> -s res://tools/build_items.gd
## This script is the source of truth for the prices and bonuses. Re-running it overwrites the files.

const ITEM_DIR: String = "res://data/items"
const EQUIPMENT_DIR: String = "res://data/equipment"
const FX_DIR: String = "res://data/fx"
const ICONS: String = "res://assets/vendor/gimbles/item_icons/64px/"
const DFGUI: String = "res://assets/vendor/dfgui/2x/"

var _failed: bool = false


func _initialize() -> void:
	for dir: String in [ITEM_DIR, EQUIPMENT_DIR]:
		DirAccess.make_dir_recursive_absolute(dir)
	_build_items()
	_build_equipment()
	print("items %s" % ("FAILED" if _failed else "written"))
	quit(1 if _failed else 0)


func _build_items() -> void:
	var mana: ItemData = _item(&"mana_potion", "Mana Potion", "053_mana_potion", 30,
			"A cold blue tincture that tastes of iron. Restores 15 MP.")
	mana.effect = ItemData.Effect.HEAL_MP
	mana.amount = 15
	mana.impact_fx = load(FX_DIR.path_join("potion_burst.tres")) as FxSpec
	_save(mana, ITEM_DIR)

	var gem: ItemData = _item(&"soul_gem", "Soul Gem", "073_soul_gem", 120,
			"A shard that still holds a heartbeat. Raises a fallen ally with 50 HP.")
	gem.effect = ItemData.Effect.REVIVE
	gem.amount = 50
	gem.impact_fx = load(FX_DIR.path_join("holy_light.tres")) as FxSpec
	_save(gem, ITEM_DIR)

	var torch: ItemData = _item(&"warding_torch", "Warding Torch", "143_torch", 60,
			"Pitch and blessed ash. The dead shun its light: fewer encounters for 200 steps.")
	torch.effect = ItemData.Effect.WARD
	torch.amount = 200
	torch.ward_mult = 0.25
	torch.usable_in_battle = false
	torch.target_mode = Targeting.Mode.ALL_ALLIES
	_save(torch, ITEM_DIR)

	var coins: ItemData = _item(&"gold_coins", "Gold Coins", "133_gold_coins", 0,
			"A tarnished handful of crowns. Worth 25 gold.")
	coins.effect = ItemData.Effect.GOLD
	coins.amount = 25
	coins.usable_in_field = false
	coins.usable_in_battle = false
	_save(coins, ITEM_DIR)

	var key: ItemData = _item(&"skull_key", "Skull Key", "081_skull_key", 0,
			"An iron key with a grinning skull for a bow. It must open something among the graves.")
	key.is_key_item = true
	key.effect = ItemData.Effect.NONE
	key.usable_in_field = false
	key.usable_in_battle = false
	_save(key, ITEM_DIR)


## Starting gear is none: the Worn Longsword waits in the village chest, the rest is sold by the
## merchant. Bonuses are sized against the Knight's level 1 stats (ATK 30, DEF 20).
func _build_equipment() -> void:
	var sword: EquipmentData = _gear(&"worn_longsword", "Worn Longsword", "001_worn_longsword",
			EquipmentData.Category.WEAPON, 60, StatBlock.create(0, 0, 6, 0),
			"Nicked and dull, but it holds an edge. ATK +6.")
	_save(sword, EQUIPMENT_DIR)

	var axe: EquipmentData = _gear(&"battle_axe", "Battle Axe", "015_battle_axe",
			EquipmentData.Category.WEAPON, 180, StatBlock.create(0, 0, 12, 0, 0, 0, -2, 0),
			"A heavy bearded axe. ATK +12, AGI -2.")
	_save(axe, EQUIPMENT_DIR)

	var stake: EquipmentData = _gear(&"silver_stake", "Silver Stake", "096_silver_stake",
			EquipmentData.Category.WEAPON, 150, StatBlock.create(0, 0, 3, 0, 0, 0, 2, 0),
			"A silver-shod dagger for the restless dead. ATK +3, AGI +2; attacks deal Holy damage.")
	stake.attack_element = Elements.Element.HOLY
	_save(stake, EQUIPMENT_DIR)

	var helm: EquipmentData = _gear(&"iron_helm", "Iron Helm", "037_iron_helm",
			EquipmentData.Category.HELM, 80, StatBlock.create(10, 0, 0, 3),
			"A dented iron cap. Max HP +10, DEF +3.")
	_save(helm, EQUIPMENT_DIR)

	var shield: EquipmentData = _gear(&"kite_shield", "Kite Shield", "048_kite_shield",
			EquipmentData.Category.SHIELD, 100, StatBlock.create(0, 0, 0, 6, 0, 2),
			"Oak and iron, painted with a faded saint. DEF +6, SPR +2.")
	_save(shield, EQUIPMENT_DIR)

	var chalice: EquipmentData = _gear(&"pilgrims_chalice", "Pilgrim's Chalice", "",
			EquipmentData.Category.ACCESSORY, 140, StatBlock.create(0, 0, 0, 0, 0, 3),
			"A pewter cup from the old pilgrim road. SPR +3; resists Shadow.")
	chalice.icon = _texture(DFGUI + "dfgui_icon-goblet.png")
	chalice.resist = {Elements.Element.SHADOW: Elements.RESIST}
	_save(chalice, EQUIPMENT_DIR)


func _item(id: StringName, label: String, icon: String, price: int, text: String) -> ItemData:
	var item: ItemData = ItemData.new()
	item.id = id
	item.display_name = label
	item.icon = _texture(ICONS + icon + ".png")
	item.price = price
	item.description = text
	return item


func _gear(id: StringName, label: String, icon: String, category: EquipmentData.Category, price: int,
		bonus: StatBlock, text: String) -> EquipmentData:
	var gear: EquipmentData = EquipmentData.new()
	gear.id = id
	gear.display_name = label
	if not icon.is_empty():
		gear.icon = _texture(ICONS + icon + ".png")
	gear.category = category
	gear.price = price
	gear.stat_bonus = bonus
	gear.target_mode = Targeting.Mode.SELF
	gear.description = text
	return gear


func _texture(path: String) -> Texture2D:
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		push_error("missing texture " + path)
		_failed = true
	return texture


func _save(res: Resource, dir: String) -> void:
	var path: String = dir.path_join(String(res.get(&"id")) + ".tres")
	var err: Error = ResourceSaver.save(res, path)
	if err != OK:
		push_error("could not save %s (%s)" % [path, error_string(err)])
		_failed = true
