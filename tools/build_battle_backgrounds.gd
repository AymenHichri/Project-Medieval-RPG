extends SceneTree
## Generates the battle backgrounds for the Phase 5 style check (PROJECT_PLAN.md Phase 5):
##   res://scenes/battle/backgrounds/graveyard_bg.tscn            Gimble's 08_graveyard.png (pixel art,
##       1920×1080, Nearest) + the vendor fog overlay.
##   res://scenes/battle/backgrounds/graveyard_composite_bg.tscn  necropolis ground, wall, trees and
##       headstones (ash palette, painted, same 3/4 angle as the battlers) + night tint + fog.
##   godot --headless --path <project> -s res://tools/build_battle_backgrounds.gd
## The battlers stand on the band y ≈ 620–850 (BattleScene slots). Background contract: a Node2D
## drawn on canvas layer 0 behind the battlers; anything meant to cover them goes on CanvasLayer 1.
## Source of truth for both layouts: edit THIS script and re-run it (it overwrites the scenes).

const OUT_DIR: String = "res://scenes/battle/backgrounds"
const GRAVEYARD_PNG: String = "res://assets/vendor/gimbles/backgrounds/1920x1080/08_graveyard.png"
const ASH: String = "res://assets/vendor/sovdigital/necropolis/ColourVariations/ash"
const TILESET: String = ASH + "/godot/necropolis-free_tileset.tres"
const PROPS: String = "res://scenes/world/props/necropolis/"
const FOG_SHADER: String = "res://assets/vendor/sovdigital/weather/godot/overlay_mix.gdshader"
const FOG_MASK: String = "res://assets/vendor/sovdigital/weather/overlays/fog/fog_mask.png"

const SCREEN: Vector2 = Vector2(1920, 1080)
const TILE: int = 128
## Vendor TileSet: ground source 0 = bone-flags paving; terrain set 1 = transparent ash-soil overlay.
const FLAGS_SOURCE: int = 0
const OVERLAY_TERRAIN_SET: int = 1
const OVERLAY_TERRAIN: int = 0
const PATTERN_TILES: int = 8
## Tile rows left paved (no soil): the band the battlers stand on.
const ARENA_ROWS: Array[int] = [5, 6]
## Night grade of the composite (the Gimble's painting already has its own lighting).
const COMPOSITE_TINT: Color = Color(0.6, 0.63, 0.76)
const FOG_TINT: Color = Color(0.74, 0.78, 0.86, 0.6)
const FOG_STRENGTH: float = 0.55

var _root: Node


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var ok: bool = _save(_build_gimbles(), OUT_DIR + "/graveyard_bg.tscn")
	ok = _save(_build_composite(), OUT_DIR + "/graveyard_composite_bg.tscn") and ok
	print("battle backgrounds %s" % ("written" if ok else "FAILED"))
	quit(0 if ok else 1)


func _build_gimbles() -> Node2D:
	var root: Node2D = _begin("GraveyardBg")
	var backdrop: Sprite2D = _add(Sprite2D.new(), "Backdrop", root) as Sprite2D
	backdrop.texture = load(GRAVEYARD_PNG) as Texture2D
	backdrop.centered = false
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fog(root)
	return root


