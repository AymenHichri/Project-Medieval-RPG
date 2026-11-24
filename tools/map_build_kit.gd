class_name MapBuildKit
extends RefCounted
## Shared helpers for the map generator tools (`tools/build_*.gd`): prop scenes built from a
## vendor biome.json, node helpers that set ownership for saving, and the standard map pieces
## (ground, boundary, spawns, transitions, interactables, lights, mood, camera bounds).
## Usage: `var kit := MapBuildKit.new(biome_dir, prop_dir)`, `kit.build_props(ids)`, then
## `kit.begin_map(...)`, add nodes, `kit.save(kit.finish_map(), path)`.

const TILE: int = 128
## Collision layer bit of `world_solid` (project physics layer 1).
const WORLD_SOLID: int = 1
## Ground block patterns are 8×8 tiles.
const PATTERN_TILES: int = 8
## Terrain set 1 of the vendor TileSets = transparent overlay terrain over a ground block.
const OVERLAY_TERRAIN_SET: int = 1
const OVERLAY_TERRAIN: int = 0
## How far (px) the solid house block reaches up from the top of the vendor footprint. The
## player stands behind the roof (hidden) once past this line.
const HOUSE_DEPTH: float = 192.0
## The block overlaps the footprint by this much so there is no seam between the two shapes.
const HOUSE_BLOCK_OVERLAP: float = 8.0
## Keeps the player inside the map (px from the map edge).
const BOUNDARY_MARGIN: float = 40.0

const PLAYER_SCENE: String = "res://scenes/world/player/player.tscn"
const TRANSITION_SCENE: String = "res://scenes/world/components/map_transition.tscn"
const INTERACTABLE_SCENE: String = "res://scenes/world/components/interactable.tscn"
const NPC_SCENE: String = "res://scenes/world/components/npc.tscn"
const REST_POINT_SCENE: String = "res://scenes/world/components/rest_point.tscn"
const RECRUIT_NPC_SCENE: String = "res://scenes/world/components/recruit_npc.tscn"
const SHOP_NPC_SCENE: String = "res://scenes/world/components/shop_npc.tscn"
const CHEST_SCENE: String = "res://scenes/world/components/chest.tscn"
const BOSS_TRIGGER_SCENE: String = "res://scenes/world/components/boss_trigger.tscn"
const ITEM_DIR: String = "res://data/items"
const EQUIPMENT_DIR: String = "res://data/equipment"
const ENCOUNTER_ZONE_SCENE: String = "res://scenes/world/components/encounter_zone.tscn"
const FOG_SHADER: String = "res://assets/vendor/sovdigital/weather/godot/overlay_mix.gdshader"
const FOG_MASK: String = "res://assets/vendor/sovdigital/weather/overlays/fog/fog_mask.png"
const AMBIENCE_SCRIPT: String = "res://addons/sovdigital/ambience/scripts/ambience_controller.gd"
const LIGHT_TEXTURE: String = "res://addons/sovdigital/ambience/textures/lights/light_radial.png"
## SovDigital Ambient Effects pack (extracted by tools/extract_assets.py).
const AMBIENT_FX: String = "res://assets/vendor/sovdigital/effects/ambient/effects"

## Vendor biome folder (holds biome.json and the piece images).
var biome_dir: String
## Where the generated prop scenes are written.
var prop_dir: String
## The map being built (set by `begin_map`).
var root: Map

var _pieces: Dictionary[String, Dictionary] = {}
## Per prop id: how far (px, negative = up) the scene origin sits from the vendor pivot.
var _sort_offsets: Dictionary[String, float] = {}


func _init(p_biome_dir: String, p_prop_dir: String) -> void:
	biome_dir = p_biome_dir
	prop_dir = p_prop_dir
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(biome_dir + "/biome.json")) as Dictionary
	for piece: Variant in data["pieces"] as Array:
		var entry: Dictionary = piece as Dictionary
		_pieces[str(entry["id"])] = entry


# --- props -------------------------------------------------------------------------------

## Builds and saves one prop scene per vendor piece id into `prop_dir`.
func build_props(ids: Array[String]) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(prop_dir))
	for id: String in ids:
		save(build_prop(id), prop_path(id))


func prop_path(id: String) -> String:
	return "%s/%s.tscn" % [prop_dir, id.replace("-", "_")]


