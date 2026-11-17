class_name DialogueData
extends RefCounted
## Loads and validates dialogue JSON files (`data/dialogue/<id>.json`, PROJECT_PLAN.md §4.7).
## Schema:
##   { "id": String (= file name), "lines": [ line, ... ] (non-empty),
##     "conditions": { "if_flag": String, "use": String (another dialogue id) } (optional) }
##   line   = { "text": String (non-empty), "speaker": String?, "set_flag": String?,
##              "give_item": String?, "goto": target?, "choices": [ choice, ... ]? }
##   choice = { "text": String (non-empty), "goto": target?, "set_flag": String? }
##   target = a line index (integer, 0 ≤ i < lines.size()) or "end".
##   give_item = "<item_id>", "<item_id>:<count>" or "gold:<amount>" (run by DialogueRunner).
## Unknown keys are errors (they are almost always typos).

const DIR: String = "res://data/dialogue"
const END: String = "end"

const ROOT_KEYS: Array[String] = ["id", "lines", "conditions"]
const LINE_KEYS: Array[String] = ["text", "speaker", "set_flag", "give_item", "goto", "choices"]
const CHOICE_KEYS: Array[String] = ["text", "goto", "set_flag"]
const CONDITION_KEYS: Array[String] = ["if_flag", "use"]
const OPTIONAL_STRING_LINE_KEYS: Array[String] = ["speaker", "set_flag", "give_item"]


static func path_for(id: StringName) -> String:
	return "%s/%s.json" % [DIR, id]


## Every dialogue id in DIR (file names without `.json`), sorted.
static func list_ids() -> Array[String]:
	var ids: Array[String] = []
	var dir: DirAccess = DirAccess.open(DIR)
	if dir == null:
		return ids
	for file_name: String in dir.get_files():
		if file_name.ends_with(".json"):
			ids.append(file_name.get_basename())
	ids.sort()
	return ids


## Loads and validates a dialogue. Returns {} (after push_error) when it is missing or invalid.
static func load_dialogue(id: StringName) -> Dictionary:
	var path: String = path_for(id)
	if not FileAccess.file_exists(path):
		push_error("Dialogue '%s' not found (%s)" % [id, path])
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var errors: Array[String] = validate(data, String(id))
	if not errors.is_empty():
		push_error("Dialogue '%s' is invalid: %s" % [id, "; ".join(errors)])
		return {}
	return data as Dictionary


## Returns the schema errors of parsed JSON `data` (empty = valid). `expected_id` is the file
## name; `known_ids` (optional) are the dialogue ids a `conditions.use` may point to.
static func validate(data: Variant, expected_id: String = "", known_ids: Array[String] = []) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary:
		errors.append("root is not an object (invalid JSON?)")
		return errors
	var root: Dictionary = data as Dictionary
	_check_keys(root, ROOT_KEYS, "root", errors)
	if not _is_text(root.get("id")):
		errors.append("'id' must be a non-empty string")
	elif not expected_id.is_empty() and str(root["id"]) != expected_id:
		errors.append("'id' is '%s' but the file is '%s'" % [root["id"], expected_id])

	var lines: Array = root.get("lines", []) as Array if root.get("lines") is Array else []
	if lines.is_empty():
		errors.append("'lines' must be a non-empty array")
	for i: int in lines.size():
		_validate_line(lines[i], i, lines.size(), errors)

	if root.has("conditions"):
		_validate_conditions(root["conditions"], known_ids, errors)
	return errors


static func _validate_line(value: Variant, index: int, line_count: int, errors: Array[String]) -> void:
	var where: String = "lines[%d]" % index
	if not value is Dictionary:
		errors.append("%s is not an object" % where)
		return
	var line: Dictionary = value as Dictionary
	_check_keys(line, LINE_KEYS, where, errors)
	if not _is_text(line.get("text")):
		errors.append("%s.text must be a non-empty string" % where)
	for key: String in OPTIONAL_STRING_LINE_KEYS:
		if line.has(key) and not line[key] is String:
			errors.append("%s.%s must be a string" % [where, key])
	if line.has("give_item") and line["give_item"] is String and not _is_give_spec(str(line["give_item"])):
		errors.append("%s.give_item must be \"<id>\", \"<id>:<count>\" or \"gold:<amount>\" (got \"%s\")" % [where, line["give_item"]])
	if line.has("goto"):
		_check_target(line["goto"], line_count, where + ".goto", errors)
	if line.has("choices"):
		var choices: Array = line["choices"] as Array if line["choices"] is Array else []
		if choices.is_empty():
			errors.append("%s.choices must be a non-empty array" % where)
		for c: int in choices.size():
			_validate_choice(choices[c], "%s.choices[%d]" % [where, c], line_count, errors)


static func _validate_choice(value: Variant, where: String, line_count: int, errors: Array[String]) -> void:
	if not value is Dictionary:
		errors.append("%s is not an object" % where)
		return
	var choice: Dictionary = value as Dictionary
	_check_keys(choice, CHOICE_KEYS, where, errors)
	if not _is_text(choice.get("text")):
		errors.append("%s.text must be a non-empty string" % where)
	if choice.has("set_flag") and not choice["set_flag"] is String:
		errors.append("%s.set_flag must be a string" % where)
	if choice.has("goto"):
		_check_target(choice["goto"], line_count, where + ".goto", errors)


static func _validate_conditions(value: Variant, known_ids: Array[String], errors: Array[String]) -> void:
	if not value is Dictionary:
		errors.append("'conditions' is not an object")
		return
	var conditions: Dictionary = value as Dictionary
	_check_keys(conditions, CONDITION_KEYS, "conditions", errors)
	if not _is_text(conditions.get("if_flag")):
		errors.append("conditions.if_flag must be a non-empty string")
	if not _is_text(conditions.get("use")):
		errors.append("conditions.use must be a non-empty string")
	elif not known_ids.is_empty() and not str(conditions["use"]) in known_ids:
		errors.append("conditions.use '%s' is not a known dialogue" % conditions["use"])


## A goto target: "end" or a whole-number line index in range (JSON numbers parse as float).
static func _check_target(value: Variant, line_count: int, where: String, errors: Array[String]) -> void:
	if value is String and str(value) == END:
		return
	if (value is float or value is int):
		var number: float = float(value)
		if number == floorf(number) and number >= 0.0 and number < line_count:
			return
	errors.append("%s must be \"end\" or a line index 0..%d (got %s)" % [where, line_count - 1, JSON.stringify(value)])


static func _check_keys(object: Dictionary, allowed: Array[String], where: String, errors: Array[String]) -> void:
	for key: Variant in object.keys():
		if not str(key) in allowed:
			errors.append("%s has unknown key '%s'" % [where, key])


static func _is_give_spec(spec: String) -> bool:
	var regex: RegEx = RegEx.create_from_string("^[a-z0-9_]+(:[1-9][0-9]*)?$")
	return regex.search(spec) != null


static func _is_text(value: Variant) -> bool:
	return value is String and not str(value).strip_edges().is_empty()
