extends TestCase
## Every dialogue file parses and matches the schema; the validator catches broken files.

## The §4.7 example from PROJECT_PLAN.md (valid).
const EXAMPLE: String = """{ "id": "elder_intro", "lines": [
	{ "speaker": "Elder Maren", "text": "The bells stopped ringing three nights ago.", "set_flag": "met_elder" },
	{ "speaker": "Elder Maren", "text": "Will you look into the graveyard?",
	  "choices": [ { "text": "I will.", "goto": 2, "set_flag": "quest_graveyard_accepted" },
				   { "text": "Not now.", "goto": "end" } ] },
	{ "speaker": "Elder Maren", "text": "Then take this, and go before dark.", "give_item": "minor_potion" } ],
	"conditions": { "if_flag": "met_elder", "use": "elder_again" } }"""


func test_every_dialogue_file_is_valid() -> void:
	var ids: Array[String] = DialogueData.list_ids()
	assert_true(ids.size() >= 3, "at least the three graveyard examine texts")
	for id: String in ids:
		var text: String = FileAccess.get_file_as_string(DialogueData.path_for(StringName(id)))
		var data: Variant = JSON.parse_string(text)
		var errors: Array[String] = DialogueData.validate(data, id, ids)
		assert_true(errors.is_empty(), "%s.json: %s" % [id, "; ".join(errors)])


func test_examine_texts_exist() -> void:
	for id: String in ["examine_headstone", "examine_sarcophagus", "examine_bone_pyre", "examine_notice_board"]:
		assert_false(DialogueData.load_dialogue(StringName(id)).is_empty(), "%s loads" % id)


func test_plan_example_is_valid() -> void:
	var errors: Array[String] = DialogueData.validate(JSON.parse_string(EXAMPLE), "elder_intro")
	assert_true(errors.is_empty(), "; ".join(errors))


func test_rejects_goto_out_of_range() -> void:
	var data: Dictionary = {"id": "x", "lines": [{"text": "a", "goto": 2.0}, {"text": "b"}]}
	assert_has_error(DialogueData.validate(data, "x"), "lines[0].goto")


func test_rejects_fractional_and_unknown_goto() -> void:
	var data: Dictionary = {"id": "x", "lines": [
		{"text": "a", "choices": [{"text": "c", "goto": 0.5}, {"text": "d", "goto": "later"}]}]}
	var errors: Array[String] = DialogueData.validate(data, "x")
	assert_has_error(errors, "choices[0].goto")
	assert_has_error(errors, "choices[1].goto")


func test_rejects_missing_or_empty_parts() -> void:
	assert_has_error(DialogueData.validate({"id": "x"}, "x"), "'lines'")
	assert_has_error(DialogueData.validate({"id": "x", "lines": []}, "x"), "'lines'")
	assert_has_error(DialogueData.validate({"id": "x", "lines": [{"text": "  "}]}, "x"), "lines[0].text")
	assert_has_error(DialogueData.validate({"lines": [{"text": "a"}]}, "x"), "'id'")
	assert_has_error(DialogueData.validate([], "x"), "root")


func test_rejects_id_mismatch_and_unknown_keys() -> void:
	assert_has_error(DialogueData.validate({"id": "y", "lines": [{"text": "a"}]}, "x"), "file is 'x'")
	assert_has_error(DialogueData.validate({"id": "x", "lines": [{"text": "a", "speakr": "Bob"}]}, "x"), "speakr")


func test_rejects_unknown_condition_target() -> void:
	var data: Dictionary = {"id": "x", "lines": [{"text": "a"}], "conditions": {"if_flag": "f", "use": "nope"}}
	assert_has_error(DialogueData.validate(data, "x", ["x"] as Array[String]), "conditions.use")


func assert_has_error(errors: Array[String], fragment: String) -> void:
	for error: String in errors:
		if error.contains(fragment):
			return
	fail("no error mentions '%s' (got %s)" % [fragment, errors])
