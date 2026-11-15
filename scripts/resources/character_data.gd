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
