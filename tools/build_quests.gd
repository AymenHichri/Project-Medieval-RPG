extends SceneTree
## Generates the quests (Phase 10) in res://data/quests/:
##   godot --headless --path <project> -s res://tools/build_quests.gd
## Source of truth for quest stages and texts. Re-running it overwrites the files.
## The flags a stage waits for are set by dialogue lines (`set_flag`) and by the boss fight
## (BossEncounter.defeated_flag), so renaming one here means renaming it there too.

const DIR: String = "res://data/quests"

var _failed: bool = false


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	_silence_in_the_graveyard()
	print("quests %s" % ("FAILED" if _failed else "written"))
	quit(1 if _failed else 0)


## The example quest (PROJECT_PLAN.md Phase 10): talk → investigate 3 graves → boss → report back.
## Started by Elder Maren (`start_quest` in elder_intro / elder_again).
func _silence_in_the_graveyard() -> void:
	var quest: QuestData = QuestData.new()
	quest.id = &"silence_in_the_graveyard"
	quest.title = "Silence in the Graveyard"
	quest.giver = "Elder Maren"
	quest.summary = "Villagers vanish on the graveyard road, and their own kin forget their faces."
	quest.stages = [
		_stage("Elder Maren says three graves in the old graveyard were opened from below. Search them.",
				[&"grave_widow_searched", &"grave_soldier_searched", &"grave_fresh_searched"], "Graves searched"),
		_stage("Every trail ends at the crypt. Whatever sealed its door is waiting behind it.",
				[&"blade_assassin_defeated"]),
		_stage("The crypt is silent. Tell Elder Maren what you found.", [&"silence_reported"], "", true),
	]
	quest.completed_text = "The Blade Assassin is dead and the graveyard is quiet. Elder Maren has your report, and the village has its names back, for now."
	_save(quest)


func _stage(text: String, flags: Array[StringName], progress_label: String = "", turn_in: bool = false) -> QuestStage:
	var stage: QuestStage = QuestStage.new()
	stage.text = text
	stage.flags = flags
	stage.progress_label = progress_label
	stage.turn_in = turn_in
	return stage


func _save(quest: QuestData) -> void:
	var path: String = QuestData.path_for(quest.id)
	var err: Error = ResourceSaver.save(quest, path)
	if err != OK:
		push_error("could not save %s (%s)" % [path, error_string(err)])
		_failed = true
