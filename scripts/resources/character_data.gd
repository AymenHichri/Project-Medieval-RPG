class_name CharacterData
extends Resource
## A playable character definition. Read-only at runtime (see PartyMember / Combatant).

@export var id: StringName
@export var display_name: String = ""
@export var portrait: Texture2D
## Level 1 stats.
@export var base_stats: StatBlock
@export var growth: GrowthCurve
@export var visual: CombatantVisual
@export var starting_skills: Array[SkillData] = []
@export var skill_unlocks: Array[SkillUnlock] = []
## The equipment slots this character can fill (Phase 9). A slot left out stays empty.
@export var allowed_equipment: Array[EquipmentData.Category] = [
	EquipmentData.Category.WEAPON, EquipmentData.Category.SHIELD,
	EquipmentData.Category.HELM, EquipmentData.Category.ACCESSORY]
