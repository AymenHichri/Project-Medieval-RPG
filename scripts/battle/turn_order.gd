class_name TurnOrder
extends RefCounted
## Orders a round's actions: Flee, then Defend and priority skills (Guard), then everything else
## by agility × random spread.
## Ties keep submission order (party actions are submitted before enemy actions).

## Random spread on agility each round.
const SPEED_VARIANCE_MIN: float = 0.85
const SPEED_VARIANCE_MAX: float = 1.15


## Returns a new, sorted array. With `use_variance = false` the order is pure agility.
static func sort(actions: Array[BattleAction], rng: RandomNumberGenerator,
		use_variance: bool = true) -> Array[BattleAction]:
	var keyed: Array[Dictionary] = []
	for i: int in actions.size():
		var action: BattleAction = actions[i]
		var spread: float = rng.randf_range(SPEED_VARIANCE_MIN, SPEED_VARIANCE_MAX) if use_variance else 1.0
		keyed.append({
			&"action": action,
			&"priority": priority(action),
			&"speed": action.actor.effective_stat(&"agility") * spread,
			&"index": i,
		})
	keyed.sort_custom(_goes_before)
	var sorted: Array[BattleAction] = []
	for entry: Dictionary in keyed:
		sorted.append(entry[&"action"] as BattleAction)
	return sorted


## Higher goes first regardless of agility.
static func priority(action: BattleAction) -> int:
	match action.kind:
		BattleAction.Kind.FLEE:
			return 2
		BattleAction.Kind.DEFEND:
			return 1
		BattleAction.Kind.SKILL:
			return action.skill.priority if action.skill != null else 0
	return 0


static func _goes_before(a: Dictionary, b: Dictionary) -> bool:
	if a[&"priority"] != b[&"priority"]:
		return (a[&"priority"] as int) > (b[&"priority"] as int)
	if a[&"speed"] != b[&"speed"]:
		return (a[&"speed"] as float) > (b[&"speed"] as float)
	return (a[&"index"] as int) < (b[&"index"] as int)
