class_name BattleAction
extends RefCounted
## One combatant's command for a round, as chosen by the CommandMenu or EnemyAI.

enum Kind { ATTACK, SKILL, ITEM, DEFEND, FLEE }

var actor: Combatant
var kind: Kind = Kind.ATTACK
var skill: SkillData
var item: ItemData
## Chosen targets. Single-target actions are retargeted if theirs is gone (ActionResolver).
var targets: Array[Combatant] = []


static func attack(by: Combatant, target: Combatant) -> BattleAction:
	return _make(by, Kind.ATTACK, [target])


static func use_skill(by: Combatant, used: SkillData, on: Array[Combatant]) -> BattleAction:
	var action: BattleAction = _make(by, Kind.SKILL, on)
	action.skill = used
	return action


static func use_item(by: Combatant, used: ItemData, on: Array[Combatant]) -> BattleAction:
	var action: BattleAction = _make(by, Kind.ITEM, on)
	action.item = used
	return action


static func defend(by: Combatant) -> BattleAction:
	return _make(by, Kind.DEFEND, [])


## The whole party tries to run. On failure the party loses its round.
static func flee(by: Combatant) -> BattleAction:
	return _make(by, Kind.FLEE, [])


static func _make(by: Combatant, action_kind: Kind, on: Array[Combatant]) -> BattleAction:
	var action: BattleAction = BattleAction.new()
	action.actor = by
	action.kind = action_kind
	action.targets = on.duplicate()
	return action
