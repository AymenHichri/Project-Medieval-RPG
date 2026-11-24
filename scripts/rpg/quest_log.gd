class_name QuestLog
extends RefCounted
## The player's quests (PROJECT_PLAN.md §6.4, Phase 10): quest id → current stage index. A quest is
## started once (dialogue `start_quest`), then `update(flags)` moves it on while its current stage's
## flags are all set; once past the last stage it is completed. Stages never go back, even if a flag
## is cleared later, and each signal fires once per change. Pure logic: GameState calls `update`
## whenever a flag changes.

signal quest_started(quest: QuestData)
## The quest moved to stage `stage` (an index into `quest.stages`).
signal stage_advanced(quest: QuestData, stage: int)
signal quest_completed(quest: QuestData)

## Started quests, in the order they were started.
var _quests: Array[QuestData] = []
## Quest id → current stage index (`stages.size()` once completed).
var _stages: Dictionary[StringName, int] = {}


func clear() -> void:
	_quests.clear()
	_stages.clear()


## Starts `quest` and applies the flags already set. False when it is null or already started.
func start(quest: QuestData, flags: Dictionary[StringName, Variant]) -> bool:
	if quest == null or has_quest(quest.id):
		return false
	_quests.append(quest)
	_stages[quest.id] = 0
	quest_started.emit(quest)
	_advance(quest, flags)
	return true


## Moves every active quest on as far as `flags` allow.
func update(flags: Dictionary[StringName, Variant]) -> void:
	for quest: QuestData in _quests.duplicate():
		_advance(quest, flags)


func has_quest(quest_id: StringName) -> bool:
	return _stages.has(quest_id)


func is_active(quest_id: StringName) -> bool:
	var quest: QuestData = get_quest(quest_id)
	return quest != null and _stages[quest_id] < quest.stages.size()


func is_completed(quest_id: StringName) -> bool:
	var quest: QuestData = get_quest(quest_id)
	return quest != null and _stages[quest_id] >= quest.stages.size()


## The current stage index (-1 when not started; `stages.size()` once completed).
func stage_index(quest_id: StringName) -> int:
	return _stages.get(quest_id, -1) as int


## The current stage (null when not started or completed).
func current_stage(quest_id: StringName) -> QuestStage:
	var quest: QuestData = get_quest(quest_id)
	if quest == null or not is_active(quest_id):
		return null
	return quest.stages[_stages[quest_id]]


## The started quest with this id (null when not started).
func get_quest(quest_id: StringName) -> QuestData:
	for quest: QuestData in _quests:
		if quest.id == quest_id:
			return quest
	return null


func active_quests() -> Array[QuestData]:
	var out: Array[QuestData] = []
	for quest: QuestData in _quests:
		if is_active(quest.id):
			out.append(quest)
	return out


func completed_quests() -> Array[QuestData]:
	var out: Array[QuestData] = []
	for quest: QuestData in _quests:
		if is_completed(quest.id):
			out.append(quest)
	return out


## The journal text of a quest's current stage, with "(2/3)" progress when the stage needs several
## flags, or its completed text.
func stage_text(quest_id: StringName, flags: Dictionary[StringName, Variant]) -> String:
	var quest: QuestData = get_quest(quest_id)
	if quest == null:
		return ""
	if is_completed(quest_id):
		return quest.completed_text
	var stage: QuestStage = current_stage(quest_id)
	if stage.flags.size() <= 1:
		return stage.text
	var label: String = stage.progress_label if not stage.progress_label.is_empty() else "Progress"
	return "%s\n%s: %d/%d" % [stage.text, label, stage.flags_done(flags), stage.flags.size()]


## True when something tied to `quest_id` is where the player should go now: with `stage` -1, the
## quest giver (quest not started yet, or its current stage is a `turn_in`); otherwise the target of
## that stage while it is current and `done_flag` (if any) is not set.
func is_target(quest_id: StringName, stage: int, done_flag: StringName, flags: Dictionary[StringName, Variant]) -> bool:
	if stage < 0:
		if not has_quest(quest_id):
			return true
		var current: QuestStage = current_stage(quest_id)
		return current != null and current.turn_in
	if stage_index(quest_id) != stage:
		return false
	return done_flag.is_empty() or not bool(flags.get(done_flag, false))


## Progress as plain data (quest id → stage index), for saving (Phase 11).
func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for quest: QuestData in _quests:
		out[String(quest.id)] = _stages[quest.id]
	return out


func _advance(quest: QuestData, flags: Dictionary[StringName, Variant]) -> void:
	var stage: int = _stages[quest.id]
	var start_stage: int = stage
	while stage < quest.stages.size() and quest.stages[stage].is_done(flags):
		stage += 1
		_stages[quest.id] = stage
		if stage < quest.stages.size():
			stage_advanced.emit(quest, stage)
	if stage != start_stage and stage >= quest.stages.size():
		quest_completed.emit(quest)
