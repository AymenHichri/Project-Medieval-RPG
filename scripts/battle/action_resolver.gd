class_name ActionResolver
extends RefCounted
## Executes one BattleAction and returns its events. Holds no battle state of its own: the sides,
## RNG and item callback are injected by BattleEngine (or a test).

## Flee: chance = FLEE_BASE_CHANCE + (party agility − enemy agility, averaged) × FLEE_PER_AGILITY.
const FLEE_BASE_CHANCE: float = 0.5
const FLEE_PER_AGILITY: float = 0.025
const FLEE_MIN_CHANCE: float = 0.1
const FLEE_MAX_CHANCE: float = 0.95
## Physical power of a plain attack, in percent.
const BASIC_ATTACK_POWER: int = 100

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var rng: RandomNumberGenerator
var can_flee: bool = true
## `func(item: ItemData) -> bool`: removes one `item` from the inventory, false if none is left.
## Not set = items are free (tests, debug battles).
var consume_item: Callable = Callable()


func _init(party_side: Array[Combatant], enemy_side: Array[Combatant], random: RandomNumberGenerator) -> void:
	party = party_side
	enemies = enemy_side
	rng = random


func resolve(action: BattleAction) -> Array[BattleEvent]:
	var actor: Combatant = action.actor
	if not actor.is_alive():
		return []
	var blocker: ActiveStatus = StatusEffects.blocking_status(actor)
	if blocker != null:
		blocker.blocked_this_round = true
		return [BattleEvent.new(BattleEvent.Type.ACTION_SKIPPED, {&"actor": actor, &"status": blocker.data})]
	var events: Array[BattleEvent] = [BattleEvent.new(BattleEvent.Type.ACTION_STARTED, {&"actor": actor, &"action": action})]
	match action.kind:
		BattleAction.Kind.ATTACK:
			events.append_array(_attack(action))
		BattleAction.Kind.SKILL:
			events.append_array(_skill(action))
		BattleAction.Kind.ITEM:
			events.append_array(_item(action))
		BattleAction.Kind.DEFEND:
			actor.is_defending = true
			events.append(BattleEvent.new(BattleEvent.Type.DEFENDING, {&"actor": actor}))
		BattleAction.Kind.FLEE:
			events.append_array(_flee(actor))
	return events


func allies_of(c: Combatant) -> Array[Combatant]:
	return party if c.side == Combatant.Team.PARTY else enemies


func opponents_of(c: Combatant) -> Array[Combatant]:
	return enemies if c.side == Combatant.Team.PARTY else party


static func living(group: Array[Combatant]) -> Array[Combatant]:
	var alive: Array[Combatant] = []
	for c: Combatant in group:
		if c.is_alive():
			alive.append(c)
	return alive


## Flee chance for the current sides.
func flee_chance() -> float:
	var diff: float = _average_agility(party) - _average_agility(enemies)
	return clampf(FLEE_BASE_CHANCE + diff * FLEE_PER_AGILITY, FLEE_MIN_CHANCE, FLEE_MAX_CHANCE)


# --- action kinds ---------------------------------------------------------------------------

func _attack(action: BattleAction) -> Array[BattleEvent]:
	var target: Combatant = _single_target(action, true)
	if target == null:
		return [_failed(action.actor, &"no_target")]
	return _physical_hit(action.actor, target, BASIC_ATTACK_POWER, &"attack", Elements.Element.PHYSICAL)


func _skill(action: BattleAction) -> Array[BattleEvent]:
	var actor: Combatant = action.actor
	var skill: SkillData = action.skill
	if actor.mp < skill.mp_cost:
		return [_failed(actor, &"not_enough_mp")]
	var targets: Array[Combatant] = _skill_targets(action, skill.target_mode, skill.effect == SkillData.Effect.DAMAGE)
	if targets.is_empty():
		return [_failed(actor, &"no_target")]
	var events: Array[BattleEvent] = []
	if skill.mp_cost > 0:
		actor.mp -= skill.mp_cost
		events.append(BattleEvent.new(BattleEvent.Type.MP_CHANGED, {&"target": actor, &"amount": -skill.mp_cost, &"mp": actor.mp}))
	for chosen: Combatant in targets:
		var hit_target: Combatant = chosen
		for _hit: int in skill.hits:
			if not hit_target.is_alive():
				# A single-target combo moves on to another target; area hits stop.
				if not Targeting.is_single(skill.target_mode):
					break
				hit_target = _retarget(hit_target, skill.effect == SkillData.Effect.DAMAGE)
				if hit_target == null:
					break
			if skill.effect == SkillData.Effect.HEAL:
				events.append(_heal(actor, hit_target, DamageCalculator.heal(
						skill.power, actor.effective_stat(skill.scaling_stat), rng,
						StatusEffects.healing_received_multiplier(hit_target))))
			elif skill.category == SkillData.Category.MAGIC:
				events.append_array(_magic_hit(actor, hit_target, skill))
			else:
				events.append_array(_physical_hit(actor, hit_target, skill.power, skill.scaling_stat, skill.element))
			if skill.inflicts != null and hit_target.is_alive() and rng.randf() < skill.inflict_chance:
				events.append_array(StatusEffects.apply(hit_target, skill.inflicts, rng))
	return events


