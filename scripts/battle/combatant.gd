class_name Combatant
extends RefCounted
## A fighter in a battle: wraps read-only EnemyData / CharacterData and holds the live state
## (HP, MP, statuses, defending). Only battle logic mutates it.

enum Team { PARTY, ENEMY }

var display_name: String = ""
var side: Team = Team.ENEMY
## Base stats (a Resource, never mutated). For party members, the stats of their current level.
var stats: StatBlock
var hp: int = 0
var mp: int = 0
var statuses: Array[ActiveStatus] = []
var is_defending: bool = false
## The ally covering this combatant this round (Guard): single-target blows aimed here hit it instead.
var guarded_by: Combatant
var affinities: Dictionary[Elements.Element, float] = {}
var skills: Array[SkillData] = []
var status_immunities: Array[StatusEffectData] = []
## Set for enemies (the current form after a phase change).
var enemy_data: EnemyData
## Set for party members.
var character_data: CharacterData
## An enemy with a second form has switched to it.
var phase_changed: bool = false


## A combatant for an enemy, at full HP/MP.
static func from_enemy(data: EnemyData) -> Combatant:
	var c: Combatant = Combatant.new()
	c.side = Team.ENEMY
	c._use_enemy_data(data)
	c.hp = c.stats.max_hp
	c.mp = c.stats.max_mp
	return c


## A combatant for a party member. `level_stats` defaults to the character's base stats;
## `current_hp`/`current_mp` < 0 mean full.
static func from_character(data: CharacterData, level_stats: StatBlock = null,
		known_skills: Array[SkillData] = [], current_hp: int = -1, current_mp: int = -1) -> Combatant:
	var c: Combatant = Combatant.new()
	c.side = Team.PARTY
	c.character_data = data
	c.display_name = data.display_name
	c.stats = level_stats if level_stats != null else data.base_stats
	c.skills = known_skills.duplicate() if not known_skills.is_empty() else data.starting_skills.duplicate()
	c.hp = c.stats.max_hp if current_hp < 0 else mini(current_hp, c.stats.max_hp)
	c.mp = c.stats.max_mp if current_mp < 0 else mini(current_mp, c.stats.max_mp)
	return c


func _use_enemy_data(data: EnemyData) -> void:
	enemy_data = data
	display_name = data.display_name
	stats = data.stats
	affinities = data.affinities.duplicate()
	skills = data.skills.duplicate()
	status_immunities = data.status_immunities.duplicate()


func is_alive() -> bool:
	return hp > 0


## Alive and not held by a turn-skipping status.
func can_act() -> bool:
	return is_alive() and StatusEffects.blocking_status(self) == null


func max_hp() -> int:
	return stats.max_hp


func max_mp() -> int:
	return stats.max_mp


func hp_ratio() -> float:
	return float(hp) / float(maxi(1, stats.max_hp))


## A stat after status multipliers (max_hp/max_mp are never modified).
func effective_stat(stat: StringName) -> int:
	var base: int = stats.get_stat(stat)
	if stat == &"max_hp" or stat == &"max_mp":
		return base
	return maxi(0, roundi(base * StatusEffects.stat_multiplier(self, stat)))


## Damage multiplier this combatant takes from `element`.
func affinity(element: Elements.Element) -> float:
	return Elements.affinity(affinities, element)


func has_status(id: StringName) -> bool:
	return get_status(id) != null


func get_status(id: StringName) -> ActiveStatus:
	for status: ActiveStatus in statuses:
		if status.data.id == id:
			return status
	return null


## Lowers HP by `amount` (≥ 0). Returns the HP actually lost.
func take_damage(amount: int) -> int:
	var lost: int = mini(hp, maxi(0, amount))
	hp -= lost
	if hp == 0:
		statuses.clear()
		is_defending = false
		guarded_by = null
	return lost


## Raises HP by `amount` up to max HP (living combatants only). Returns the HP actually gained.
func restore_hp(amount: int) -> int:
	if not is_alive():
		return 0
	var gained: int = mini(stats.max_hp - hp, maxi(0, amount))
	hp += gained
	return gained


## Raises MP up to max MP. Returns the MP actually gained.
func restore_mp(amount: int) -> int:
	var gained: int = mini(stats.max_mp - mp, maxi(0, amount))
	mp += gained
	return gained


## Brings a defeated combatant back with `amount` HP (at least 1). Returns the HP set.
func revive(amount: int) -> int:
	if is_alive():
		return 0
	hp = clampi(amount, 1, stats.max_hp)
	return hp


## Has a status that draws the opponents' single-target actions (Taunt).
func draws_attacks() -> bool:
	for status: ActiveStatus in statuses:
		if status.data.draws_attacks:
			return true
	return false


## True when this enemy should switch to its second form now (checked by BattleEngine).
func should_change_phase() -> bool:
	return (enemy_data != null and not phase_changed and enemy_data.phase_two != null
			and is_alive() and hp_ratio() <= enemy_data.phase_two_at_hp_pct)


## Switches to the second form, keeping the current HP ratio and statuses.
func change_phase() -> void:
	var ratio: float = hp_ratio()
	_use_enemy_data(enemy_data.phase_two)
	phase_changed = true
	hp = clampi(roundi(stats.max_hp * ratio), 1, stats.max_hp)
	mp = mini(mp, stats.max_mp)