## Node2D (origin = base / Y-sort point) → Sprite + Body (StaticBody2D, world_solid) → Footprint.
## Buildings sort at their front wall line, not at the bottom of the image: the image includes
## a cobble apron in front of the house, and sorting at its far edge drew the house over a
## player standing on the apron. The wall line is the top of the vendor footprint, so the
## scene origin (= Y-sort point) moves up there and the children move down by the same amount.
func build_prop(id: String) -> PackedScene:
	var piece: Dictionary = _pieces[id]
	var pivot: Vector2 = _vec(piece["pivot"])
	var is_building: bool = str(piece["category"]) == "buildings" or id == "cottage-smoke"
	var footprint: PackedVector2Array = []
	for point: Variant in piece["footprint"] as Array:
		footprint.append(_vec(point) - pivot)
	var sort_y: float = 0.0
	if is_building:
		sort_y = bounds_of(footprint).position.y
		for i: int in footprint.size():
			footprint[i].y -= sort_y
	_sort_offsets[id] = sort_y
	var prop_root: Node2D = Node2D.new()
	prop_root.name = id.replace("-", "_").to_pascal_case()

	var offset: Vector2 = -pivot - Vector2(0, sort_y)
	if str(piece["category"]) == "animated":
		var animated: AnimatedSprite2D = AnimatedSprite2D.new()
		animated.name = "Sprite"
		animated.sprite_frames = load(biome_dir + "/" + str(piece["godot_spriteframes"])) as SpriteFrames
		animated.animation = &"loop"
		animated.autoplay = "loop"
		animated.centered = false
		animated.offset = offset
		add(prop_root, animated, prop_root)
	else:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = load(biome_dir + "/" + str(piece["file"])) as Texture2D
		sprite.centered = false
		sprite.offset = offset
		add(prop_root, sprite, prop_root)

	if str(piece["collision"]) == "footprint":
		var body: StaticBody2D = StaticBody2D.new()
		body.name = "Body"
		body.collision_layer = WORLD_SOLID
		body.collision_mask = 0
		add(prop_root, body, prop_root)
		var shape: CollisionPolygon2D = CollisionPolygon2D.new()
		shape.name = "Footprint"
		shape.polygon = footprint
		add(body, shape, prop_root)
		if is_building:
			_add_house_block(body, footprint, prop_root)
	return pack(prop_root)


## The vendor footprint is only the ground band at the bottom of a building image, so the
## house walls above it would be walkable from the sides. This adds a solid block over the
## house body: the footprint's width, from its top edge up by HOUSE_DEPTH.
func _add_house_block(body: StaticBody2D, footprint: PackedVector2Array, owner_node: Node) -> void:
	var box: Rect2 = bounds_of(footprint)
	var block: CollisionPolygon2D = CollisionPolygon2D.new()
	block.name = "HouseBlock"
	var top: float = box.position.y - HOUSE_DEPTH
	var bottom: float = box.position.y + HOUSE_BLOCK_OVERLAP
	block.polygon = PackedVector2Array([
		Vector2(box.position.x, top), Vector2(box.end.x, top),
		Vector2(box.end.x, bottom), Vector2(box.position.x, bottom),
	])
	add(body, block, owner_node)


# --- map pieces --------------------------------------------------------------------------

## Starts a new map root.
func begin_map(node_name: String, map_id: StringName, display_name: String, preset: StringName) -> Map:
	root = Map.new()
	root.name = node_name
	root.map_id = map_id
	root.display_name = display_name
	root.ambience_preset = preset
	return root


## The generated MusicTrack `id` (data/audio/music/<id>.tres, written by tools/build_audio.gd);
## null when the audio has not been built.
func music_track(id: StringName) -> MusicTrack:
	var path: String = "res://data/audio/music/%s.tres" % id
	return load(path) as MusicTrack if ResourceLoader.exists(path) else null


## Adds the CameraBounds rect (map size in px) and packs the map.
func finish_map(map_size: Vector2) -> PackedScene:
	var bounds: ReferenceRect = node(ReferenceRect.new(), "CameraBounds", root)
	bounds.unique_name_in_owner = true
	bounds.size = map_size
	bounds.border_color = Color(0.9, 0.3, 0.2)
	bounds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pack(root)


