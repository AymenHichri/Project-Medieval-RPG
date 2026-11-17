extends TestCase
## DialogueRunner (Phase 7): lines advance, choices jump, flags and items reach GameState, and
## the conditional entry picks the alternate dialogue once its flag is set.

var _flags: Dictionary[StringName, Variant] = {}
var _items: Dictionary[StringName, int] = {}
var _gold: int = 0


func before_each() -> void:
	_flags = GameState.flags.duplicate()
	_items = GameState.items.duplicate()
	_gold = GameState.gold
	GameState.flags = {}
	GameState.items = {}
	GameState.gold = 0


func after_each() -> void:
	GameState.flags = _flags
	GameState.items = _items
	GameState.gold = _gold


func _data(lines: Array) -> Dictionary:
	return {"id": "test", "lines": lines}


func test_lines_advance_in_order_then_finish() -> void:
	var runner: DialogueRunner = DialogueRunner.from_data(_data([
		{"text": "one", "speaker": "A"}, {"text": "two"}, {"text": "three"}]), GameState)
	assert_eq(runner.text(), "one")
	assert_eq(runner.speaker(), "A")
	runner.advance()
	assert_eq(runner.text(), "two")
	assert_eq(runner.speaker(), "")
	runner.advance()
	runner.advance()
	assert_true(runner.is_finished())
	assert_eq(runner.current_line(), {})


func test_line_goto_jumps_and_end_finishes() -> void:
	var runner: DialogueRunner = DialogueRunner.from_data(_data([
		{"text": "a", "goto": 2.0}, {"text": "skipped"}, {"text": "c", "goto": "end"}, {"text": "never"}]), GameState)
	runner.advance()
	assert_eq(runner.text(), "c")
	runner.advance()
	assert_true(runner.is_finished(), "goto end closes the dialogue")


func test_choice_goto_and_set_flag() -> void:
	var lines: Array = [
		{"text": "Will you?", "choices": [
			{"text": "Yes", "set_flag": "said_yes", "goto": 2.0},
			{"text": "No", "goto": "end"}]},
		{"text": "never shown"},
		{"text": "Good."}]
	var runner: DialogueRunner = DialogueRunner.from_data(_data(lines), GameState)
	assert_eq(runner.choices(), PackedStringArray(["Yes", "No"]))
	runner.advance()
	assert_eq(runner.text(), "Will you?", "advance() does not skip a choice")
	runner.choose(0)
	assert_eq(runner.text(), "Good.")
	assert_eq(GameState.get_flag(&"said_yes"), true, "choice flag set in GameState")

	var other: DialogueRunner = DialogueRunner.from_data(_data(lines), GameState)
	other.choose(1)
	assert_true(other.is_finished(), "the other choice ends it")


func test_choice_without_goto_falls_through_to_the_next_line() -> void:
	var runner: DialogueRunner = DialogueRunner.from_data(_data([
		{"text": "?", "choices": [{"text": "ok"}]}, {"text": "next"}]), GameState)
	runner.choose(0)
	assert_eq(runner.text(), "next")


func test_line_set_flag_and_give_item_run_on_entering_the_line() -> void:
	var runner: DialogueRunner = DialogueRunner.from_data(_data([
		{"text": "hello", "set_flag": "greeted"},
		{"text": "here", "give_item": "minor_potion:2"},
		{"text": "coins", "give_item": "gold:15"},
		{"text": "one more", "give_item": "minor_potion"}]), GameState)
	assert_eq(GameState.get_flag(&"greeted"), true, "first line's flag set on open")
	assert_eq(GameState.item_count(&"minor_potion"), 0, "not before its line")
	runner.advance()
	assert_eq(GameState.item_count(&"minor_potion"), 2)
	runner.advance()
	assert_eq(GameState.gold, 15)
	runner.advance()
	assert_eq(GameState.item_count(&"minor_potion"), 3)


func test_conditional_entry_uses_the_alternate_dialogue() -> void:
	assert_eq(DialogueRunner.resolve_id(&"elder_intro", GameState), &"elder_intro")
	GameState.set_flag(&"met_elder")
	assert_eq(DialogueRunner.resolve_id(&"elder_intro", GameState), &"elder_again")
	GameState.set_flag(&"elder_agreed")
	assert_eq(DialogueRunner.resolve_id(&"elder_intro", GameState), &"elder_again_agreed", "chains follow")
	var runner: DialogueRunner = DialogueRunner.open(&"elder_intro", GameState)
	assert_eq(runner.dialogue_id, &"elder_again_agreed")


func test_elder_intro_accept_path() -> void:
	var runner: DialogueRunner = DialogueRunner.open(&"elder_intro", GameState)
	assert_eq(runner.dialogue_id, &"elder_intro")
	assert_eq(GameState.get_flag(&"met_elder"), true)
	while not runner.has_choices():
		runner.advance()
	runner.choose(0)
	assert_eq(GameState.get_flag(&"elder_agreed"), true)
	assert_eq(GameState.item_count(&"minor_potion"), 2, "the Elder's potions")
	while not runner.is_finished():
		runner.advance()
	assert_eq(DialogueRunner.resolve_id(&"elder_intro", GameState), &"elder_again_agreed")


func test_elder_intro_refuse_path_then_second_talk_differs() -> void:
	var runner: DialogueRunner = DialogueRunner.open(&"elder_intro", GameState)
	var first_texts: PackedStringArray = [runner.text()]
	while not runner.has_choices():
		runner.advance()
	runner.choose(1)
	while not runner.is_finished():
		runner.advance()
	assert_eq(GameState.get_flag(&"elder_agreed"), false)
	assert_eq(GameState.item_count(&"minor_potion"), 0)
	var second: DialogueRunner = DialogueRunner.open(&"elder_intro", GameState)
	assert_eq(second.dialogue_id, &"elder_again")
	assert_false(second.text() in first_texts, "a different response on the second talk")
