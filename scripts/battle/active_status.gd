class_name ActiveStatus
extends RefCounted
## A status effect currently on a Combatant.

var data: StatusEffectData
var turns_left: int = 0
## True until the first round end after the status was applied. A turn-skipping status applied
## after its holder already acted must still cost it a turn next round.
var fresh: bool = true
## A turn-skipping status cost its holder an action this round.
var blocked_this_round: bool = false


func _init(status: StatusEffectData, turns: int) -> void:
	data = status
	turns_left = turns
