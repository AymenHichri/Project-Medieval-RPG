extends TestCase
## Every project script parses (catches errors in scripts that `--import` never compiles).

const ROOTS: Array[String] = ["res://scripts", "res://scenes", "res://tests", "res://tools"]


func _collect(path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	for file: String in dir.get_files():
		if file.ends_with(".gd"):
			out.append(path.path_join(file))
	for sub: String in dir.get_directories():
		_collect(path.path_join(sub), out)


func test_all_scripts_load() -> void:
	var scripts: Array[String] = []
	for root: String in ROOTS:
		_collect(root, scripts)
	assert_true(scripts.size() >= 20, "expected at least 20 scripts, found %d" % scripts.size())
	for path: String in scripts:
		var script: GDScript = load(path) as GDScript
		assert_not_null(script, "failed to load " + path)
		if script != null:
			assert_true(script.can_instantiate(), "cannot instantiate " + path)
