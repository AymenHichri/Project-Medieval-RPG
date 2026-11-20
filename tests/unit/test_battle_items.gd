extends TestCase
## Items in battle (Phase 9): the battle spends items from the Inventory through the engine's
## `consume_item` callback, Holy Water thrown at a skeleton deals Holy damage (×2, weak) and still
## cures a Curse on an ally, and the Soul Gem raises a fallen ally.

func _item(id: StringName) -> ItemData:
	return Inventory.item_data(id)


func _skeleton() -> Combatant:
	return Combatant.from_enemy(load("res://data/enemies/skeleton.tres") as EnemyData)


func _knight() -> Combatant:
	return Combatant.from_character(load("res://data/characters/knight.tres") as CharacterData)


func test_holy_water_burns_the_undead() -> void:
	var hero: Combatant = _knight()
	var skeleton: Combatant = _skeleton()
	var resolver: ActionResolver = ActionResolver.new([hero], [skeleton], BattleFixtures.rng(1))
	var water: ItemData = _item(&"holy_water")
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.use_item(hero, water, [skeleton]))
	var hit: BattleEvent = BattleFixtures.first(events, BattleEvent.Type.DAMAGE)
	assert_not_null(hit, "it damages the foe")
	assert_eq(hit.subject(), skeleton)
	assert_eq(hit.get_value(&"element"), Elements.Element.HOLY)
	assert_eq(hit.get_value(&"amount"), water.foe_damage * 2, "skeletons take double Holy")
	assert_true(hit.get_value(&"weak") as bool)


func test_holy_water_still_cures_an_ally() -> void:
	var hero: Combatant = _knight()
	var curse: StatusEffectData = load("res://data/status_effects/curse.tres") as StatusEffectData
	StatusEffects.apply(hero, curse, BattleFixtures.rng(1))
	assert_true(hero.has_status(&"curse"))
	var resolver: ActionResolver = ActionResolver.new([hero], [_skeleton()], BattleFixtures.rng(1))
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.use_item(hero, _item(&"holy_water"), [hero]))
	assert_false(hero.has_status(&"curse"), "Curse lifted")
	assert_eq(BattleFixtures.count(events, BattleEvent.Type.DAMAGE), 0, "no damage to the ally")


func test_soul_gem_revives() -> void:
	var hero: Combatant = _knight()
	var ally: Combatant = _knight()
	ally.take_damage(9999)
	var resolver: ActionResolver = ActionResolver.new([hero, ally], [_skeleton()], BattleFixtures.rng(1))
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.use_item(hero, _item(&"soul_gem"), [ally]))
	assert_eq(BattleFixtures.count(events, BattleEvent.Type.REVIVED), 1)
	assert_eq(ally.hp, 50)


func test_battle_spends_from_the_inventory() -> void:
	var inv: Inventory = Inventory.new()
	inv.add(&"minor_potion", 2)
	inv.add(&"worn_longsword")
	inv.add(&"warding_torch")
	var battle: BattleController = (load("res://scenes/battle/battle_scene.tscn") as PackedScene).instantiate() as BattleController
	battle.instant = true
	battle.inventory = inv
	var counts: Dictionary[ItemData, int] = battle.item_counts()
	assert_eq(counts.size(), 1, "only battle consumables are offered")
	assert_eq(counts[_item(&"minor_potion")], 2)
	assert_true(battle._consume_item(_item(&"minor_potion")))
	assert_eq(inv.count(&"minor_potion"), 1, "spent from the inventory itself")
	assert_true(battle._consume_item(_item(&"minor_potion")))
	assert_false(battle._consume_item(_item(&"minor_potion")), "none left")
	assert_true(battle.item_counts().is_empty())
	battle.free()
