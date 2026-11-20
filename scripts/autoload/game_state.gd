extends Node
## Autoload `GameState`: the data of the current play session.
## Flags, gold, item counts, the party (levels, XP, recruits) and encounter-rate modifiers.
## The full Inventory arrives in Phase 9, quests and serialisation later.

signal flag_changed(flag: StringName, value: Variant)
signal gold_changed(gold: int)
signal items_changed
## A party member gained a level (emitted once per level, from `apply_battle_rewards`).
signal member_leveled(member: PartyMember, level_up: LevelUp)
## A character joined the party (`recruit`).
signal member_joined(member: PartyMember)

## The character a new game starts with (recruits join through `recruit`).
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
## The active party. Its members' fighters are taken into every battle, so HP/MP, levels and
## learned skills carry over. Built by `new_game()` / `ensure_party()`.
var party: Party = Party.new()
## Rolls the stat gains of level-ups. Seed it in tests; randomised on start-up.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


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
		party.add(PartyMember.create(knight))


## Adds `character` to the party at the leader's level and sets `flag` (if given). Returns the
## new member, or null when the party is full or already has this character.
func recruit(character: CharacterData, flag: StringName = &"") -> PartyMember:
	if character == null or party.is_full() or party.has_character(character.id):
		return null
	var level: int = party.leader().level if not party.is_empty() else 1
	var member: PartyMember = PartyMember.create(character, level, rng)
	party.add(member)
	if not flag.is_empty():
		set_flag(flag)
	member_joined.emit(member)
	return member


## Clears what only lasts for one battle (Defend, statuses) once it ends.
func settle_party_after_battle() -> void:
	party.settle_after_battle()


## Full HP/MP for every member, statuses cleared (rest points, debug restart).
func heal_party() -> void:
	party.heal_all()


# --- rewards --------------------------------------------------------------------------------

## Applies a victory's rewards: gold, dropped items, and `xp_per_member` to every member who
## survived (a fallen member gets none). Called only by `SceneManager.end_battle()`.
## Returns the level-ups, in party order (also emitted as `member_leveled`).
func apply_battle_rewards(result: BattleResult) -> Array[LevelUp]:
	var level_ups: Array[LevelUp] = []
	if result == null or not result.is_victory():
		return level_ups
	if result.gold > 0:
		add_gold(result.gold)
	for drop: ItemData in result.drops:
		add_item(drop.id, 1)
	for member: PartyMember in party.members:
		if not member.combatant in result.survivors or not member.is_alive():
			continue
		for up: LevelUp in member.gain_xp(result.xp_per_member, rng):
			level_ups.append(up)
			member_leveled.emit(member, up)
	return level_ups


## The level-up lines a victory will produce, before it is applied (the results screen shows
## them; stat gains are rolled later, in `apply_battle_rewards`).
func preview_level_ups(result: BattleResult) -> PackedStringArray:
	var lines: PackedStringArray = []
	if result == null or not result.is_victory():
		return lines
	for member: PartyMember in party.members:
		if not member.combatant in result.survivors or not member.is_alive():
			continue
		var growth: GrowthCurve = member.data.growth
		var reached: int = Progression.level_for_xp(growth, member.xp + result.xp_per_member)
		for level: int in range(member.level + 1, reached + 1):
			var up: LevelUp = LevelUp.new()
			up.member_name = member.display_name()
			up.level = level
			up.learned = Progression.skills_learned_at(member.data, level)
			lines.append_array(up.describe())
	return lines


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
