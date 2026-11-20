extends TestCase
## Equipment (Phase 9): bonuses join the stats on demand and leave with the item, gear moves between
## the Inventory and the slots, a slot the character can't use is refused, resistances feed
## DamageCalculator, a weapon's element reaches plain attacks, and gear multiplies the encounter rate.

const KNIGHT: String = "res://data/characters/knight.tres"
const HEXBLADE: String = "res://data/characters/hexblade.tres"

var inv: Inventory
var knight: PartyMember


func before_each() -> void:
	inv = Inventory.new()
	knight = PartyMember.create(load(KNIGHT) as CharacterData)


func _gear(id: StringName) -> EquipmentData:
	return Inventory.item_data(id) as EquipmentData


func test_gear_data_matches_the_plan() -> void:
	for id: StringName in [&"worn_longsword", &"battle_axe", &"silver_stake", &"iron_helm", &"kite_shield", &"pilgrims_chalice"]:
		var gear: EquipmentData = _gear(id)
		assert_not_null(gear, "%s exists" % id)
		if gear != null:
			assert_not_null(gear.icon, "%s has an icon" % id)
			assert_true(gear.price > 0, "%s has a price" % id)
			assert_false(gear.usable_in_field or gear.usable_in_battle, "%s is not a consumable" % id)
	assert_eq(_gear(&"silver_stake").attack_element, Elements.Element.HOLY)
	assert_eq(_gear(&"pilgrims_chalice").category, EquipmentData.Category.ACCESSORY)
	assert_eq(_gear(&"kite_shield").category, EquipmentData.Category.SHIELD)


func test_bonuses_applied_and_removed() -> void:
	var base_attack: int = knight.stats.attack
	inv.add(&"worn_longsword")
	assert_true(knight.equip_from(inv, _gear(&"worn_longsword")))
	assert_eq(knight.combatant.stat(&"attack"), base_attack + 6, "ATK +6 while worn")
	assert_eq(knight.combatant.effective_stat(&"attack"), base_attack + 6)
	assert_eq(knight.stats.attack, base_attack, "never stored into the level stats")
	assert_eq(inv.count(&"worn_longsword"), 0, "taken out of the bag")
	assert_true(knight.unequip_to(inv, EquipmentData.Category.WEAPON))
	assert_eq(knight.combatant.stat(&"attack"), base_attack, "bonus gone with the sword")
	assert_eq(inv.count(&"worn_longsword"), 1, "back in the bag")
	assert_false(knight.unequip_to(inv, EquipmentData.Category.WEAPON), "nothing left to take off")


func test_swapping_returns_the_old_piece() -> void:
	inv.add(&"worn_longsword")
	inv.add(&"battle_axe")
	knight.equip_from(inv, _gear(&"worn_longsword"))
	assert_true(knight.equip_from(inv, _gear(&"battle_axe")))
	assert_eq(knight.equipped(EquipmentData.Category.WEAPON), _gear(&"battle_axe"))
	assert_eq(inv.count(&"worn_longsword"), 1, "the sword went back")
	assert_eq(inv.count(&"battle_axe"), 0)
	assert_eq(knight.combatant.stat(&"agility"), knight.stats.agility - 2, "negative bonuses apply too")


func test_needs_the_item_in_the_inventory() -> void:
	assert_false(knight.equip_from(inv, _gear(&"iron_helm")), "not owned")
	assert_null(knight.equipped(EquipmentData.Category.HELM))


func test_invalid_category_is_rejected() -> void:
	var hexblade: PartyMember = PartyMember.create(load(HEXBLADE) as CharacterData)
	inv.add(&"kite_shield")
	assert_false(hexblade.can_equip(_gear(&"kite_shield")), "the Hexblade carries no shield")
	assert_false(hexblade.equip_from(inv, _gear(&"kite_shield")))
	assert_null(hexblade.equipped(EquipmentData.Category.SHIELD))
	assert_eq(inv.count(&"kite_shield"), 1, "the shield stays in the bag")
	assert_true(knight.equip_from(inv, _gear(&"kite_shield")), "the Knight can")


func test_max_hp_gear_clamps_hp_when_removed() -> void:
	inv.add(&"iron_helm")
	knight.equip_from(inv, _gear(&"iron_helm"))
	knight.heal_full()
	var with_helm: int = knight.combatant.max_hp()
	assert_eq(with_helm, knight.stats.max_hp + 10)
	assert_eq(knight.combatant.hp, with_helm, "a full heal fills the raised maximum")
	knight.unequip_to(inv, EquipmentData.Category.HELM)
	assert_eq(knight.combatant.hp, knight.stats.max_hp, "HP clamped to the lower maximum")