func _build_composite() -> Node2D:
	var root: Node2D = _begin("GraveyardCompositeBg")
	var tileset: TileSet = load(TILESET) as TileSet
	var tiles: Vector2i = Vector2i(ceili(SCREEN.x / TILE), ceili(SCREEN.y / TILE))
	var ground: TileMapLayer = _add(TileMapLayer.new(), "Ground", root) as TileMapLayer
	ground.tile_set = tileset
	var pattern: TileMapPattern = _pattern_for_source(tileset, FLAGS_SOURCE)
	for y: int in range(0, tiles.y, PATTERN_TILES):
		for x: int in range(0, tiles.x, PATTERN_TILES):
			ground.set_pattern(Vector2i(x, y), pattern)
	var soil: TileMapLayer = _add(TileMapLayer.new(), "Soil", root) as TileMapLayer
	soil.tile_set = tileset
	var cells: Array[Vector2i] = []
	for y: int in tiles.y:
		if y in ARENA_ROWS:
			continue
		for x: int in tiles.x:
			cells.append(Vector2i(x, y))
	soil.set_cells_terrain_connect(cells, OVERLAY_TERRAIN_SET, OVERLAY_TERRAIN)

	var props: Node2D = _add(Node2D.new(), "Props", root) as Node2D
	props.y_sort_enabled = true
	for x: float in [186.0, 558.0, 930.0, 1302.0, 1674.0, 2046.0]:
		_prop(props, "wall_north", Vector2(x, 250))
	_prop(props, "gnarled_tree", Vector2(220, 560))
	_prop(props, "gnarled_tree", Vector2(1740, 540))
	var stones: Array[Array] = [
		["headstone_round", Vector2(520, 470)], ["headstone_cross", Vector2(690, 520)],
		["headstone_round", Vector2(880, 455)], ["headstone_cross", Vector2(1060, 505)],
		["headstone_round", Vector2(1250, 470)], ["headstone_cross", Vector2(1430, 525)],
		["grave_mound", Vector2(610, 575)], ["grave_mound", Vector2(1190, 580)],
		["small_obelisk", Vector2(1000, 400)], ["lantern_post", Vector2(380, 600)],
		["lantern_post", Vector2(1580, 600)], ["dead_stump", Vector2(140, 900)],
	]
	for entry: Array in stones:
		_prop(props, entry[0] as String, entry[1] as Vector2)
	var grade: CanvasModulate = _add(CanvasModulate.new(), "NightGrade", root) as CanvasModulate
	grade.color = COMPOSITE_TINT
	_fog(root)
	return root


# --- helpers ------------------------------------------------------------------------------

func _begin(node_name: String) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = node_name
	_root = root
	return root


func _add(node: Node, node_name: String, parent: Node) -> Node:
	node.name = node_name
	parent.add_child(node)
	node.owner = _root
	return node


func _prop(parent: Node, prop_name: String, base: Vector2) -> void:
	var scene: PackedScene = load(PROPS + prop_name + ".tscn") as PackedScene
	var prop: Node2D = scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node2D
	prop.position = base
	var count: int = parent.get_child_count()
	_add(prop, "%s%d" % [prop_name.to_pascal_case(), count], parent)


## Drifting fog over the battlers (CanvasLayer 1), below the battle UI (layer 10).
func _fog(root: Node) -> void:
	var layer: CanvasLayer = _add(CanvasLayer.new(), "Fog", root) as CanvasLayer
	layer.layer = 1
	var fog: ColorRect = _add(ColorRect.new(), "FogOverlay", layer) as ColorRect
	fog.size = SCREEN
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load(FOG_SHADER) as Shader
	material.set_shader_parameter(&"mask", load(FOG_MASK) as Texture2D)
	material.set_shader_parameter(&"tint", FOG_TINT)
	material.set_shader_parameter(&"tiles", SCREEN / 1024.0)
	material.set_shader_parameter(&"speed", Vector2(0.02, 0.0))
	material.set_shader_parameter(&"strength", FOG_STRENGTH)
	fog.material = material


static func _pattern_for_source(tileset: TileSet, source_id: int) -> TileMapPattern:
	for i: int in tileset.get_patterns_count():
		var pattern: TileMapPattern = tileset.get_pattern(i)
		if pattern.get_cell_source_id(Vector2i.ZERO) == source_id:
			return pattern
	push_error("no ground pattern for source %d" % source_id)
	return tileset.get_pattern(0)


func _save(root: Node, path: String) -> bool:
	var packed: PackedScene = PackedScene.new()
	var err: Error = packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	root.free()
	if err != OK:
		push_error("could not save %s: %s" % [path, error_string(err)])
		return false
	return true
