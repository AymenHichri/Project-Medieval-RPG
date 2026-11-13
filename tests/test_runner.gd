extends SceneTree
## Minimal headless test runner (no third-party addon).
##   godot --headless --path <project> -s res://tests/test_runner.gd [-- --filter=<substring>]
## Discovers res://tests/unit/test_*.gd and res://tests/smoke/test_*.gd, runs every `test_*`
## method of each TestCase, prints a summary and exits 1 if anything failed.

const TEST_DIRS: Array[String] = ["res://tests/unit", "res://tests/smoke"]


func _initialize() -> void:
	# Wait one frame so autoload singletons are in the tree before tests run.
	await process_frame
	var filter: String = _read_filter()
	var files: Array[String] = _discover(filter)
	var total_tests: int = 0
	var all_failures: Array[String] = []
	for path: String in files:
		var script: GDScript = load(path) as GDScript
		if script == null or not script.can_instantiate():
			all_failures.append("%s: could not load script" % path)
			continue
		var case: TestCase = script.new() as TestCase
		if case == null:
			all_failures.append("%s: does not extend TestCase" % path)
			continue
		for method: Dictionary in case.get_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			total_tests += 1
			case.current_test = "%s::%s" % [path.get_file(), method_name]
			var before: int = case.failures.size()
			case.before_each()
			await case.call(method_name)
			case.after_each()
			var status: String = "ok" if case.failures.size() == before else "FAIL"
			print("[%s] %s" % [status, case.current_test])
		all_failures.append_array(case.failures)
	print("")
	for failure: String in all_failures:
		printerr("FAIL  " + failure)
	print("%d tests, %d failures (%d files)" % [total_tests, all_failures.size(), files.size()])
	quit(1 if all_failures.size() > 0 else 0)


func _read_filter() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			return arg.trim_prefix("--filter=")
	return ""


func _discover(filter: String) -> Array[String]:
	var result: Array[String] = []
	for dir_path: String in TEST_DIRS:
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir == null:
			continue
		for file_name: String in dir.get_files():
			if file_name.begins_with("test_") and file_name.ends_with(".gd") and (filter.is_empty() or filter in file_name):
				result.append(dir_path.path_join(file_name))
	result.sort()
	return result