## `Ground` layer filled with the 8×8 ground pattern of `source_id`.
func ground(tileset: TileSet, source_id: int, map_tiles: Vector2i) -> TileMapLayer:
	var layer: TileMapLayer = node(TileMapLayer.new(), "Ground", root)
	layer.tile_set = tileset
	var pattern: TileMapPattern = pattern_for_source(tileset, source_id)
	for y: int in range(0, map_tiles.y, PATTERN_TILES):
		for x: int in range(0, map_tiles.x, PATTERN_TILES):
			layer.set_pattern(Vector2i(x, y), pattern)
	return layer


## `Terrain` layer: the transparent overlay terrain painted on `cells` (blended edges).
func overlay_terrain(tileset: TileSet, cells: Array[Vector2i]) -> TileMapLayer:
	var layer: TileMapLayer = node(TileMapLayer.new(), "Terrain", root)
	layer.tile_set = tileset
	layer.set_cells_terrain_connect(cells, OVERLAY_TERRAIN_SET, OVERLAY_TERRAIN)
	return layer


## `Boundary` body: four world-boundary lines BOUNDARY_MARGIN inside the map edge.
func boundary(map_size: Vector2) -> void:
	var body: StaticBody2D = node(StaticBody2D.new(), "Boundary", root)
	body.collision_layer = WORLD_SOLID
	body.collision_mask = 0
	var edges: Array[Array] = [
		[Vector2(BOUNDARY_MARGIN, 0), Vector2.RIGHT],
		[Vector2(map_size.x - BOUNDARY_MARGIN, 0), Vector2.LEFT],
		[Vector2(0, BOUNDARY_MARGIN), Vector2.DOWN],
		[Vector2(0, map_size.y - BOUNDARY_MARGIN), Vector2.UP],
	]
	var names: Array[String] = ["West", "East", "North", "South"]
	for i: int in edges.size():
		var shape: CollisionShape2D = node(CollisionShape2D.new(), names[i], body)
		var line: WorldBoundaryShape2D = WorldBoundaryShape2D.new()
		line.normal = edges[i][1] as Vector2
		shape.shape = line
		shape.position = edges[i][0] as Vector2


func spawn(parent: Node, node_name: String, spawn_id: StringName, facing: String, at: Vector2) -> SpawnPoint:
	var point: SpawnPoint = node(SpawnPoint.new(), node_name, parent)
	point.spawn_id = spawn_id
	point.facing = facing
	point.position = at
	return point


func player(world: Node2D, at: Vector2) -> void:
	scene(world, PLAYER_SCENE, "Player", at)


## A MapTransition covering `rect` (map px) that leads to `target_spawn` in `target_map`.
func transition(parent: Node, node_name: String, target_map: String, target_spawn: StringName, rect: Rect2) -> MapTransition:
	var exit: MapTransition = scene(parent, TRANSITION_SCENE, node_name, rect.get_center()) as MapTransition
	exit.target_map = target_map
	exit.target_spawn = target_spawn
	exit.size = rect.size
	return exit


## An EncounterZone using the table at `table_path`, outlined by `outline` (map px).
func encounter_zone(parent: Node, node_name: String, table_path: String, outline: PackedVector2Array) -> EncounterZone:
	var zone: EncounterZone = scene(parent, ENCOUNTER_ZONE_SCENE, node_name, Vector2.ZERO) as EncounterZone
	zone.table = load(table_path) as EncounterTable
	zone.polygon = outline
	return zone


