class_name DialogueRunner
extends RefCounted
## Steps through one validated dialogue (DialogueData schema) with no UI, so the rules are
## testable headless. DialogueManager drives it and shows each line in the DialogueBox.
##   var runner := DialogueRunner.open(id, GameState)    # follows conditions.if_flag → use
##   while not runner.is_finished():
##       show(runner.current_line()); runner.advance()   # or runner.choose(i) on a choice line
## Entering a line runs its `set_flag` and `give_item`. After a line, its `goto` (or the next
## line) follows; a choice's own `set_flag` runs and its `goto` (or the next line) follows.
## `give_item` is "<item_id>", "<item_id>:<count>" or "gold:<amount>".

## How many `conditions.use` redirects are followed before giving up (guards against loops).
const MAX_REDIRECTS: int = 8

## The id of the dialogue actually played (after conditional redirects).
var dialogue_id: StringName = &""
## Receives `set_flag(flag)`, `get_flag(flag)`, `add_item(id, n)` and `add_gold(n)` (GameState).
var state: Object

var _lines: Array = []
var _index: int = -1


## Loads `id`, follows its conditional entry while the flag is set, and enters the first line.
## Returns null when the dialogue is missing or invalid (DialogueData reports why).
static func open(id: StringName, game_state: Object) -> DialogueRunner:
	var resolved: StringName = resolve_id(id, game_state)
	var data: Dictionary = DialogueData.load_dialogue(resolved)
	if data.is_empty():
		return null
	return from_data(data, game_state)


## A runner over already-parsed dialogue data (tests); enters the first line.
static func from_data(data: Dictionary, game_state: Object) -> DialogueRunner:
	var runner: DialogueRunner = DialogueRunner.new()
	runner.dialogue_id = StringName(str(data.get("id", "")))
	runner.state = game_state
	runner._lines = data["lines"] as Array
	runner._enter(0)
	return runner


## The dialogue to play for `id`: while its `conditions.if_flag` is set, its `conditions.use`.
static func resolve_id(id: StringName, game_state: Object) -> StringName:
	var current: StringName = id
	for i: int in MAX_REDIRECTS:
		var path: String = DialogueData.path_for(current)
		if not FileAccess.file_exists(path):
			return current
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Dictionary or not (data as Dictionary).has("conditions"):
			return current
		var conditions: Dictionary = (data as Dictionary)["conditions"] as Dictionary
		if not bool(game_state.call(&"get_flag", StringName(str(conditions.get("if_flag", ""))), false)):
			return current
		current = StringName(str(conditions.get("use", "")))
	push_warning("DialogueRunner: too many conditional redirects from '%s'" % id)
	return current


func is_finished() -> bool:
	return _index < 0 or _index >= _lines.size()


## The line being shown ({} once finished).
func current_line() -> Dictionary:
	return {} if is_finished() else _lines[_index] as Dictionary


func current_index() -> int:
	return _index


func speaker() -> String:
	return str(current_line().get("speaker", ""))


func text() -> String:
	return str(current_line().get("text", ""))


## The choice texts of the current line (empty when it has none).
func choices() -> PackedStringArray:
	var out: PackedStringArray = []
	for choice: Variant in current_line().get("choices", []) as Array:
		out.append(str((choice as Dictionary)["text"]))
	return out


func has_choices() -> bool:
	return not choices().is_empty()


## Moves past a line without choices (its `goto`, or the next line). Ignored on a choice line.
func advance() -> void:
	if is_finished():
		return
	if has_choices():
		push_warning("DialogueRunner: advance() on a choice line; call choose()")
		return
	_jump(current_line().get("goto", _index + 1))


## Picks choice `index` of the current line: runs its `set_flag`, then follows its `goto`
## (or the next line).
func choose(index: int) -> void:
	var options: Array = current_line().get("choices", []) as Array
	if index < 0 or index >= options.size():
		push_warning("DialogueRunner: no choice %d" % index)
		return
	var choice: Dictionary = options[index] as Dictionary
	if choice.has("set_flag"):
		state.call(&"set_flag", StringName(str(choice["set_flag"])), true)
	_jump(choice.get("goto", _index + 1))


func _jump(target: Variant) -> void:
	if target is String and str(target) == DialogueData.END:
		_index = _lines.size()
		return
	_enter(int(target))


func _enter(index: int) -> void:
	_index = index
	if is_finished():
		return
	var line: Dictionary = current_line()
	if line.has("set_flag"):
		state.call(&"set_flag", StringName(str(line["set_flag"])), true)
	if line.has("give_item"):
		_give(str(line["give_item"]))


func _give(spec: String) -> void:
	var parts: PackedStringArray = spec.split(":")
	var id: String = parts[0].strip_edges()
	var amount: int = int(parts[1]) if parts.size() > 1 else 1
	if id == "gold":
		state.call(&"add_gold", amount)
	else:
		state.call(&"add_item", StringName(id), amount)
