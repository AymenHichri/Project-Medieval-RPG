class_name PartyMember
extends RefCounted
## A playable character's live progress (PROJECT_PLAN.md §6.4): level, total XP and the stats of
## that level. Its `combatant` is the same object across battles, so HP/MP, learned skills and
## level stats carry from one battle to the next. `data` (a .tres) is never mutated.
## Phase 9: gear is worn in the combatant's `equipment` slots; the effective stats (level stats +
## gear) are computed on demand by the combatant, never stored. `equip_from`/`unequip_to` move
## gear between the slots and an Inventory.

var data: CharacterData
var level: int = 1
## Total XP earned since level 1.
var xp: int = 0
## Stats at the current level: the character's base stats plus every level's gains. A private
## copy (never the .tres), shared with `combatant.stats`.
var stats: StatBlock
## The fighter taken into battles.
var combatant: Combatant


## A new member at level 1, or at `start_level` (a recruit catching up with the party): every level
## between is gained in turn (rolled stat gains, skills learned), then HP and MP are full.
static func create(character: CharacterData, start_level: int = 1, rng: RandomNumberGenerator = null) -> PartyMember:
	var member: PartyMember = PartyMember.new()
	member.data = character
	member.stats = character.base_stats.duplicate() as StatBlock
	member.combatant = Combatant.from_character(character, member.stats)
	if start_level > 1 and character.growth != null:
		var roll: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()
		member.xp = Progression.total_xp_for_level(character.growth, start_level)
		while member.level < mini(start_level, character.growth.max_level):
			member._level_up(roll)
		member.heal_full()
	return member


func display_name() -> String:
	return data.display_name


func is_alive() -> bool:
	return combatant.is_alive()


func skills() -> Array[SkillData]:
	return combatant.skills


## XP still needed for the next level (0 at the level cap).
func xp_to_next_level() -> int:
	if level >= data.growth.max_level:
		return 0
	return Progression.total_xp_for_level(data.growth, level + 1) - xp


## Adds XP and applies every level reached (a big reward can give several). Each level adds
## rolled stat gains (HP/MP rise by the same amount as their maximum) and teaches the skills
## unlocked at that level. Returns one LevelUp per level gained, in order.
func gain_xp(amount: int, rng: RandomNumberGenerator) -> Array[LevelUp]:
	var out: Array[LevelUp] = []
	if amount <= 0 or data.growth == null:
		return out
	xp += amount
	var target: int = Progression.level_for_xp(data.growth, xp)
	while level < target:
		out.append(_level_up(rng))
	return out


func _level_up(rng: RandomNumberGenerator) -> LevelUp:
	level += 1
	var up: LevelUp = LevelUp.new()
	up.member_name = display_name()
	up.level = level
	up.gains = Progression.roll_gains(data.growth, rng)
	for stat: StringName in StatBlock.NAMES:
		stats.set(stat, stats.get_stat(stat) + up.gains.get_stat(stat))
	if combatant.is_alive():
		combatant.hp = mini(combatant.hp + up.gains.max_hp, combatant.max_hp())
	combatant.mp = mini(combatant.mp + up.gains.max_mp, combatant.max_mp())
	for skill: SkillData in Progression.skills_learned_at(data, level):
		if not skill in combatant.skills:
			combatant.skills.append(skill)
			up.learned.append(skill)
	return up


## Full HP and MP, statuses cleared (rest points).
func heal_full() -> void:
	combatant.hp = combatant.max_hp()
	combatant.mp = combatant.max_mp()
	combatant.statuses.clear()
	combatant.is_defending = false
	combatant.guarded_by = null


# --- equipment ------------------------------------------------------------------------------

## The item worn in `slot` (null = empty).
func equipped(slot: EquipmentData.Category) -> EquipmentData:
	return combatant.equipment.get(slot) as EquipmentData


## The character may wear `item` (its slot is in CharacterData.allowed_equipment).
func can_equip(item: EquipmentData) -> bool:
	return item != null and item.category in data.allowed_equipment


## Wears `item` in its slot, taking it out of `inventory`; what the slot held goes back into the
## inventory. False (nothing changes) when the character can't wear it or the inventory has none.
func equip_from(inventory: Inventory, item: EquipmentData) -> bool:
	if not can_equip(item) or not inventory.has(item.id):
		return false
	var old: EquipmentData = equipped(item.category)
	if old == item:
		return true
	if old != null and not inventory.has_room(old.id):
		return false
	inventory.remove(item.id)
	if old != null:
		inventory.add(old.id)
	combatant.equipment[item.category] = item
	combatant.clamp_to_max()
	return true


## Takes off what `slot` holds and puts it in `inventory`. False when the slot is empty or the
## inventory has no room for it.
func unequip_to(inventory: Inventory, slot: EquipmentData.Category) -> bool:
	var old: EquipmentData = equipped(slot)
	if old == null or inventory.add(old.id) < 1:
		return false
	combatant.equipment.erase(slot)
	combatant.clamp_to_max()
	return true


## Every stat as it would read with `item` in `slot` (null = the slot emptied), for the
## equipment page's preview. Nothing changes.
func stats_with(slot: EquipmentData.Category, item: EquipmentData) -> Dictionary[StringName, int]:
	var worn: Dictionary[EquipmentData.Category, EquipmentData] = combatant.equipment
	var trial: Dictionary[EquipmentData.Category, EquipmentData] = worn.duplicate()
	if item != null:
		trial[slot] = item
	else:
		trial.erase(slot)
	combatant.equipment = trial
	var out: Dictionary[StringName, int] = {}
	for stat: StringName in StatBlock.NAMES:
		out[stat] = combatant.stat(stat)
	combatant.equipment = worn
	return out
