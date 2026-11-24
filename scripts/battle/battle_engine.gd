class_name BattleEngine
extends RefCounted
## The round-based battle rules (PROJECT_PLAN.md §4.6). Takes actions in, returns BattleEvents out.
## Never awaits and never touches nodes; deterministic for a given seeded RNG.
##
##   engine.setup(battle_setup, party, rng)
##   loop: engine.begin_round(party_actions)
##         while engine.has_next_action(): present(engine.execute_next()); stop if outcome() != ONGOING
##         present(engine.end_round())
##   engine.compute_rewards()

enum Outcome { ONGOING, VICTORY, DEFEAT, FLED }

## Letters appended to duplicate enemy names ("Wolf A", "Wolf B").
const NAME_SUFFIXES: String = "ABCDEFGH"

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
## Current round, 1-based once the first round begins.
var round_number: int = 0
var rng: RandomNumberGenerator
var battle_setup: BattleSetup

var _resolver: ActionResolver
var _queue: Array[BattleAction] = []
var _fled: bool = false
var _ended_emitted: bool = false


## `consume_item`: see ActionResolver.consume_item.
func setup(new_setup: BattleSetup, party_members: Array[Combatant], random: RandomNumberGenerator,
		consume_item: Callable = Callable()) -> void:
	battle_setup = new_setup
	rng = random
	party = party_members.duplicate()
	enemies.clear()
	for data: EnemyData in new_setup.enemies:
		enemies.append(Combatant.from_enemy(data))
	_name_duplicates()
	round_number = 0
	_queue.clear()
	_fled = false
	_ended_emitted = false
	_resolver = ActionResolver.new(party, enemies, rng)
	_resolver.can_flee = new_setup.can_flee and not new_setup.is_boss
	_resolver.consume_item = consume_item


## Starts a round: drops actions of party members who cannot act, keeps only the Flee if the
## party is running (a failed Flee costs the party its round), adds each able enemy's choice, and orders everything.
func begin_round(party_actions: Array[BattleAction]) -> void:
	round_number += 1
	var actions: Array[BattleAction] = []
	for action: BattleAction in party_actions:
		if action.actor.side == Combatant.Team.PARTY and action.actor.can_act():
			if action.kind == BattleAction.Kind.FLEE:
				actions = [action]
				break
			actions.append(action)
	for enemy: Combatant in enemies:
		if enemy.can_act():
			for i: int in enemy.enemy_data.actions_per_round:
				actions.append(EnemyAI.choose(enemy, self))
	_queue = TurnOrder.sort(actions, rng)


func has_next_action() -> bool:
	return not _queue.is_empty() and outcome() == Outcome.ONGOING


## Resolves the next queued action. Dead or disabled actors produce no or a skip event.
func execute_next() -> Array[BattleEvent]:
	if not has_next_action():
		return []
	var events: Array[BattleEvent] = _resolver.resolve(_queue.pop_front() as BattleAction)
	for event: BattleEvent in events:
		if event.type == BattleEvent.Type.FLEE_ATTEMPTED and event.get_value(&"success") as bool:
			_fled = true
			_queue.clear()
	events.append_array(_check_phase_changes())
	events.append_array(_check_end())
	return events


## Status ticks, Defend and Guard reset and the round-end marker.
func end_round() -> Array[BattleEvent]:
	_queue.clear()
	var events: Array[BattleEvent] = []
	if outcome() == Outcome.ONGOING:
		events.append_array(StatusEffects.tick_round_end(everyone()))
		events.append_array(_check_phase_changes())
	for c: Combatant in everyone():
		c.is_defending = false
		c.guarded_by = null
	events.append(BattleEvent.new(BattleEvent.Type.ROUND_ENDED, {&"round": round_number}))
	events.append_array(_check_end())
	return events


func outcome() -> Outcome:
	if _fled:
		return Outcome.FLED
	if ActionResolver.living(enemies).is_empty():
		return Outcome.VICTORY
	if ActionResolver.living(party).is_empty():
		return Outcome.DEFEAT
	return Outcome.ONGOING


## Rewards for the current outcome. Only a VICTORY yields XP, gold and drops.
func compute_rewards() -> BattleResult:
	var result: BattleResult = BattleResult.new()
	result.outcome = outcome()
	result.rounds = round_number
	result.survivors = ActionResolver.living(party)
	if result.outcome != Outcome.VICTORY:
		return result
	for enemy: Combatant in enemies:
		var data: EnemyData = enemy.enemy_data
		result.xp += data.xp
		result.gold += data.gold
		result.defeated_enemy_ids.append(data.id)
		for drop: DropEntry in data.drops:
			if drop.item != null and rng.randf() < drop.chance:
				result.drops.append(drop.item)
	if not result.survivors.is_empty():
		result.xp_per_member = ceili(float(result.xp) / result.survivors.size())
	return result


## Flee chance for the current sides (0 when fleeing is not allowed).
func flee_chance() -> float:
	return _resolver.flee_chance() if _resolver.can_flee else 0.0


func _check_phase_changes() -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	for enemy: Combatant in enemies:
		if enemy.should_change_phase():
			enemy.change_phase()
			events.append(BattleEvent.new(BattleEvent.Type.PHASE_CHANGE, {&"target": enemy, &"new_data": enemy.enemy_data}))
	return events


func _check_end() -> Array[BattleEvent]:
	var current: Outcome = outcome()
	if current == Outcome.ONGOING or _ended_emitted:
		return []
	_ended_emitted = true
	_queue.clear()
	return [BattleEvent.new(BattleEvent.Type.BATTLE_ENDED, {&"outcome": current})]


## Party then enemies.
func everyone() -> Array[Combatant]:
	var all: Array[Combatant] = party.duplicate()
	all.append_array(enemies)
	return all


func _name_duplicates() -> void:
	var counts: Dictionary[String, int] = {}
	for enemy: Combatant in enemies:
		counts[enemy.display_name] = counts.get(enemy.display_name, 0) + 1
	var seen: Dictionary[String, int] = {}
	for enemy: Combatant in enemies:
		var base: String = enemy.display_name
		if counts[base] > 1:
			var i: int = seen.get(base, 0)
			seen[base] = i + 1
			enemy.display_name = "%s %s" % [base, NAME_SUFFIXES[i % NAME_SUFFIXES.length()]]
