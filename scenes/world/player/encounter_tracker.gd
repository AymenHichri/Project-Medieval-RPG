class_name EncounterTracker
extends Node
## Counts the player's steps and rolls for random encounters (PROJECT_PLAN.md §6.2).
## A step is every STEP_DISTANCE px actually travelled (from `get_real_velocity()`, so pushing
## against a wall doesn't count). Each step ticks the GameState rate modifiers and, inside an
## EncounterZone, asks EncounterRoller whether a battle starts. Zones form a stack: the last
## entered one is used, and leaving it restores the one around it.
## Child of the PlayerController. The Map listens to `encounter_triggered` and starts the battle.

signal encounter_triggered(group: EncounterGroup, table: EncounterTable)
signal step_taken(steps_since_last: int)

## Distance (px) of one step: half a tile.
const STEP_DISTANCE: float = 64.0

## Debug toggle (F4 on the debug overlay): false stops every random encounter.
static var encounters_enabled: bool = true

## Steps since the last reset (map entry, battle, closed dialogue); the grace period uses it.
var steps_since_last: int = 0
## Every step counted on this map (debug overlay).
var total_steps: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _distance: float = 0.0
var _zones: Array[EncounterZone] = []

@onready var _player: PlayerController = get_parent() as PlayerController


func _ready() -> void:
	rng.randomize()
	if not DialogueManager.dialogue_finished.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_finished.connect(_on_dialogue_finished)


func _physics_process(delta: float) -> void:
	if _player != null and _player.can_act():
		add_distance(_player.get_real_velocity().length() * delta)


## Adds travelled distance; every full STEP_DISTANCE is one step. Returns the steps taken.
## Stops early if a step triggers an encounter (the rest of the distance is dropped).
func add_distance(distance: float) -> int:
	_distance += maxf(0.0, distance)
	var steps: int = 0
	while _distance >= STEP_DISTANCE:
		_distance -= STEP_DISTANCE
		steps += 1
		if _take_step():
			_distance = 0.0
			break
	return steps


## Restarts the grace period (no encounter for the table's `grace_steps` steps).
func reset_grace() -> void:
	steps_since_last = 0
	_distance = 0.0


## The zone in use (last entered), or null outside every zone.
func current_zone() -> EncounterZone:
	_prune()
	return _zones[_zones.size() - 1] if not _zones.is_empty() else null


func current_table() -> EncounterTable:
	var zone: EncounterZone = current_zone()
	return zone.table if zone != null else null


## Called by an EncounterZone when the player enters it. Re-entering a zone already on the
## stack changes nothing (zones re-report the player when the world is re-attached after a battle).
func enter_zone(zone: EncounterZone) -> void:
	if zone in _zones:
		return
	_zones.append(zone)


## Called by an EncounterZone when the player leaves it. Ignored while the player's feet are
## still inside the outline: zones also report an exit when the world is detached for a battle.
func exit_zone(zone: EncounterZone) -> void:
	if _player != null and is_instance_valid(zone) and zone.is_inside_tree() \
			and zone.contains_point(_player.global_position):
		return
	_zones.erase(zone)


## Starts an encounter from the current zone at once (F5 on the debug overlay). False when the
## player is in no zone or the table has no eligible group.
func force_encounter() -> bool:
	return _trigger(current_table())


## One step: rolls for an encounter, then ticks the rate modifiers, so a modifier lasting N steps
## covers exactly N rolls (the Warding Torch's 200).
func _take_step() -> bool:
	steps_since_last += 1
	total_steps += 1
	step_taken.emit(steps_since_last)
	var triggered: bool = _roll_step()
	GameState.tick_encounter_modifiers()
	return triggered


func _roll_step() -> bool:
	var table: EncounterTable = current_table()
	if table == null or not encounters_enabled:
		return false
	if not EncounterRoller.should_trigger(steps_since_last, table, GameState.get_encounter_multiplier(), rng):
		return false
	return _trigger(table)


func _trigger(table: EncounterTable) -> bool:
	if table == null:
		return false
	var group: EncounterGroup = EncounterRoller.pick_group(table, GameState.flags, rng)
	if group == null:
		return false
	reset_grace()
	encounter_triggered.emit(group, table)
	return true


func _prune() -> void:
	for i: int in range(_zones.size() - 1, -1, -1):
		if not is_instance_valid(_zones[i]):
			_zones.remove_at(i)


func _on_dialogue_finished(_id: StringName) -> void:
	reset_grace()
