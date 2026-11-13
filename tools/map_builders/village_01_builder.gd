extends RefCounted
## Builds the village exploration map and the village prop scenes it uses.
## Run through the launcher: godot --headless --path <project> -s res://tools/build_maps.gd -- village_01
## Writes:
##   res://scenes/world/props/village/<piece>.tscn   one scene per static village piece (ash palette),
##       built from the vendor biome.json by MapBuildKit.
##   res://scenes/world/maps/village_01.tscn         the map (PROJECT_PLAN.md §6.1 template).
## Source of truth for the layout: edit THIS script, then re-run it. If the map is later
## edited by hand in the editor, stop re-running this script (it would overwrite the edits).

const ASH: String = "res://assets/vendor/sovdigital/village/ColourVariations/ash"
const TILESET_PATH: String = ASH + "/godot/medieval-village-free_tileset.tres"
const PROP_DIR: String = "res://scenes/world/props/village"
const MAP_PATH: String = "res://scenes/world/maps/village_01.tscn"
const GRAVEYARD_PATH: String = "res://scenes/world/maps/graveyard_01.tscn"

const TILE: int = MapBuildKit.TILE
## Map size in tiles (32×24 = 4096×3072 px).
const MAP_TILES: Vector2i = Vector2i(32, 24)
## The south fence line; its gap over the street is the exit to the graveyard.
const FENCE_Y: float = 3000.0

## Static pieces turned into prop scenes (vendor biome.json ids).
const PROP_IDS: Array[String] = [
	"wall-north", "wall-corner-nw", "wall-corner-ne", "picket-fence",
	"cottage", "cottage-smoke", "cottage-e", "cottage-w", "cottage-damaged", "cottage-ruined", "cottage-stage-2",
	"market-stall", "notice-board", "bird-bath", "public-bench", "rain-barrel", "flower-planter",
	"laundry-line",
]

## Vendor scene tiles (origin = base point), used as-is.
const OAK_SWAY: String = ASH + "/animated/oak-tree-sway/godot/oak-tree-sway.tscn"
const OAK_STILL: String = ASH + "/destructibles/oak-tree/godot/oak-tree.tscn"
const APPLE_CART: String = ASH + "/destructibles/apple-cart/godot/apple-cart.tscn"

var _kit: MapBuildKit


func build() -> void:
	_kit = MapBuildKit.new(ASH, PROP_DIR)
	_kit.build_props(PROP_IDS)
	_kit.save(_build_map(), MAP_PATH)
	print("built %d props and %s" % [PROP_IDS.size(), MAP_PATH])


func _build_map() -> PackedScene:
	var root: Map = _kit.begin_map("Village01", &"village_01", "Hollow Border Village", &"dusk")
	var tileset: TileSet = load(TILESET_PATH) as TileSet
	_kit.ground(tileset, 0, MAP_TILES)
	_build_streets(tileset)
	_build_decals()
	var world: Node2D = _kit.node(Node2D.new(), "World", root)
	world.y_sort_enabled = true
	_build_walls(world)
	_build_buildings(world)
	_build_props(world)
	_build_trees(world)
	_kit.boundary(Vector2(MAP_TILES * TILE))
	_build_spawns_and_exits(world)
	_build_mood()
	return _kit.finish_map(Vector2(MAP_TILES * TILE))


func _build_streets(tileset: TileSet) -> void:
	# Mud streets: a cross through the village square, drawn as the transparent mud overlay.
	var street: Array[Vector2i] = []
	for x: int in MAP_TILES.x:
		for y: int in [13, 14]:
			street.append(Vector2i(x, y))
	for y: int in range(4, MAP_TILES.y):
		for x: int in [15, 16]:
			street.append(Vector2i(x, y))
	for y: int in range(11, 17):  # village square
		for x: int in range(13, 19):
			street.append(Vector2i(x, y))
	# The overlay keeps the seamless grass block visible; the opaque corner set (0) shows a
	# tile grid on the grass and its navigation polygons overlap, so it is not used here.
	_kit.overlay_terrain(tileset, street)


func _build_decals() -> void:
	var decals: Node2D = _kit.node(Node2D.new(), "Decals", _kit.root)
	_kit.decal(decals, "CartRutsNorth", "cart-ruts", Vector2(2048, 1000))
	_kit.decal(decals, "CartRutsSouth", "cart-ruts", Vector2(2048, 2500))
	_kit.decal(decals, "StrawByStall", "straw", Vector2(2500, 1700))
	_kit.decal(decals, "StrawByCottage", "straw", Vector2(1400, 1450))