func test_preview_changes_nothing() -> void:
	inv.add(&"battle_axe")
	var preview: Dictionary[StringName, int] = knight.stats_with(EquipmentData.Category.WEAPON, _gear(&"battle_axe"))
	assert_eq(preview[&"attack"], knight.stats.attack + 12)
	assert_eq(preview[&"agility"], knight.stats.agility - 2)
	assert_eq(knight.combatant.stat(&"attack"), knight.stats.attack, "nothing worn after the preview")
	assert_true(knight.combatant.equipment.is_empty())


func test_element_resist_feeds_damage_calculator() -> void:
	var c: Combatant = knight.combatant
	assert_almost_eq(DamageCalculator.element_multiplier(c, Elements.Element.SHADOW), 1.0, 0.001)
	inv.add(&"pilgrims_chalice")
	knight.equip_from(inv, _gear(&"pilgrims_chalice"))
	var mult: float = DamageCalculator.element_multiplier(c, Elements.Element.SHADOW)
	assert_almost_eq(mult, Elements.RESIST, 0.001, "the chalice halves Shadow")
	assert_true(Elements.is_resisted(mult))
	var plain: int = DamageCalculator.magical(40, 20, c.effective_stat(&"spirit"), BattleFixtures.rng(5), 1.0)
	var resisted: int = DamageCalculator.magical(40, 20, c.effective_stat(&"spirit"), BattleFixtures.rng(5), mult)
	assert_eq(resisted, roundi(plain / 2.0), "the same roll, halved")
	assert_eq(StatusPage.resistance_tags(c).size(), 1, "the Party tab lists it")


func test_resisted_spell_in_battle() -> void:
	var hex: SkillData = load("res://data/skills/hex.tres") as SkillData
	var caster: Combatant = BattleFixtures.foe(StatBlock.create(100, 50, 10, 10, 30, 10, 10, 0))
	caster.skills = [hex]
	inv.add(&"pilgrims_chalice")
	var plain: Array[BattleEvent] = _cast(hex, caster, knight.combatant)
	knight.combatant.hp = knight.combatant.max_hp()
	knight.equip_from(inv, _gear(&"pilgrims_chalice"))
	var warded: Array[BattleEvent] = _cast(hex, caster, knight.combatant)
	var before: BattleEvent = BattleFixtures.first(plain, BattleEvent.Type.DAMAGE)
	var after: BattleEvent = BattleFixtures.first(warded, BattleEvent.Type.DAMAGE)
	assert_true(after.get_value(&"resisted") as bool, "reported as resisted")
	assert_true((after.get_value(&"amount") as int) < (before.get_value(&"amount") as int), "less damage")


func _cast(skill: SkillData, caster: Combatant, target: Combatant) -> Array[BattleEvent]:
	caster.mp = caster.max_mp()
	var resolver: ActionResolver = ActionResolver.new([target], [caster], BattleFixtures.rng(9))
	return resolver.resolve(BattleAction.use_skill(caster, skill, [target]))


func test_silver_stake_makes_attacks_holy() -> void:
	var skeleton: Combatant = Combatant.from_enemy(load("res://data/enemies/skeleton.tres") as EnemyData)
	inv.add(&"silver_stake")
	knight.equip_from(inv, _gear(&"silver_stake"))
	assert_eq(knight.combatant.attack_element(), Elements.Element.HOLY)
	var resolver: ActionResolver = ActionResolver.new([knight.combatant], [skeleton], BattleFixtures.rng(2))
	var events: Array[BattleEvent] = resolver.resolve(BattleAction.attack(knight.combatant, skeleton))
	var hit: BattleEvent = BattleFixtures.first(events, BattleEvent.Type.DAMAGE)
	assert_eq(hit.get_value(&"element"), Elements.Element.HOLY)
	assert_true(hit.get_value(&"weak") as bool, "skeletons are weak to Holy")


func test_gear_multiplies_the_encounter_rate() -> void:
	var saved_party: Party = GameState.party
	var saved_mods: Dictionary[StringName, RateModifier] = GameState.encounter_rate_modifiers
	GameState.party = Party.new()
	GameState.party.add(knight)
	GameState.encounter_rate_modifiers = {}
	var charm: EquipmentData = EquipmentData.new()
	charm.id = &"test_charm"
	charm.category = EquipmentData.Category.ACCESSORY
	charm.encounter_rate_mult = 0.5
	knight.combatant.equipment[charm.category] = charm
	assert_almost_eq(GameState.get_encounter_multiplier(), 0.5, 0.001)
	GameState.add_encounter_modifier(&"test", 0.5)
	assert_almost_eq(GameState.get_encounter_multiplier(), 0.25, 0.001, "multiplied with the modifiers")
	GameState.party = saved_party
	GameState.encounter_rate_modifiers = saved_mods
