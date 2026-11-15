class_name SkillUnlock
extends Resource
## A skill a character learns on reaching `level`.

@export_range(1, 99) var level: int = 2
@export var skill: SkillData
