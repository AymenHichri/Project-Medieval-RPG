class_name ActionResolver
extends RefCounted
## Executes one BattleAction and returns its events. Holds no battle state of its own: the sides,
## RNG and item callback are injected by BattleEngine (or a test).
## Taunt and Guard (Phase 8): a single-target offensive action is drawn to a living opponent with a
## Taunt status (Provoke), chosen when the action resolves, so a Provoke used first this round
## already counts. Then, if its target is guarded, it strikes the living guardian instead (a
## COVERED event comes first). Area actions are never redirected.
## Phase 9: a plain attack has the element of the attacker's weapon (Silver Stake: HOLY). An item
## with `foe_damage` used on an opponent deals that damage of its element instead of its effect
## (Holy Water on a skeleton); DAMAGE items use their element and the target's affinity.

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
	var events: Array[BattleEvent] = []
	target = _cover(action.actor, target, events)
	events.append_array(_physical_hit(action.actor, target, BASIC_ATTACK_POWER, &"attack", action.actor.attack_element()))
	return events


func _skill(action: BattleAction) -> Array[BattleEvent]:
	var actor: Combatant = action.actor
	var skill: SkillData = action.skill
	if actor.mp < skill.mp_cost:
		return [_failed(actor, &"not_enough_mp")]
	var offensive: bool = skill.is_offensive()
	var targets: Array[Combatant] = _skill_targets(action, skill.target_mode, offensive)
	if targets.is_empty():
		return [_failed(actor, &"no_target")]
	var events: Array[BattleEvent] = []
	if skill.mp_cost > 0:
		actor.mp -= skill.mp_cost
		events.append(BattleEvent.new(BattleEvent.Type.MP_CHANGED, {&"target": actor, &"amount": -skill.mp_cost, &"mp": actor.mp}))
	if not offensive and skill.effect != SkillData.Effect.HEAL:
		for target: Combatant in targets:
			events.append_array(_support(actor, target, skill))
		return events
	if offensive and Targeting.is_single(skill.target_mode):
		targets[0] = _cover(actor, targets[0], events)
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
	elif _aimed_at_foe(action):
		targets = _skill_targets(action, Targeting.Mode.ONE_ENEMY, true)
	else:
		targets = _skill_targets(action, item.target_mode, item.effect == ItemData.Effect.DAMAGE)
	if targets.is_empty():
		return [_failed(actor, &"no_target")]
	if consume_item.is_valid() and not (consume_item.call(item) as bool):
		return [_failed(actor, &"no_item")]
	var events: Array[BattleEvent] = []
	for target: Combatant in targets:
		if target.side != actor.side:
			var amount: int = item.foe_damage if item.effect != ItemData.Effect.DAMAGE else item.amount
			events.append_array(_item_damage(actor, target, amount, item.element))
			continue
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
	return events


## An item used on one opponent: a DAMAGE item, or an ally item with `foe_damage` thrown at a foe.
func _aimed_at_foe(action: BattleAction) -> bool:
	if not action.item.can_target_foes() or action.targets.is_empty():
		return false
	return action.targets[0].side != action.actor.side


## Fixed item damage of `element`, scaled by the target's affinity (Holy Water: ×2 on the undead).
func _item_damage(actor: Combatant, target: Combatant, amount: int, element: Elements.Element) -> Array[BattleEvent]:
	var mult: float = DamageCalculator.element_multiplier(target, element)
	var dealt: int = clampi(roundi(amount * mult), 0, DamageCalculator.MAX_DAMAGE)
	return _apply_damage(actor, target, dealt, element, false, mult)


## STATUS, CURE and GUARD skills on one target.
func _support(actor: Combatant, target: Combatant, skill: SkillData) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	match skill.effect:
		SkillData.Effect.STATUS:
			if skill.inflicts != null and rng.randf() < skill.inflict_chance:
				events = StatusEffects.apply(target, skill.inflicts, rng)
		SkillData.Effect.CURE:
			events = StatusEffects.cure(target, skill.cures)
		SkillData.Effect.GUARD:
			actor.is_defending = true
			if target != actor:
				target.guarded_by = actor
			events = [BattleEvent.new(BattleEvent.Type.GUARDING, {&"actor": actor, &"target": target})]
	if events.is_empty():
		events.append(BattleEvent.new(BattleEvent.Type.NO_EFFECT, {&"target": target}))
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

## The combatant a single-target blow from `actor` on `target` really strikes: a taunting
## opponent if there is one (and `target` is not), then that one's living guardian when it has
## one (adds a COVERED event), else the target.
func _cover(actor: Combatant, target: Combatant, events: Array[BattleEvent]) -> Combatant:
	if not target.draws_attacks():
		for c: Combatant in living(opponents_of(actor)):
			if c.draws_attacks():
				target = c
				break
	var guardian: Combatant = target.guarded_by
	if guardian == null or guardian == target or not guardian.is_alive() or guardian.side == actor.side:
		return target
	events.append(BattleEvent.new(BattleEvent.Type.COVERED, {&"target": guardian, &"protected": target}))
	return guardian


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