func _item(action: BattleAction) -> Array[BattleEvent]:
	var actor: Combatant = action.actor
	var item: ItemData = action.item
	var wants_dead: bool = item.effect == ItemData.Effect.REVIVE
	var targets: Array[Combatant] = []
	if wants_dead:
		for c: Combatant in action.targets:
			if not c.is_alive():
				targets.append(c)
	else:
		targets = _skill_targets(action, item.target_mode, item.effect == ItemData.Effect.DAMAGE)
	if targets.is_empty():
		return [_failed(actor, &"no_target")]
	if consume_item.is_valid() and not (consume_item.call(item) as bool):
		return [_failed(actor, &"no_item")]
	var events: Array[BattleEvent] = []
	for target: Combatant in targets:
		match item.effect:
			ItemData.Effect.HEAL_HP:
				var amount: int = roundi(item.amount * StatusEffects.healing_received_multiplier(target))
				events.append(_heal(actor, target, amount))
			ItemData.Effect.HEAL_MP:
				var gained: int = target.restore_mp(item.amount)
				events.append(BattleEvent.new(BattleEvent.Type.MP_CHANGED, {&"target": target, &"amount": gained, &"mp": target.mp}))
			ItemData.Effect.CURE_STATUS:
				events.append_array(StatusEffects.cure(target, item.cures))
			ItemData.Effect.REVIVE:
				events.append(BattleEvent.new(BattleEvent.Type.REVIVED, {&"target": target, &"amount": target.revive(item.amount)}))
			ItemData.Effect.DAMAGE:
				events.append_array(_apply_damage(actor, target, item.amount, Elements.Element.PHYSICAL, false, Elements.NORMAL))
	return events


func _flee(actor: Combatant) -> Array[BattleEvent]:
	if not can_flee:
		return [_failed(actor, &"cannot_flee")]
	var chance: float = flee_chance()
	var success: bool = rng.randf() < chance
	return [BattleEvent.new(BattleEvent.Type.FLEE_ATTEMPTED, {&"actor": actor, &"success": success, &"chance": chance})]


# --- hits -----------------------------------------------------------------------------------

func _physical_hit(actor: Combatant, target: Combatant, power: int, stat: StringName,
		element: Elements.Element) -> Array[BattleEvent]:
	var critical: bool = DamageCalculator.is_critical(actor.effective_stat(&"luck"), rng)
	var mult: float = DamageCalculator.element_multiplier(target, element)
	var amount: int = DamageCalculator.physical(actor.effective_stat(stat), target.effective_stat(&"defense"),
			rng, critical, power / 100.0, mult, target.is_defending)
	return _apply_damage(actor, target, amount, element, critical, mult)


func _magic_hit(actor: Combatant, target: Combatant, skill: SkillData) -> Array[BattleEvent]:
	var mult: float = DamageCalculator.element_multiplier(target, skill.element)
	var amount: int = DamageCalculator.magical(skill.power, actor.effective_stat(skill.scaling_stat),
			target.effective_stat(&"spirit"), rng, mult, target.is_defending)
	return _apply_damage(actor, target, amount, skill.element, false, mult)


func _apply_damage(actor: Combatant, target: Combatant, amount: int, element: Elements.Element,
		critical: bool, mult: float) -> Array[BattleEvent]:
	var lost: int = target.take_damage(amount)
	var events: Array[BattleEvent] = [BattleEvent.new(BattleEvent.Type.DAMAGE, {
		&"target": target, &"amount": lost, &"element": element, &"critical": critical,
		&"weak": Elements.is_weak(mult), &"resisted": Elements.is_resisted(mult),
		&"immune": Elements.is_immune(mult), &"source": actor})]
	if not target.is_alive():
		events.append(BattleEvent.new(BattleEvent.Type.DEFEATED, {&"target": target}))
	elif lost > 0:
		events.append_array(StatusEffects.on_hit(target))
	return events


func _heal(actor: Combatant, target: Combatant, amount: int) -> BattleEvent:
	return BattleEvent.new(BattleEvent.Type.HEAL, {&"target": target, &"amount": target.restore_hp(amount), &"source": actor})


# --- targeting ------------------------------------------------------------------------------

func _single_target(action: BattleAction, offensive: bool) -> Combatant:
	var chosen: Combatant = action.targets[0] if not action.targets.is_empty() else null
	if chosen != null and chosen.is_alive():
		return chosen
	if chosen == null:
		var pool: Array[Combatant] = living(opponents_of(action.actor) if offensive else allies_of(action.actor))
		return pool[rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else null
	return _retarget(chosen, offensive)


## Replacement for a target that is gone: a random living combatant of the same side for
## offensive actions (DQ rule), the most wounded living ally for supportive ones.
func _retarget(gone: Combatant, offensive: bool) -> Combatant:
	var pool: Array[Combatant] = living(party if gone.side == Combatant.Team.PARTY else enemies)
	if pool.is_empty():
		return null
	if offensive:
		return pool[rng.randi_range(0, pool.size() - 1)]
	var best: Combatant = pool[0]
	for c: Combatant in pool:
		if c.hp_ratio() < best.hp_ratio():
			best = c
	return best


func _skill_targets(action: BattleAction, mode: Targeting.Mode, offensive: bool) -> Array[Combatant]:
	match mode:
		Targeting.Mode.ALL_ENEMIES:
			return living(opponents_of(action.actor))
		Targeting.Mode.ALL_ALLIES:
			return living(allies_of(action.actor))
		Targeting.Mode.SELF:
			return [action.actor]
	var target: Combatant = _single_target(action, offensive)
	if target == null:
		return []
	return [target]


func _failed(actor: Combatant, reason: StringName) -> BattleEvent:
	return BattleEvent.new(BattleEvent.Type.ACTION_FAILED, {&"actor": actor, &"reason": reason})


static func _average_agility(group: Array[Combatant]) -> float:
	var alive: Array[Combatant] = living(group)
	if alive.is_empty():
		return 0.0
	var total: int = 0
	for c: Combatant in alive:
		total += c.effective_stat(&"agility")
	return float(total) / alive.size()
