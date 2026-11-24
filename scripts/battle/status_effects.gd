class_name StatusEffects
extends RefCounted
## Applying, querying and ticking status effects. Pure static functions.
## Durations count down at round end. A turn-skipping status (Sleep, Stun) applied after its
## holder acted is not counted down that round, so it always costs at least one turn.


## Applies `data` to `target`. A status already present is refreshed, never stacked.
static func apply(target: Combatant, data: StatusEffectData, rng: RandomNumberGenerator) -> Array[BattleEvent]:
	if not target.is_alive():
		return []
	if is_immune(target, data):
		return [BattleEvent.new(BattleEvent.Type.STATUS_RESISTED, {&"target": target, &"status": data})]
	var turns: int = roll_duration(data, rng)
	var existing: ActiveStatus = target.get_status(data.id)
	if existing != null:
		existing.turns_left = maxi(existing.turns_left, turns)
		existing.fresh = true
		existing.blocked_this_round = false
	else:
		target.statuses.append(ActiveStatus.new(data, turns))
	return [BattleEvent.new(BattleEvent.Type.STATUS_APPLIED, {
		&"target": target, &"status": data, &"turns": turns, &"refreshed": existing != null})]


static func roll_duration(data: StatusEffectData, rng: RandomNumberGenerator) -> int:
	if data.duration_turns_max > data.duration_turns:
		return rng.randi_range(data.duration_turns, data.duration_turns_max)
	return data.duration_turns


## Listed immunity, or immunity to the status's (non-physical) element.
static func is_immune(target: Combatant, data: StatusEffectData) -> bool:
	for immunity: StatusEffectData in target.status_immunities:
		if immunity.id == data.id:
			return true
	return data.element != Elements.Element.PHYSICAL and Elements.is_immune(target.affinity(data.element))


## Product of the active statuses' multipliers for `stat`.
static func stat_multiplier(target: Combatant, stat: StringName) -> float:
	var mult: float = 1.0
	for status: ActiveStatus in target.statuses:
		mult *= status.data.stat_mult.get(stat, 1.0) as float
	return mult


## True if any active status changes `stat`.
static func modifies_stat(target: Combatant, stat: StringName) -> bool:
	return not is_equal_approx(stat_multiplier(target, stat), 1.0)


static func healing_received_multiplier(target: Combatant) -> float:
	var mult: float = 1.0
	for status: ActiveStatus in target.statuses:
		mult *= status.data.healing_received_mult
	return mult


## The status that stops `target` acting, or null. One that `starts_next_round` waits for the
## round after it was applied.
static func blocking_status(target: Combatant) -> ActiveStatus:
	for status: ActiveStatus in target.statuses:
		if status.data.skip_turn and not (status.data.starts_next_round and status.fresh):
			return status
	return null


static func blocks_action(target: Combatant) -> bool:
	return blocking_status(target) != null


## Removes statuses that wear off when the holder is hit (call after damage > 0).
static func on_hit(target: Combatant) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	for status: ActiveStatus in target.statuses.duplicate():
		if status.data.wears_off_on_hit:
			target.statuses.erase(status)
			events.append(_removed(target, status.data, &"hit"))
	return events


## Removes `which` (empty = every status). Returns the events.
static func cure(target: Combatant, which: Array[StatusEffectData]) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	for status: ActiveStatus in target.statuses.duplicate():
		var listed: bool = which.is_empty()
		for wanted: StatusEffectData in which:
			listed = listed or wanted.id == status.data.id
		if listed:
			target.statuses.erase(status)
			events.append(_removed(target, status.data, &"cured"))
	return events


## End of round: damage over time, regeneration, then durations. Returns the events in order.
static func tick_round_end(combatants: Array[Combatant]) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	for c: Combatant in combatants:
		for status: ActiveStatus in c.statuses.duplicate():
			if not c.is_alive():
				break
			events.append_array(_apply_tick(c, status))
		if not c.is_alive():
			continue
		for status: ActiveStatus in c.statuses.duplicate():
			var counts: bool = not (status.data.skip_turn and status.fresh and not status.blocked_this_round)
			status.fresh = false
			status.blocked_this_round = false
			if counts:
				status.turns_left -= 1
			if status.turns_left <= 0:
				c.statuses.erase(status)
				events.append(_removed(c, status.data, &"expired"))
	return events


static func _apply_tick(c: Combatant, status: ActiveStatus) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	var data: StatusEffectData = status.data
	if data.dot_percent > 0.0:
		var lost: int = c.take_damage(maxi(1, roundi(c.max_hp() * data.dot_percent)))
		events.append(BattleEvent.new(BattleEvent.Type.DAMAGE, {
			&"target": c, &"amount": lost, &"element": data.element, &"critical": false,
			&"weak": false, &"resisted": false, &"immune": false, &"source": data}))
		if not c.is_alive():
			events.append(BattleEvent.new(BattleEvent.Type.DEFEATED, {&"target": c}))
	if data.regen_percent > 0.0 and c.is_alive():
		var amount: int = roundi(c.max_hp() * data.regen_percent * healing_received_multiplier(c))
		var gained: int = c.restore_hp(maxi(1, amount))
		events.append(BattleEvent.new(BattleEvent.Type.HEAL, {&"target": c, &"amount": gained, &"source": data}))
	return events


static func _removed(target: Combatant, data: StatusEffectData, reason: StringName) -> BattleEvent:
	return BattleEvent.new(BattleEvent.Type.STATUS_REMOVED, {&"target": target, &"status": data, &"reason": reason})
