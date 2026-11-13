extends SceneTree
## Generates the exploration maps and their prop scenes (see tools/map_builders/).
##   godot --headless --path <project> -s res://tools/build_maps.gd [-- village_01 graveyard_01]
## No argument builds every map. The builders are loaded at runtime, after the first frame:
## map scripts refer to autoloads by name, and those names are not known yet while the `-s`
## script itself is compiled.

const BUILDERS: Dictionary[String, String] = {
	"village_01": "res://tools/map_builders/village_01_builder.gd",
	"graveyard_01": "res://tools/map_builders/graveyard_01_builder.gd",
}


func _initialize() -> void:
	await process_frame
	var names: Array[String] = []
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("-"):
			names.append(arg)
	if names.is_empty():
		names.assign(BUILDERS.keys())
	var failed: bool = false
	for map_name: String in names:
		if not BUILDERS.has(map_name):
			push_error("unknown map '%s' (known: %s)" % [map_name, ", ".join(BUILDERS.keys())])
			failed = true
			continue
		var builder: Object = (load(BUILDERS[map_name]) as GDScript).new()
		builder.call(&"build")
	quit(1 if failed else 0)
