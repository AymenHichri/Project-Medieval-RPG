class_name MapAtlas
extends RefCounted
## What the map page shows for each visited map (PROJECT_PLAN.md Phase 10):
## - its picture: the map rendered once into a SubViewport (the player, NPCs and floating icons
##   hidden, since they move or change; no HUD or fog: those are CanvasLayers outside the world),
##   saved as `user://map_cache/<map_id>_v<VERSION>.png`. The
##   page grades it sepia when it shows it. A headless run (tests) has no renderer: no picture.
## - its facts: name, camera bounds and markers (exits, rest points, quest targets, the boss door),
##   as fractions of the bounds, saved next to it as JSON when the map is entered, so maps that are
##   not loaded can still be shown. Which quest markers are lit is decided live (`visible_markers`).

const CACHE_DIR: String = "user://map_cache"
## Bump when the maps or the capture change, so every picture is taken again.
const VERSION: int = 1
## Width (px) of a captured picture; the height follows the map's camera bounds.
const CAPTURE_WIDTH: int = 1280

enum Kind { PLAYER, EXIT, QUEST, REST, BOSS }


static func map_id_of(map_path: String) -> String:
	return map_path.get_file().get_basename()


static func info_path(map_id: String) -> String:
	return "%s/%s_v%d.json" % [CACHE_DIR, map_id, VERSION]


static func picture_path(map_id: String) -> String:
	return "%s/%s_v%d.png" % [CACHE_DIR, map_id, VERSION]


## The map's name, path, camera bounds and markers (positions as fractions of the bounds).
static func describe(map: Map) -> Dictionary:
	var bounds: Rect2 = map.get_camera_bounds()
	var markers: Array = []
	for node: Node in map.find_children("*", "", true, false):
		var entry: Dictionary = {}
		if node is MapTransition:
			entry = {"kind": Kind.EXIT}
		elif node is RestPoint:
			entry = {"kind": Kind.REST}
		elif node is Interactable and (node as Interactable).quest != null:
			var area: Interactable = node as Interactable
			entry = {"kind": Kind.BOSS if area is BossTrigger else Kind.QUEST, "quest": String(area.quest.id),
					"stage": area.quest_stage, "done": String(area.quest_done_flag)}
		if entry.is_empty():
			continue
		var at: Vector2 = fraction(bounds, (node as Node2D).global_position)
		entry["x"] = at.x
		entry["y"] = at.y
		markers.append(entry)
	return {
		"name": map.display_name, "path": map.scene_file_path, "map_id": String(map.map_id),
		"bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "markers": markers,
	}


## `world` as a fraction of `bounds` (0..1 inside).
static func fraction(bounds: Rect2, world: Vector2) -> Vector2:
	return (world - bounds.position) / bounds.size


## Writes the map's facts to the cache (every visit, so they follow the current scene). Returns them.
static func save_info(map: Map) -> Dictionary:
	var info: Dictionary = describe(map)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	var file: FileAccess = FileAccess.open(info_path(map_id_of(map.scene_file_path)), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(info, "\t"))
	return info


## The cached facts of a visited map ({} when there are none).
static func load_info(map_path: String) -> Dictionary:
	var path: String = info_path(map_id_of(map_path))
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data as Dictionary if data is Dictionary else {}


## The markers to draw now: exits and rest points always; quest markers (and the boss door) only
## while they are the quest's current target (QuestLog.is_target).
static func visible_markers(info: Dictionary, quests: QuestLog, flags: Dictionary[StringName, Variant]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for value: Variant in info.get("markers", []) as Array:
		var marker: Dictionary = value as Dictionary
		var kind: int = int(marker.get("kind", -1))
		if kind == Kind.QUEST or kind == Kind.BOSS:
			if not quests.is_target(StringName(str(marker.get("quest", ""))), int(marker.get("stage", -1)),
					StringName(str(marker.get("done", ""))), flags):
				continue
		out.append(marker)
	return out


## True when the map has no cached picture yet and a renderer can make one.
static func can_capture(map_path: String) -> bool:
	return DisplayServer.get_name() != "headless" and not FileAccess.file_exists(picture_path(map_id_of(map_path)))


## Renders the whole map (its camera bounds) once into a SubViewport sharing the map's world, with
## the player, NPCs and interactable icons hidden, and saves the picture. Returns it (null when it
## could not be made).
static func capture(map: Map) -> Image:
	var path: String = picture_path(map_id_of(map.scene_file_path))
	var bounds: Rect2 = map.get_camera_bounds()
	var zoom: float = CAPTURE_WIDTH / bounds.size.x
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(CAPTURE_WIDTH, roundi(bounds.size.y * zoom))
	viewport.world_2d = map.get_viewport().world_2d
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var camera: Camera2D = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	camera.position = bounds.position
	camera.zoom = Vector2(zoom, zoom)
	viewport.add_child(camera)
	map.add_child(viewport)
	camera.make_current()
	var hidden: Array[CanvasItem] = []
	for item: CanvasItem in _transient_items(map):
		if item.visible:
			item.visible = false
			hidden.append(item)
	for i: int in 3:
		await RenderingServer.frame_post_draw
	var image: Image = null
	if is_instance_valid(viewport):
		image = viewport.get_texture().get_image()
		viewport.queue_free()
	for item: CanvasItem in hidden:
		if not is_instance_valid(item):
			continue
		var area: Interactable = item.get_parent() as Interactable
		# An icon stays hidden while its prompt shows (Interactable.set_focused).
		item.visible = area == null or item is Interactable or not area.is_focused()
	if image == null or image.is_empty():
		return null
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	image.save_png(path)
	return image


## What must not be baked into the picture: the player, NPCs (recruits leave) and floating icons.
static func _transient_items(map: Map) -> Array[CanvasItem]:
	var items: Array[CanvasItem] = []
	if map.player != null:
		items.append(map.player)
	for node: Node in map.find_children("*", "", true, false):
		if node is Npc:
			items.append(node as CanvasItem)
		elif node is Interactable and (node as Interactable).icon != null:
			items.append((node as Interactable).icon)
	return items


## The cached picture of a map (null when there is none).
static func load_picture(map_path: String) -> Texture2D:
	var path: String = picture_path(map_id_of(map_path))
	if not FileAccess.file_exists(path):
		return null
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null
