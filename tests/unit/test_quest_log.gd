extends TestCase
## QuestLog (Phase 10): stages advance by flag, never go back, completion is signalled once; quest
## targets and givers; GameState starts quests and moves them on as flags are set.

const QUEST_ID: StringName = &"silence_in_the_graveyard"

var _flags: Dictionary[StringName, Variant] = {}
var _quests: QuestLog


func before_each() -> void:
	_flags = GameState.flags.duplicate()
	_quests = GameState.quests
	GameState.flags = {}
	GameState.quests = QuestLog.new()


func after_each() -> void:
	GameState.flags = _flags
	GameState.quests = _quests


## A three-stage fixture quest: a (needs a1 and a2), b, c (turn-in).
func _quest() -> QuestData:
	var quest: QuestData = QuestData.new()
	quest.id = &"fixture"
	quest.title = "Fixture"
	quest.completed_text = "All done."
	for spec: Array in [["Find both.", [&"a1", &"a2"], false], ["Then b.", [&"b"], false], ["Report.", [&"c"], true]]:
		var stage: QuestStage = QuestStage.new()
		stage.text = spec[0]
		var stage_flags: Array[StringName] = []
		stage_flags.assign(spec[1])
		stage.flags = stage_flags
		stage.turn_in = spec[2]
		stage.progress_label = "Found"
		quest.stages.append(stage)
	return quest


func test_stage_advances_only_when_all_its_flags_are_set() -> void:
	var quests: QuestLog = QuestLog.new()
	var flags: Dictionary[StringName, Variant] = {}
	assert_true(quests.start(_quest(), flags))
	assert_eq(quests.stage_index(&"fixture"), 0)
	flags[&"a1"] = true
	quests.update(flags)
	assert_eq(quests.stage_index(&"fixture"), 0, "one of two flags is not enough")
	assert_eq(quests.stage_text(&"fixture", flags), "Find both.\nFound: 1/2")
	flags[&"a2"] = true
	quests.update(flags)
	assert_eq(quests.stage_index(&"fixture"), 1)
	assert_eq(quests.stage_text(&"fixture", flags), "Then b.")


func test_later_flags_set_early_advance_in_order() -> void:
	var quests: QuestLog = QuestLog.new()
	var advanced: Array[int] = []
	quests.stage_advanced.connect(func(_q: QuestData, stage: int) -> void: advanced.append(stage))
	var flags: Dictionary[StringName, Variant] = {&"b": true}
	quests.start(_quest(), flags)
	assert_eq(quests.stage_index(&"fixture"), 0, "b alone does not skip stage a")
	flags[&"a1"] = true
	flags[&"a2"] = true
	quests.update(flags)
	assert_eq(quests.stage_index(&"fixture"), 2, "a, then the already-set b")
	assert_eq(advanced, [1, 2] as Array[int])


func test_no_regression_when_a_flag_is_cleared() -> void:
	var quests: QuestLog = QuestLog.new()
	var flags: Dictionary[StringName, Variant] = {&"a1": true, &"a2": true}
	quests.start(_quest(), flags)
	assert_eq(quests.stage_index(&"fixture"), 1)
	flags[&"a1"] = false
	quests.update(flags)
	assert_eq(quests.stage_index(&"fixture"), 1, "a stage never goes back")


func test_completion_emits_once() -> void:
	var quests: QuestLog = QuestLog.new()
	var completed: Array[StringName] = []
	quests.quest_completed.connect(func(q: QuestData) -> void: completed.append(q.id))
	var flags: Dictionary[StringName, Variant] = {}
	quests.start(_quest(), flags)
	for flag: StringName in [&"a1", &"a2", &"b", &"c"]:
		flags[flag] = true
		quests.update(flags)
	quests.update(flags)
	quests.update(flags)
	assert_eq(completed, [&"fixture"] as Array[StringName], "exactly one completion")
	assert_true(quests.is_completed(&"fixture"))
	assert_false(quests.is_active(&"fixture"))
	assert_eq(quests.stage_text(&"fixture", flags), "All done.")
	assert_eq(quests.completed_quests().size(), 1)
	assert_eq(quests.active_quests().size(), 0)


