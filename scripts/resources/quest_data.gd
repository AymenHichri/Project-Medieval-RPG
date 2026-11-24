class_name QuestData
extends Resource
## A quest definition (PROJECT_PLAN.md §6.4, Phase 10): ordered stages, each finished by flags.
## Read-only at runtime; the player's progress lives in QuestLog. Files: `data/quests/<id>.tres`.

const DIR: String = "res://data/quests"

@export var id: StringName
@export var title: String = ""
## Who gave it (shown in the journal).
@export var giver: String = ""
## One line about the quest as a whole (journal header).
@export_multiline var summary: String = ""
@export var stages: Array[QuestStage] = []
## Journal text once every stage is done.
@export_multiline var completed_text: String = ""


static func path_for(quest_id: StringName) -> String:
	return "%s/%s.tres" % [DIR, quest_id]


## The quest with this id, or null (after an error) when there is no such file.
static func find(quest_id: StringName) -> QuestData:
	var path: String = path_for(quest_id)
	if not ResourceLoader.exists(path):
		push_error("Quest '%s' not found (%s)" % [quest_id, path])
		return null
	return load(path) as QuestData
