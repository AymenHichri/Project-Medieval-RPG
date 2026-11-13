extends SceneTree
## Writes ×2 nearest-neighbour copies of the dfgui UI PNGs (assets/vendor/dfgui/1x → 2x),
## so both UI kits share the 2 screen-px per art-px grid. Copies only; the 1x files are untouched.
##   godot --headless --path <project> -s res://tools/upscale_ui.gd

const SRC: String = "res://assets/vendor/dfgui/1x"
const DST: String = "res://assets/vendor/dfgui/2x"
const FACTOR: int = 2


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DST))
	var dir: DirAccess = DirAccess.open(SRC)
	if dir == null:
		push_error("upscale_ui: %s not found (run tools/extract_assets.py first)" % SRC)
		quit(1)
		return
	var count: int = 0
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".png"):
			continue
		var image: Image = Image.load_from_file(ProjectSettings.globalize_path(SRC.path_join(file_name)))
		if image == null:
			push_error("upscale_ui: cannot read %s" % file_name)
			continue
		image.resize(image.get_width() * FACTOR, image.get_height() * FACTOR, Image.INTERPOLATE_NEAREST)
		image.save_png(ProjectSettings.globalize_path(DST.path_join(file_name)))
		count += 1
	print("upscale_ui: wrote %d files to %s" % [count, DST])
	quit(0)