func _build_walls(world: Node2D) -> void:
	# North wall run: straight `wall-north` pieces end to end, a corner at each end.
	const RUN_LEFT: float = 640.0
	const RUN_PIECES: int = 7
	const BASE_Y: float = 448.0
	var width: float = _kit.size("wall-north").x
	for i: int in RUN_PIECES:
		var x: float = RUN_LEFT + i * width + _kit.pivot("wall-north").x
		_kit.prop(world, "wall-north", "WallNorth%d" % (i + 1), Vector2(x, BASE_Y))
	var run_right: float = RUN_LEFT + RUN_PIECES * width
	var nw_x: float = RUN_LEFT - (_kit.size("wall-corner-nw").x - _kit.pivot("wall-corner-nw").x)
	_kit.prop(world, "wall-corner-nw", "WallCornerNW", Vector2(nw_x, BASE_Y))
	_kit.prop(world, "wall-corner-ne", "WallCornerNE", Vector2(run_right + _kit.pivot("wall-corner-ne").x, BASE_Y))

	# South picket fence with a gap where the street leaves the village (exit to the graveyard).
	var fence_width: float = _kit.size("picket-fence").x
	for i: int in 4:
		var west_x: float = 160.0 + i * fence_width + _kit.pivot("picket-fence").x
		var east_x: float = 2400.0 + i * fence_width + _kit.pivot("picket-fence").x
		_kit.prop(world, "picket-fence", "FenceWest%d" % (i + 1), Vector2(west_x, FENCE_Y))
		_kit.prop(world, "picket-fence", "FenceEast%d" % (i + 1), Vector2(east_x, FENCE_Y))


func _build_buildings(world: Node2D) -> void:
	_kit.prop(world, "cottage-smoke", "CottageSmoke", Vector2(1150, 1400))
	_kit.prop(world, "cottage-e", "CottageEast", Vector2(420, 1300))
	_kit.prop(world, "cottage", "Cottage", Vector2(2700, 1400))
	_kit.prop(world, "cottage-w", "CottageWest", Vector2(3500, 1350))
	_kit.prop(world, "cottage-damaged", "CottageDamaged", Vector2(900, 2700))
	_kit.prop(world, "cottage-ruined", "CottageRuined", Vector2(2800, 2700))
	_kit.prop(world, "cottage-stage-2", "CottageRebuilt", Vector2(3560, 2760))


func _build_props(world: Node2D) -> void:
	var board: Node2D = _kit.prop(world, "notice-board", "NoticeBoard", Vector2(1720, 1600))
	_kit.interactable(board, "Read", &"examine_notice_board", Vector2(0, 10), 72.0, 200.0)
	_kit.prop(world, "market-stall", "MarketStall", Vector2(2420, 1620))
	_kit.scene(world, APPLE_CART, "AppleCart", Vector2(2700, 1650))
	_kit.prop(world, "bird-bath", "BirdBath", Vector2(1660, 2150))
	_kit.prop(world, "public-bench", "PublicBench", Vector2(2460, 2160))
	_kit.prop(world, "rain-barrel", "RainBarrelWest", Vector2(1500, 1380))
	_kit.prop(world, "rain-barrel", "RainBarrelEast", Vector2(3790, 1340))
	_kit.prop(world, "flower-planter", "FlowerPlanter", Vector2(860, 1480))
	_kit.prop(world, "laundry-line", "LaundryLine", Vector2(1480, 2560))


func _build_trees(world: Node2D) -> void:
	var sway: Array[Vector2] = [
		Vector2(170, 640), Vector2(3930, 660), Vector2(150, 2020), Vector2(3950, 2080),
		Vector2(1450, 900), Vector2(600, 2250),
	]
	for i: int in sway.size():
		_kit.scene(world, OAK_SWAY, "OakTree%d" % (i + 1), sway[i])
	_kit.scene(world, OAK_STILL, "OakTreeStill", Vector2(3050, 2250))


## Spawns: `start` (first, the fallback) and `from_graveyard`, which sits up the street from
## the south exit, clear of its trigger, facing away from the gate.
func _build_spawns_and_exits(world: Node2D) -> void:
	var spawns: Node2D = _kit.node(Node2D.new(), "Spawns", _kit.root)
	var start: SpawnPoint = _kit.spawn(spawns, "Start", &"start", "S", Vector2(2048, 1820))
	_kit.spawn(spawns, "FromGraveyard", &"from_graveyard", "N", Vector2(2048, 2760))
	_kit.player(world, start.position)

	var transitions: Node2D = _kit.node(Node2D.new(), "Transitions", _kit.root)
	# The fence gap (x 1696–2400) down to past the south boundary line.
	_kit.transition(transitions, "ToGraveyard", GRAVEYARD_PATH, &"from_village",
		Rect2(1696, FENCE_Y - 50.0, 704, 120))


func _build_mood() -> void:
	var lamps: Dictionary[String, Vector2] = {
		"CottageSmokeWindow": Vector2(1150, 1330), "CottageWindow": Vector2(2700, 1330),
		"MarketLamp": Vector2(2420, 1560), "CottageDamagedWindow": Vector2(900, 2640),
		"NoticeBoardLamp": Vector2(1720, 1560),
	}
	_kit.lights(lamps, Color(1.0, 0.72, 0.42))
	_kit.mood("dusk", Color(0.80, 0.82, 0.86, 0.55), 0.6)
