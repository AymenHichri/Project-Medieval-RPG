extends TestCase
## Phase 10 dialogue keys: `start_quest`, `require_item` / `else_goto`, `take_item`, `portrait` and
## `music` (runner rules, validation, and the DialogueManager's portrait and music cue).

const QUEST_ID: StringName = &"silence_in_the_graveyard"
const MusicTest: GDScript = preload("res://tests/unit/test_music_manager.gd")

var _flags: Dictionary[StringName, Variant] = {}
var _items: Inventory
var _quests: QuestLog


func before_each() -> void:
	_flags = GameState.flags.duplicate()
	_items = GameState.inventory
	_quests = GameState.quests
	GameState.flags = {}
	GameState.inventory = Inventory.new()
	GameState.quests = QuestLog.new()


func after_each() -> void:
	DialogueTestUtil.close_dialogue()
	AudioManager.music.stop(0.0)
	GameState.flags = _flags
	GameState.inventory = _items
	GameState.quests = _quests


func _runner(lines: Array) -> DialogueRunner:
	return DialogueRunner.from_data({"id": "test", "lines": lines}, GameState)


func _finish(runner: DialogueRunner) -> void:
	var guard: int = 0
	while not runner.is_finished() and guard < 50:
		guard += 1
		runner.advance()


func test_start_quest_on_entering_a_line() -> void:
	var runner: DialogueRunner = _runner([{"text": "a"}, {"text": "b", "start_quest": String(QUEST_ID)}])
	assert_false(GameState.quests.has_quest(QUEST_ID))
	runner.advance()
	assert_true(GameState.quests.is_active(QUEST_ID))


func test_require_item_branches_on_what_the_party_holds() -> void:
	var lines: Array = [
		{"text": "door", "require_item": "skull_key", "else_goto": 2},
		{"text": "it opens", "goto": "end"},
		{"text": "it is locked"},
	]
	var without: DialogueRunner = _runner(lines)
	assert_eq(without.text(), "it is locked", "no key: else_goto")
	GameState.add_item(&"skull_key")
	var with_key: DialogueRunner = _runner(lines)
	assert_eq(with_key.text(), "door")
	with_key.advance()
	assert_eq(with_key.text(), "it opens")


func test_require_item_without_else_goto_ends_the_dialogue() -> void:
	var runner: DialogueRunner = _runner([{"text": "a"}, {"text": "pay", "require_item": "gold:50"}, {"text": "after"}])
	runner.advance()
	assert_true(runner.is_finished(), "not enough gold: the dialogue ends")
	GameState.gold = 50
	var rich: DialogueRunner = _runner([{"text": "a"}, {"text": "pay", "require_item": "gold:50", "take_item": "gold:50"}])
	rich.advance()
	assert_eq(rich.text(), "pay")
	assert_eq(GameState.gold, 0, "take_item gold spends it")


func test_a_loop_of_unmet_requirements_ends_the_dialogue() -> void:
	var runner: DialogueRunner = _runner([
		{"text": "a", "require_item": "skull_key", "else_goto": 1},
		{"text": "b", "require_item": "skull_key", "else_goto": 0}])
	assert_true(runner.is_finished())


func test_take_item_removes_on_entering() -> void:
	GameState.add_item(&"minor_potion", 3)
	var runner: DialogueRunner = _runner([{"text": "a", "take_item": "minor_potion:2"}])
	assert_eq(GameState.item_count(&"minor_potion"), 1)
	_finish(runner)
	GameState.add_item(&"skull_key")
	_runner([{"text": "k", "take_item": "skull_key"}])
	assert_eq(GameState.item_count(&"skull_key"), 0, "a key item can be taken")


func test_portrait_and_music_ids() -> void:
	var runner: DialogueRunner = _runner([{"text": "a", "speaker": "X", "portrait": "43_vampire_lord", "music": "mus_story_dread"}, {"text": "b"}])
	assert_eq(runner.portrait_id(), "43_vampire_lord")
	assert_eq(runner.music_id(), "mus_story_dread")
	runner.advance()
	assert_eq(runner.portrait_id(), "")
	assert_eq(runner.music_id(), "")


func test_line_portrait_overrides_the_npc_portrait() -> void:
	var npc_portrait: Texture2D = load("res://assets/vendor/gimbles/portraits/framed/256px/01_knight.png") as Texture2D
	var own: DialogueRunner = _runner([{"text": "a", "speaker": "Boss", "portrait": "43_vampire_lord"}])
	var shown: Texture2D = DialogueManager.line_portrait(own, npc_portrait)
	assert_eq(shown.resource_path, DialogueData.portrait_path("43_vampire_lord"))
	var plain: DialogueRunner = _runner([{"text": "a", "speaker": "Elder"}])
	assert_eq(DialogueManager.line_portrait(plain, npc_portrait), npc_portrait, "the NPC's own")
	var narration: DialogueRunner = _runner([{"text": "a"}])
	assert_null(DialogueManager.line_portrait(narration, npc_portrait), "no speaker, no portrait")


func test_music_cue_plays_over_the_map_music_and_ends_with_the_dialogue() -> void:
	var field: MusicTrack = MusicTrack.new()
	field.stream = MusicTest.silent_stream(30.0)
	AudioManager.music.play(field, 0.0)
	var cue: MusicTrack = load(DialogueData.music_path("mus_story_dread")) as MusicTrack
	assert_not_null(cue, "mus_story_dread is built")
	DialogueManager.start(&"crypt_door_open")
	assert_true(DialogueManager.is_active)
	assert_true(DialogueManager.is_cue_playing(), "the first line starts the cue")
	assert_eq(AudioManager.music.current_track, cue)
	DialogueTestUtil.close_dialogue()
	assert_false(DialogueManager.is_cue_playing())
	assert_eq(AudioManager.music.current_track, field, "back to the map music")


func test_validation_of_the_new_keys() -> void:
	var good: Dictionary = {"id": "x", "lines": [
		{"text": "a", "require_item": "skull_key", "else_goto": 1, "take_item": "gold:5",
		 "start_quest": String(QUEST_ID), "portrait": "43_vampire_lord", "music": "mus_story_sorrow"},
		{"text": "b", "music": "stop"}]}
	var errors: Array[String] = DialogueData.validate(good, "x")
	assert_true(errors.is_empty(), "; ".join(errors))
	var bad: Dictionary = {"id": "x", "lines": [
		{"text": "a", "else_goto": 1, "take_item": "two potions", "start_quest": "nope",
		 "portrait": "no_face", "music": "mus_nothing"},
		{"text": "b", "require_item": "skull_key", "else_goto": 1}]}
	errors = DialogueData.validate(bad, "x")
	for fragment: String in ["lines[0].else_goto needs a require_item", "lines[0].take_item", "start_quest 'nope'",
			"portrait 'no_face'", "music 'mus_nothing'", "lines[1].else_goto points at its own line"]:
		var found: bool = false
		for error: String in errors:
			found = found or error.contains(fragment)
		assert_true(found, "an error mentions '%s' (got %s)" % [fragment, errors])
