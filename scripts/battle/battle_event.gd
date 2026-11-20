class_name BattleEvent
extends RefCounted
## One thing that happened in battle, produced by the logic and played by the presenter.
## `payload` keys per type are listed on the Type values.

enum Type {
	ACTION_STARTED,  ## actor, action
	ACTION_SKIPPED,  ## actor, status (StatusEffectData)
	ACTION_FAILED,   ## actor, reason (&"not_enough_mp", &"no_item", &"cannot_flee", &"no_target")
	DEFENDING,       ## actor
	GUARDING,        ## actor, target (the ally it covers; the actor also defends)
	COVERED,         ## target (the guardian who takes the blow), protected (the ally aimed at)
	DAMAGE,          ## target, amount, element, critical, weak, resisted, immune, source (actor or status)
	HEAL,            ## target, amount, source
	MP_CHANGED,      ## target, amount (negative = spent), mp
	REVIVED,         ## target, amount
	NO_EFFECT,       ## target (a support skill changed nothing, e.g. Purify on a healthy ally)
	STATUS_APPLIED,  ## target, status, turns, refreshed
	STATUS_RESISTED, ## target, status
	STATUS_REMOVED,  ## target, status, reason (&"expired", &"hit", &"cured")
	DEFEATED,        ## target
	PHASE_CHANGE,    ## target, new_data (EnemyData)
	FLEE_ATTEMPTED,  ## actor, success, chance
	MESSAGE,         ## text
	ROUND_ENDED,     ## round
	BATTLE_ENDED,    ## outcome
}

var type: Type
var payload: Dictionary[StringName, Variant] = {}


func _init(event_type: Type, data: Dictionary = {}) -> void:
	type = event_type
	payload.assign(data)


## Payload value for `key` (null when absent).
func get_value(key: StringName) -> Variant:
	return payload.get(key)


## The `target` (or `actor`) combatant of this event, if any.
func subject() -> Combatant:
	if payload.has(&"target"):
		return payload[&"target"] as Combatant
	return payload.get(&"actor") as Combatant


func _to_string() -> String:
	return "%s%s" % [Type.keys()[type], payload]
