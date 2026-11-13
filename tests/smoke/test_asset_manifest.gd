extends TestCase
## Every external file is covered by a complete licence row in docs/asset_manifest.csv.

const MANIFEST: String = "res://docs/asset_manifest.csv"
const SCANNED: Array[String] = ["res://assets", "res://addons/sovdigital"]
const REQUIRED: Array[String] = ["path", "name", "creator", "source_url", "license", "commercial_use", "attribution", "format", "usage"]

var rows: Array[Dictionary] = []


func before_each() -> void:
	rows.clear()
	var file: FileAccess = FileAccess.open(MANIFEST, FileAccess.READ)
	if file == null:
		return
	var header: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line()
		if line.size() < header.size():
			continue
		var row: Dictionary = {}
		for i: int in header.size():
			row[header[i]] = line[i].strip_edges()
		rows.append(row)


func _collect(path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	for file: String in dir.get_files():
		if not (file.ends_with(".import") or file.ends_with(".uid") or file == ".gitkeep"):
			out.append(path.path_join(file))
	for sub: String in dir.get_directories():
		_collect(path.path_join(sub), out)


func test_manifest_rows_are_complete() -> void:
	assert_true(rows.size() > 0, "manifest missing or empty")
	for row: Dictionary in rows:
		for key: String in REQUIRED:
			assert_true(String(row.get(key, "")) != "", "row %s: empty %s" % [row.get("path", "?"), key])
		assert_ne(String(row.get("commercial_use", "")).to_lower(), "no", "row %s forbids commercial use" % row.get("path", "?"))


func test_every_file_is_covered() -> void:
	var files: Array[String] = []
	for root: String in SCANNED:
		_collect(root, files)
	assert_true(files.size() > 100, "expected the extracted vendor files")
	var uncovered: Array[String] = []
	for file: String in files:
		var rel: String = file.trim_prefix("res://")
		var covered: bool = false
		for row: Dictionary in rows:
			if rel.begins_with(String(row["path"])):
				covered = true
				break
		if not covered:
			uncovered.append(rel)
	assert_eq(uncovered.size(), 0, "uncovered files: %s" % str(uncovered.slice(0, 5)))


func test_report_release_blockers() -> void:
	for row: Dictionary in rows:
		if String(row.get("release_blocker", "")).to_lower() == "yes":
			print("  RELEASE BLOCKER: %s (%s)" % [row["path"], row["name"]])