func test_start_twice_is_refused_and_null_is_ignored() -> void:
	var quests: QuestLog = QuestLog.new()
	var started: Array[int] = [0]
	quests.quest_started.connect(func(_q: QuestData) -> void: started[0] += 1)
	var flags: Dictionary[StringName, Variant] = {}
	assert_true(quests.start(_quest(), flags))
	assert_false(quests.start(_quest(), flags), "already started")
	assert_false(quests.start(null, flags))
	assert_eq(started[0], 1)


func test_targets_and_giver() -> void:
	var quests: QuestLog = QuestLog.new()
	var flags: Dictionary[StringName, Variant] = {}
	assert_true(quests.is_target(&"fixture", -1, &"", flags), "the giver, before the quest starts")
	assert_false(quests.is_target(&"fixture", 0, &"a1", flags), "no stage target before it starts")
	quests.start(_quest(), flags)
	assert_false(quests.is_target(&"fixture", -1, &"", flags), "the giver waits while stage a runs")
	assert_true(quests.is_target(&"fixture", 0, &"a1", flags))
	flags[&"a1"] = true
	quests.update(flags)
	assert_false(quests.is_target(&"fixture", 0, &"a1", flags), "done with this one")
	assert_true(quests.is_target(&"fixture", 0, &"a2", flags), "the other is still wanted")
	for flag: StringName in [&"a2", &"b"]:
		flags[flag] = true
	quests.update(flags)
	assert_true(quests.is_target(&"fixture", -1, &"", flags), "turn-in stage: back to the giver")
	flags[&"c"] = true
	quests.update(flags)
	assert_false(quests.is_target(&"fixture", -1, &"", flags), "nothing left to give")


func test_to_dict_records_stage_indices() -> void:
	var quests: QuestLog = QuestLog.new()
	var flags: Dictionary[StringName, Variant] = {&"a1": true, &"a2": true}
	quests.start(_quest(), flags)
	assert_eq(quests.to_dict(), {"fixture": 1})


func test_game_state_starts_and_moves_the_example_quest() -> void:
	var changes: Array[int] = [0]
	var on_change: Callable = func(_q: QuestData) -> void: changes[0] += 1
	GameState.quests_changed.connect(on_change)
	assert_true(GameState.start_quest(QUEST_ID))
	assert_false(GameState.start_quest(QUEST_ID), "once")
	assert_true(GameState.quests.is_active(QUEST_ID))
	for flag: StringName in [&"grave_widow_searched", &"grave_soldier_searched"]:
		GameState.set_flag(flag)
	assert_eq(GameState.quests.stage_index(QUEST_ID), 0)
	assert_true(GameState.quests.stage_text(QUEST_ID, GameState.flags).ends_with("Graves searched: 2/3"))
	GameState.set_flag(&"grave_fresh_searched")
	assert_eq(GameState.quests.stage_index(QUEST_ID), 1, "the crypt stage")
	GameState.set_flag(&"blade_assassin_defeated")
	assert_true(GameState.quests.current_stage(QUEST_ID).turn_in, "report back")
	GameState.set_flag(&"silence_reported")
	assert_true(GameState.quests.is_completed(QUEST_ID))
	GameState.quests_changed.disconnect(on_change)
	assert_eq(changes[0], 4, "started, two stage changes, completed")


func test_unknown_quest_is_not_started() -> void:
	assert_false(GameState.start_quest(&"no_such_quest"))
	assert_eq(GameState.quests.active_quests().size(), 0)


func test_new_game_clears_quests_and_visited_maps() -> void:
	var party: Party = GameState.party
	var inventory: Inventory = GameState.inventory
	var visited: Array[String] = GameState.visited_maps.duplicate()
	GameState.party = Party.new()
	GameState.inventory = Inventory.new()
	GameState.start_quest(QUEST_ID)
	GameState.visit_map("res://scenes/world/maps/village_01.tscn")
	GameState.new_game()
	assert_false(GameState.quests.has_quest(QUEST_ID))
	assert_true(GameState.visited_maps.is_empty())
	GameState.party = party
	GameState.inventory = inventory
	GameState.visited_maps = visited