## Adds an Interactable to a placed prop. `offset` is from the prop's origin (its base).
func interactable(target: Node2D, prompt: String, dialogue_id: StringName, offset: Vector2 = Vector2.ZERO,
		radius: float = 64.0, prompt_height: float = 170.0) -> Interactable:
	var area: Interactable = (load(INTERACTABLE_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Interactable
	area.name = "Interactable"
	area.position = offset
	area.prompt_text = prompt
	area.dialogue_id = dialogue_id
	area.radius = radius
	area.prompt_offset = Vector2(0, -prompt_height)
	add(target, area, root)
	return area


## A talking NPC standing at `at` (feet), facing `facing`, with an optional portrait and look
## (SpriteFrames; empty = the scene's default).
func npc(world: Node2D, node_name: String, at: Vector2, dialogue_id: StringName, facing: String,
		portrait_path: String = "", frames_path: String = "") -> Npc:
	var person: Npc = scene(world, NPC_SCENE, node_name, at) as Npc
	person.dialogue_id = dialogue_id
	person.facing = facing
	if not portrait_path.is_empty():
		person.portrait = load(portrait_path) as Texture2D
	if not frames_path.is_empty():
		person.sprite_frames = load(frames_path) as SpriteFrames
	return person


## Ties an interactable to a quest (Phase 10): the target of `stage` until `done_flag` is set, or
## (stage -1) the quest's giver.
func quest_target(area: Interactable, quest_path: String, stage: int, done_flag: StringName = &"") -> void:
	area.quest = load(quest_path) as QuestData
	area.quest_stage = stage
	area.quest_done_flag = done_flag


## A fixed boss fight (Phase 10) at `at`: sealed until its encounter's flags are set.
func boss_trigger(world: Node2D, node_name: String, at: Vector2, encounter_path: String, dialogue_id: StringName,
		sealed_dialogue: StringName, after_dialogue: StringName) -> BossTrigger:
	var trigger: BossTrigger = scene(world, BOSS_TRIGGER_SCENE, node_name, at) as BossTrigger
	trigger.encounter = load(encounter_path) as BossEncounter
	trigger.dialogue_id = dialogue_id
	trigger.sealed_dialogue = sealed_dialogue
	trigger.after_dialogue = after_dialogue
	return trigger


## A character who joins the party after its dialogue when `join_if_flag` is set (Phase 8).
## Its sprite and portrait come from the character data.
func recruit(world: Node2D, node_name: String, at: Vector2, dialogue_id: StringName, facing: String,
		character_path: String, joined_flag: StringName, join_if_flag: StringName) -> RecruitNpc:
	var person: RecruitNpc = scene(world, RECRUIT_NPC_SCENE, node_name, at) as RecruitNpc
	person.dialogue_id = dialogue_id
	person.facing = facing
	person.character = load(character_path) as CharacterData
	person.joined_flag = joined_flag
	person.join_if_flag = join_if_flag
	return person


## A merchant who opens the shop after its greeting (Phase 9). `stock`: item / equipment ids.
func merchant(world: Node2D, node_name: String, at: Vector2, dialogue_id: StringName, facing: String,
		stock: Array[StringName]) -> ShopNpc:
	var person: ShopNpc = scene(world, SHOP_NPC_SCENE, node_name, at) as ShopNpc
	person.dialogue_id = dialogue_id
	person.facing = facing
	var items: Array[ItemData] = []
	for id: StringName in stock:
		items.append(item(id))
	person.stock = items
	return person


## A chest opened once (Phase 9): `item_id` × `count` (empty id = gold only), remembered by `flag`.
func chest(world: Node2D, node_name: String, at: Vector2, item_id: StringName, count: int, flag: StringName,
		gold: int = 0) -> Chest:
	var box: Chest = scene(world, CHEST_SCENE, node_name, at) as Chest
	if not item_id.is_empty():
		box.item = item(item_id)
	box.count = count
	box.gold = gold
	box.opened_flag = flag
	return box


## An item or equipment resource by id.
func item(id: StringName) -> ItemData:
	for dir: String in [ITEM_DIR, EQUIPMENT_DIR]:
		var path: String = dir.path_join(String(id) + ".tres")
		if ResourceLoader.exists(path):
			return load(path) as ItemData
	push_error("MapBuildKit: unknown item " + String(id))
	return null


## Adds a RestPoint (full heal + its dialogue) to a placed prop.
func rest_point(target: Node2D, offset: Vector2 = Vector2.ZERO, radius: float = 64.0,
		prompt_height: float = 170.0) -> RestPoint:
	var area: RestPoint = (load(REST_POINT_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as RestPoint
	area.name = "RestPoint"
	area.position = offset
	area.radius = radius
	area.prompt_offset = Vector2(0, -prompt_height)
	add(target, area, root)
	return area


## A looping ambient effect (Ambient Effects pack: ember_swirl, smoke_column, dust_swirl, steam_vent,
## toxic_gas, ...) as a child of `target`, centred at `offset` from its origin.
func ambient_fx(target: Node2D, node_name: String, effect: String, offset: Vector2, scale: float = 1.0,
		tint: Color = Color.WHITE) -> AnimatedSprite2D:
	var fx: AnimatedSprite2D = node(AnimatedSprite2D.new(), node_name, target)
	fx.sprite_frames = load("%s/%s/godot/%s_spriteframes.tres" % [AMBIENT_FX, effect, effect]) as SpriteFrames
	fx.animation = &"effect"
	fx.autoplay = "effect"
	fx.position = offset
	fx.scale = Vector2(scale, scale)
	fx.modulate = tint
	return fx


## `Lights` node with one warm PointLight2D per entry.
func lights(lamps: Dictionary[String, Vector2], color: Color, scale: float = 2.5, energy: float = 1.1) -> Node2D:
	var parent: Node2D = node(Node2D.new(), "Lights", root)
	var texture: Texture2D = load(LIGHT_TEXTURE) as Texture2D
	for lamp_name: String in lamps:
		var light: PointLight2D = node(PointLight2D.new(), lamp_name, parent)
		light.texture = texture
		light.texture_scale = scale
		light.energy = energy
		light.color = color
		light.position = lamps[lamp_name]
	return parent


## CanvasModulate + vendor ambience controller (`preset`) + a drifting fog overlay.
func mood(preset: String, fog_tint: Color, fog_strength: float) -> void:
	node(CanvasModulate.new(), "CanvasModulate", root)
	var ambience: Node = node(Node.new(), "Ambience", root)
	ambience.set_script(load(AMBIENCE_SCRIPT))
	ambience.set(&"preset", preset)

	var fog_layer: CanvasLayer = node(CanvasLayer.new(), "Fog", root)
	fog_layer.layer = 2
	var fog: ColorRect = node(ColorRect.new(), "FogOverlay", fog_layer)
	fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load(FOG_SHADER) as Shader
	material.set_shader_parameter(&"mask", load(FOG_MASK) as Texture2D)
	material.set_shader_parameter(&"tint", fog_tint)
	material.set_shader_parameter(&"tiles", Vector2(1920.0 / 1024.0, 1080.0 / 1024.0))
	material.set_shader_parameter(&"speed", Vector2(0.02, 0.0))
	material.set_shader_parameter(&"strength", fog_strength)
	fog.material = material


# --- helpers -----------------------------------------------------------------------------

## Places a generated prop by its vendor base point (the bottom of the image), whatever its
## sort offset. The prop must have been built by `build_props` in this run.
func prop(parent: Node, id: String, node_name: String, base: Vector2) -> Node2D:
	return scene(parent, prop_path(id), node_name, base + Vector2(0, _sort_offsets[id]))


func scene(parent: Node, path: String, node_name: String, at: Vector2) -> Node2D:
	var instance: Node2D = (load(path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	instance.name = node_name
	instance.position = at
	add(parent, instance, root)
	return instance


func decal(parent: Node, node_name: String, file: String, center: Vector2) -> void:
	var sprite: Sprite2D = node(Sprite2D.new(), node_name, parent)
	sprite.texture = load("%s/decals/%s.png" % [biome_dir, file]) as Texture2D
	sprite.position = center


## Names a new node, adds it under `parent` and makes the map root its owner.
func node(new_node: Node, node_name: String, parent: Node) -> Variant:
	new_node.name = node_name
	add(parent, new_node, root)
	return new_node


func add(parent: Node, child: Node, owner_node: Node) -> void:
	parent.add_child(child)
	child.owner = owner_node


func pattern_for_source(tileset: TileSet, source_id: int) -> TileMapPattern:
	for i: int in tileset.get_patterns_count():
		var pattern: TileMapPattern = tileset.get_pattern(i)
		if pattern.get_cell_source_id(Vector2i.ZERO) == source_id:
			return pattern
	push_error("no ground pattern for source %d" % source_id)
	return tileset.get_pattern(0)


func bounds_of(points: PackedVector2Array) -> Rect2:
	var box: Rect2 = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		box = box.expand(point)
	return box


func size(id: String) -> Vector2:
	return _vec(_pieces[id]["size_px"])


func pivot(id: String) -> Vector2:
	return _vec(_pieces[id]["pivot"])


func _vec(value: Variant) -> Vector2:
	var pair: Array = value as Array
	return Vector2(float(pair[0]), float(pair[1]))


func pack(scene_root: Node) -> PackedScene:
	var packed: PackedScene = PackedScene.new()
	var error: Error = packed.pack(scene_root)
	if error != OK:
		push_error("could not pack %s: %s" % [scene_root.name, error_string(error)])
	scene_root.free()
	return packed


func save(resource: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var error: Error = ResourceSaver.save(resource, path)
	if error != OK:
		push_error("could not save %s: %s" % [path, error_string(error)])
