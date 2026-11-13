extends TestCase
## Every map exit leads somewhere real, and no spawn point sits inside an exit trigger (which
## would bounce the player straight back: the "double-trigger loop").
## Maps are inspected as instances outside the tree (no _ready): several maps in the tree at
## once would overlap at the origin and their navigation meshes would clash.

const MAPS_DIR: String = "res://scenes/world/maps"
## Extra margin (px) around each trigger: the player's feet collider reaches this far.
const PLAYER_REACH: float = 48.0

var _maps: Array[Map] = []


func after_each() -> void:
	for map: Map in _maps:
		map.free()
	_maps.clear()


func test_every_map_has_spawns_and_exits() -> void:
	for path: String in _map_paths():
		var map: Map = _instance(path)
		assert_false(map.get_spawns().is_empty(), "%s has a spawn point" % path)
		assert_false(_transitions(map).is_empty(), "%s has an exit" % path)


func test_exits_lead_to_existing_spawns() -> void:
	for path: String in _map_paths():
		for exit: MapTransition in _transitions(_instance(path)):
			var where: String = "%s/%s" % [path.get_file(), exit.name]
			assert_true(ResourceLoader.exists(exit.target_map), "%s: target map %s exists" % [where, exit.target_map])
			if not ResourceLoader.exists(exit.target_map):
				continue
			var ids: Array[StringName] = []
			for spawn: SpawnPoint in _instance(exit.target_map).get_spawns():
				ids.append(spawn.spawn_id)
			assert_true(exit.target_spawn in ids, "%s: %s has spawn '%s' (has %s)" % [where, exit.target_map, exit.target_spawn, ids])


func test_no_spawn_inside_an_exit() -> void:
	for path: String in _map_paths():
		var map: Map = _instance(path)
		for exit: MapTransition in _transitions(map):
			var zone: Rect2 = _exit_rect(exit, map).grow(PLAYER_REACH)
			for spawn: SpawnPoint in map.get_spawns():
				assert_false(zone.has_point(_position_in(spawn, map)),
					"%s: spawn '%s' is inside exit %s" % [path.get_file(), spawn.spawn_id, exit.name])


func test_exits_are_reachable_inside_the_boundary() -> void:
	# The trigger must reach into the walkable area, or the player can never touch it.
	for path: String in _map_paths():
		var map: Map = _instance(path)
		var bounds: ReferenceRect = map.get_node(^"CameraBounds") as ReferenceRect
		var walkable: Rect2 = Rect2(_position_in(bounds, map), bounds.size).grow(-MapBuildKit.BOUNDARY_MARGIN)
		for exit: MapTransition in _transitions(map):
			assert_true(walkable.intersects(_exit_rect(exit, map)),
				"%s: exit %s overlaps the walkable area" % [path.get_file(), exit.name])


func _map_paths() -> Array[String]:
	var paths: Array[String] = []
	for file_name: String in DirAccess.get_files_at(MAPS_DIR):
		if file_name.ends_with(".tscn"):
			paths.append(MAPS_DIR.path_join(file_name))
	paths.sort()
	assert_true(paths.size() >= 2, "at least two maps")
	return paths


func _instance(path: String) -> Map:
	var map: Map = (load(path) as PackedScene).instantiate() as Map
	_maps.append(map)
	return map


func _transitions(map: Map) -> Array[MapTransition]:
	var result: Array[MapTransition] = []
	for node: Node in map.find_children("*", "Area2D", true, false):
		if node is MapTransition:
			result.append(node as MapTransition)
	return result


func _exit_rect(exit: MapTransition, map: Map) -> Rect2:
	return Rect2(_position_in(exit, map) - exit.size / 2.0, exit.size)


## Position of a node in map coordinates, computed from the parent chain (works outside the tree).
func _position_in(node: CanvasItem, map: Map) -> Vector2:
	var transform: Transform2D = node.get_transform()
	var parent: Node = node.get_parent()
	while parent != null and parent != map:
		var item: CanvasItem = parent as CanvasItem
		if item != null:
			transform = item.get_transform() * transform
		parent = parent.get_parent()
	return transform.origin
