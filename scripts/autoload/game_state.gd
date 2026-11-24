extends Node
## Autoload `GameState`: the data of the current play session.
## Flags, the inventory (items, key items, gold), the party (levels, XP, recruits, gear),
## encounter-rate modifiers, the quest log (Phase 10) and the maps visited. Serialisation arrives in
## Phase 11.

signal flag_changed(flag: StringName, value: Variant)
signal gold_changed(gold: int)
## The inventory's items changed (picked up, used, bought, sold, equipped).
signal items_changed
## A party member gained a level (emitted once per level, from `apply_battle_rewards`).
signal member_leveled(member: PartyMember, level_up: LevelUp)
## A character joined the party (`recruit`).
signal member_joined(member: PartyMember)
## A quest started, moved to another stage or was completed.
signal quests_changed(quest: QuestData)
## A map was entered for the first time (`visit_map`).
signal map_visited(map_path: String)

## The character a new game starts with (recruits join through `recruit`).
const STARTING_CHARACTER: String = "res://data/characters/knight.tres"
## Gold, read from and written to the inventory.
var gold: int:
	get:
		return inventory.gold
	set(value):
		inventory.gold = value
var flags: Dictionary[StringName, Variant] = {}
## Items, key items and gold (Phase 9). Assigning a new one (tests) moves the signals to it.
var inventory: Inventory:
	set(value):
		if inventory != null and inventory.changed.is_connected(_on_inventory_changed):
			inventory.changed.disconnect(_on_inventory_changed)
			inventory.gold_changed.disconnect(_on_gold_changed)
		inventory = value if value != null else Inventory.new()
		inventory.changed.connect(_on_inventory_changed)
		inventory.gold_changed.connect(_on_gold_changed)
var current_map: String = ""
var play_time: float = 0.0
## Encounter-rate multipliers by id (PROJECT_PLAN.md §6.2), ticked once per step.
var encounter_rate_modifiers: Dictionary[StringName, RateModifier] = {}
## The active party. Its members' fighters are taken into every battle, so HP/MP, levels and
## learned skills carry over. Built by `new_game()` / `ensure_party()`.
var party: Party = Party.new()
## Started and completed quests (Phase 10). Moved on by `set_flag`. Assigning a new one (tests)
## moves the `quests_changed` relay to it.
var quests: QuestLog:
	set(value):
		if quests != null and quests.quest_started.is_connected(_on_quest_event):
			quests.quest_started.disconnect(_on_quest_event)
			quests.stage_advanced.disconnect(_on_stage_advanced)
			quests.quest_completed.disconnect(_on_quest_event)
		quests = value if value != null else QuestLog.new()
		quests.quest_started.connect(_on_quest_event)
		quests.stage_advanced.connect(_on_stage_advanced)
		quests.quest_completed.connect(_on_quest_event)
## Scene paths of the maps entered so far, in order (the map page lists them).
var visited_maps: Array[String] = []
## Rolls the stat gains of level-ups. Seed it in tests; randomised on start-up.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	inventory = Inventory.new()
	quests = QuestLog.new()


func _ready() -> void:
	rng.randomize()


func new_game() -> void:
	flags.clear()
	inventory.clear()
	encounter_rate_modifiers.clear()
	current_map = ""
	play_time = 0.0
	quests.clear()
	visited_maps.clear()
	party.clear()
	ensure_party()


## Sets a flag and moves the quests on (a flag can finish a quest stage) before `flag_changed`,
## so listeners see the quests as they now stand.
func set_flag(flag: StringName, value: Variant = true) -> void:
	flags[flag] = value
	quests.update(flags)
	flag_changed.emit(flag, value)


# --- quests and maps ------------------------------------------------------------------------

## Starts the quest `data/quests/<quest_id>.tres` (dialogue `start_quest`). False when it is
## unknown or already started.
func start_quest(quest_id: StringName) -> bool:
	return quests.start(QuestData.find(quest_id), flags)


func _on_quest_event(quest: QuestData) -> void:
	quests_changed.emit(quest)


func _on_stage_advanced(quest: QuestData, _stage: int) -> void:
	quests_changed.emit(quest)


## Records that the player entered `map_path` (Map._ready). True the first time.
func visit_map(map_path: String) -> bool:
	if map_path.is_empty() or map_path in visited_maps:
		return false
	visited_maps.append(map_path)
	map_visited.emit(map_path)
	return true


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(flag, default)


## Adds (or, negative, takes) gold. Never below 0.
func add_gold(amount: int) -> void:
	inventory.add_gold(amount)


# --- items ----------------------------------------------------------------------------------

func item_count(id: StringName) -> int:
	return inventory.count(id)


## Adds items (dialogue `give_item`, chests, drops); a negative amount removes them (never below
## 0). Returns how many were added (see Inventory.add).
func add_item(id: StringName, amount: int = 1) -> int:
	if amount < 0:
		inventory.remove(id, mini(-amount, inventory.count(id)))
		return 0
	return inventory.add(id, amount)


## The ItemData of an item id (`data/items/` or `data/equipment/`), or null.
static func item_data(id: StringName) -> ItemData:
	return Inventory.item_data(id)


## Uses an item outside battle on `target` (ignored for items that act on the whole party or
## need no target). Spends one when it did something; false otherwise.
func use_item(item: ItemData, target: PartyMember = null) -> bool:
	if item == null or not inventory.has(item.id):
		return false
	var targets: Array[Combatant] = []
	if item.target_mode == Targeting.Mode.ALL_ALLIES:
		targets = party.combatants()
	elif target != null:
		targets = [target.combatant]
	if not FieldItems.apply(item, targets, encounter_rate_modifiers):
		return false
	inventory.remove(item.id)
	return true


func _on_inventory_changed() -> void:
	items_changed.emit()


func _on_gold_changed(value: int) -> void:
	gold_changed.emit(value)


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


## Product of all rate modifiers and of the gear the party wears (`encounter_rate_mult`).
func get_encounter_multiplier() -> float:
	var mult: float = RateModifier.product(encounter_rate_modifiers)
	for member: PartyMember in party.members:
		for slot: EquipmentData.Category in member.combatant.equipment:
			mult *= member.combatant.equipment[slot].encounter_rate_mult
	return mult


## One step walked: counts down the timed modifiers and drops the expired ones.
func tick_encounter_modifiers() -> void:
	RateModifier.tick(encounter_rate_modifiers)
