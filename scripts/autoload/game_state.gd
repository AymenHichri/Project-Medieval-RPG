extends Node
## Autoload `GameState`: the data of the current play session.
## Phase 6: flags, gold, item counts, the battle party and encounter-rate modifiers.
## The real Party/PartyMember (levels, XP) arrives in Phase 7, the full Inventory in Phase 9,
## quests and serialisation later.

signal flag_changed(flag: StringName, value: Variant)
signal gold_changed(gold: int)
signal items_changed

## The character a new game starts with (until Party/PartyMember exist, Phase 7).
const STARTING_CHARACTER: String = "res://data/characters/knight.tres"
## Item ids are the file names in this folder.
const ITEM_DIR: String = "res://data/items"

var gold: int = 0
var flags: Dictionary[StringName, Variant] = {}
## Item id → count (only ids with a count > 0). The full Inventory replaces this in Phase 9.
var items: Dictionary[StringName, int] = {}
var current_map: String = ""
var play_time: float = 0.0
## Encounter-rate multipliers by id (PROJECT_PLAN.md §6.2), ticked once per step.
var encounter_rate_modifiers: Dictionary[StringName, RateModifier] = {}
## The fighters taken into every battle. Minimal stand-in for Party (Phase 7): their HP/MP
## carry over from one battle to the next. Built on first use.
var party: Array[Combatant] = []


func new_game() -> void:
	gold = 0
	flags.clear()
	items.clear()
	encounter_rate_modifiers.clear()
	current_map = ""
	play_time = 0.0
	party.clear()
	ensure_party()


func set_flag(flag: StringName, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(flag, default)


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	gold_changed.emit(gold)


# --- items ----------------------------------------------------------------------------------

func item_count(id: StringName) -> int:
	return items.get(id, 0) as int


## Adds (or, with a negative amount, removes) items. Counts never go below 0.
func add_item(id: StringName, amount: int = 1) -> void:
	set_item_count(id, item_count(id) + amount)


func set_item_count(id: StringName, count: int) -> void:
	if count > 0:
		items[id] = count
	else:
		items.erase(id)
	items_changed.emit()


## The ItemData of an item id (`data/items/<id>.tres`), or null.
static func item_data(id: StringName) -> ItemData:
	var path: String = ITEM_DIR.path_join(String(id) + ".tres")
	if not ResourceLoader.exists(path):
		push_warning("GameState: unknown item '%s'" % id)
		return null
	return load(path) as ItemData


## The items the party carries into a battle, as the BattleController expects them.
func battle_items() -> Dictionary[ItemData, int]:
	var out: Dictionary[ItemData, int] = {}
	for id: StringName in items:
		var data: ItemData = item_data(id)
		if data != null and data.usable_in_battle:
			out[data] = items[id]
	return out


## Writes back the counts left after a battle (items used in it are gone).
func sync_battle_items(remaining: Dictionary[ItemData, int]) -> void:
	for data: ItemData in remaining:
		set_item_count(data.id, remaining[data])


# --- party ----------------------------------------------------------------------------------

## Builds the starting party when there is none yet (e.g. a map started with F6).
func ensure_party() -> void:
	if not party.is_empty():
		return
	var knight: CharacterData = load(STARTING_CHARACTER) as CharacterData
	if knight != null:
		party.append(Combatant.from_character(knight))


## Clears what only lasts for one battle (Defend, statuses) once it ends.
func settle_party_after_battle() -> void:
	for member: Combatant in party:
		member.is_defending = false
		member.statuses.clear()


## Full HP/MP for every member (a debug restart; Phase 7 adds rest points).
func heal_party() -> void:
	for member: Combatant in party:
		member.hp = member.max_hp()
		member.mp = member.max_mp()
		member.statuses.clear()


# --- rewards --------------------------------------------------------------------------------

## Applies a victory's rewards: gold and dropped items. Called only by
## `SceneManager.end_battle()`. XP and levels arrive in Phase 7.
func apply_battle_rewards(result: BattleResult) -> void:
	if result == null or not result.is_victory():
		return
	if result.gold > 0:
		add_gold(result.gold)
	for drop: ItemData in result.drops:
		add_item(drop.id, 1)


# --- encounter rate -------------------------------------------------------------------------

## Adds or replaces a rate modifier. `steps` = -1 for a permanent one.
func add_encounter_modifier(id: StringName, mult: float, steps: int = -1) -> void:
	encounter_rate_modifiers[id] = RateModifier.new(mult, steps)


func remove_encounter_modifier(id: StringName) -> void:
	encounter_rate_modifiers.erase(id)


## Product of all rate modifiers (equipment multipliers join it in Phase 9).
func get_encounter_multiplier() -> float:
	return RateModifier.product(encounter_rate_modifiers)


## One step walked: counts down the timed modifiers and drops the expired ones.
func tick_encounter_modifiers() -> void:
	RateModifier.tick(encounter_rate_modifiers)
