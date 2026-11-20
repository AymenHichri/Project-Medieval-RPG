class_name FieldItems
extends RefCounted
## Using an item outside battle (PROJECT_PLAN.md Phase 9: the pause menu's Items tab). Pure rules:
## healing, MP, cures and revives work on party combatants as in battle; a WARD item (Warding
## Torch) adds an encounter-rate modifier for `amount` steps. An item that would change nothing
## (full HP, nobody fallen, ...) is refused, so it is not wasted. GameState.use_item spends it.

## Id of the encounter-rate modifier a WARD item adds (a second torch restarts it).
static func ward_modifier_id(item: ItemData) -> StringName:
	return StringName("item_" + String(item.id))


## The item can be used outside battle on `target` (null for items that need no target).
static func can_use_on(item: ItemData, target: Combatant) -> bool:
	if item == null or not item.usable_in_field or not item.is_consumable():
		return false
	if item.effect == ItemData.Effect.WARD:
		return true
	if target == null:
		return false
	match item.effect:
		ItemData.Effect.HEAL_HP:
			return target.is_alive() and target.hp < target.max_hp()
		ItemData.Effect.HEAL_MP:
			return target.is_alive() and target.mp < target.max_mp()
		ItemData.Effect.CURE_STATUS:
			return target.is_alive() and _has_curable(item, target)
		ItemData.Effect.REVIVE:
			return not target.is_alive()
	return false


## The item needs a party member chosen (single-target and not a WARD).
static func needs_target(item: ItemData) -> bool:
	return item.effect != ItemData.Effect.WARD and item.target_mode != Targeting.Mode.ALL_ALLIES


## Applies the item to `targets` (the whole party for ALL_ALLIES, ignored for WARD). Returns true
## when it changed anything, i.e. when it should be spent.
static func apply(item: ItemData, targets: Array[Combatant],
		modifiers: Dictionary[StringName, RateModifier]) -> bool:
	if item == null or not item.usable_in_field or not item.is_consumable():
		return false
	if item.effect == ItemData.Effect.WARD:
		modifiers[ward_modifier_id(item)] = RateModifier.new(item.ward_mult, item.amount)
		return true
	var used: bool = false
	for target: Combatant in targets:
		if not can_use_on(item, target):
			continue
		used = true
		match item.effect:
			ItemData.Effect.HEAL_HP:
				target.restore_hp(roundi(item.amount * StatusEffects.healing_received_multiplier(target)))
			ItemData.Effect.HEAL_MP:
				target.restore_mp(item.amount)
			ItemData.Effect.CURE_STATUS:
				StatusEffects.cure(target, item.cures)
			ItemData.Effect.REVIVE:
				target.revive(item.amount)
	return used


static func _has_curable(item: ItemData, target: Combatant) -> bool:
	for status: ActiveStatus in target.statuses:
		if item.cures.is_empty() or status.data in item.cures:
			return true
	return false
