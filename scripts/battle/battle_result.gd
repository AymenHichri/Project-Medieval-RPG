class_name BattleResult
extends RefCounted
## What a finished battle hands to SceneManager.end_battle(), the single place rewards are applied.

var outcome: BattleEngine.Outcome = BattleEngine.Outcome.ONGOING
## Total XP of the defeated enemies (0 unless VICTORY).
var xp: int = 0
## XP each surviving party member receives (living members only, divided equally, rounded up).
var xp_per_member: int = 0
var gold: int = 0
var drops: Array[ItemData] = []
## Party members alive at the end (the XP recipients).
var survivors: Array[Combatant] = []
var defeated_enemy_ids: Array[StringName] = []
var rounds: int = 0


func is_victory() -> bool:
	return outcome == BattleEngine.Outcome.VICTORY
