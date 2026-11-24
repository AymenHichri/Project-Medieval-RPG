extends RefCounted
## Builds the graveyard exploration map and the necropolis prop scenes it uses.
## Run through the launcher: godot --headless --path <project> -s res://tools/build_maps.gd -- graveyard_01
## Writes:
##   res://scenes/world/props/necropolis/<piece>.tscn   one scene per static necropolis piece (ash
##       palette), built from the vendor biome.json by MapBuildKit.
##   res://scenes/world/maps/graveyard_01.tscn           the map (PROJECT_PLAN.md §6.1 template).
## Layout: the gate and the exit to the village are at the south; a flagstone path runs north
## between two grave fields to a plaza in front of the crypt, with the bone pyre at its west side.
## Source of truth for the layout: edit THIS script, then re-run it (it overwrites the scene).

const ASH: String = "res://assets/vendor/sovdigital/necropolis/ColourVariations/ash"
const TILESET_PATH: String = ASH + "/godot/necropolis-free_tileset.tres"
const PROP_DIR: String = "res://scenes/world/props/necropolis"
const MAP_PATH: String = "res://scenes/world/maps/graveyard_01.tscn"
const VILLAGE_PATH: String = "res://scenes/world/maps/village_01.tscn"
const ENCOUNTERS_PATH: String = "res://data/encounters/graveyard_outskirts.tres"
## Phase 10: the example quest, its three graves and the boss behind the crypt door.
const QUEST_PATH: String = "res://data/quests/silence_in_the_graveyard.tres"
const BOSS_PATH: String = "res://data/bosses/blade_assassin.tres"

const TILE: int = MapBuildKit.TILE
## Map size in tiles (24×20 = 3072×2560 px).
const MAP_TILES: Vector2i = Vector2i(24, 20)
## Ground sources of the vendor TileSet: 0 = bone-flags (paving), 1 = ash-soil.
const FLAGS_SOURCE: int = 0
## Flagstone path columns (tiles) and the plaza in front of the crypt (tile rect).
const PATH_COLUMNS: Array[int] = [11, 12]
const PLAZA: Rect2i = Rect2i(8, 4, 8, 4)
## The south iron fence line; its gap over the path is the gate to the village.
const FENCE_Y: float = 2380.0
const GATE_LEFT: float = 1344.0
const GATE_RIGHT: float = 1744.0

## Static pieces turned into prop scenes (vendor biome.json ids).
const PROP_IDS: Array[String] = [
	"wall-north", "wall-corner-nw", "wall-corner-ne", "crypt-barracks", "iron-fence",
	"headstone-cross", "headstone-round", "grave-mound", "gargoyle-plinth", "lantern-post",
	"small-obelisk", "dead-stump", "gnarled-tree", "burial-cart",
]

## Vendor scene tiles (origin = base point), used as-is.
const PYRE: String = ASH + "/animated/bone-pyre-lit/godot/bone-pyre-lit.tscn"
const TREE_SWAY: String = ASH + "/animated/gnarled-tree-sway/godot/gnarled-tree-sway.tscn"
const SARCOPHAGUS: String = ASH + "/destructibles/sarcophagus/godot/sarcophagus.tscn"
const BONE_PILE: String = ASH + "/destructibles/bone-pile/godot/bone-pile.tscn"

var _kit: MapBuildKit


func build() -> void:
	_kit = MapBuildKit.new(ASH, PROP_DIR)
	_kit.build_props(PROP_IDS)
	_kit.save(_build_map(), MAP_PATH)
	print("built %d props and %s" % [PROP_IDS.size(), MAP_PATH])


func _build_map() -> PackedScene:
	var root: Map = _kit.begin_map("Graveyard01", &"graveyard_01", "Old Graveyard", &"night")
	root.music = _kit.music_track(&"mus_dungeon_graveyard")
	var tileset: TileSet = load(TILESET_PATH) as TileSet
	_kit.ground(tileset, FLAGS_SOURCE, MAP_TILES)
	_build_soil(tileset)
	_build_decals()
	var world: Node2D = _kit.node(Node2D.new(), "World", root)
	world.y_sort_enabled = true
	_build_walls_and_crypt(world)
	_build_fence(world)
	_build_graves(world)
	_build_setpieces(world)
	_kit.boundary(Vector2(MAP_TILES * TILE))
	_build_spawns_and_exits(world)
	_build_encounter_zones()
	_build_mood()
	return _kit.finish_map(Vector2(MAP_TILES * TILE))


## Ash soil everywhere except the flagstone path and plaza (the paving is the ground block).
func _build_soil(tileset: TileSet) -> void:
	var soil: Array[Vector2i] = []
	for y: int in MAP_TILES.y:
		for x: int in MAP_TILES.x:
			var cell: Vector2i = Vector2i(x, y)
			var on_path: bool = x in PATH_COLUMNS and y >= PLAZA.position.y
			if not on_path and not PLAZA.has_point(cell):
				soil.append(cell)
	_kit.overlay_terrain(tileset, soil)


func _build_decals() -> void:
	var decals: Node2D = _kit.node(Node2D.new(), "Decals", _kit.root)
	_kit.decal(decals, "BoneDustPyre", "bone-dust", Vector2(1180, 920))
	_kit.decal(decals, "BoneDustCrypt", "bone-dust", Vector2(1700, 760))
	_kit.decal(decals, "GraveSoilWest", "grave-soil", Vector2(740, 1600))
	_kit.decal(decals, "GraveSoilEast", "grave-soil", Vector2(2310, 1900))
	_kit.decal(decals, "GraveSoilFresh", "grave-soil", Vector2(1250, 1560))


func _build_walls_and_crypt(world: Node2D) -> void:
	# A wall run on each side of the crypt, closed by a corner at the outer end.
	const BASE_Y: float = 420.0
	var width: float = _kit.size("wall-north").x
	var pivot_x: float = _kit.pivot("wall-north").x
	for i: int in 2:
		_kit.prop(world, "wall-north", "WallWest%d" % (i + 1), Vector2(320.0 + i * width + pivot_x, BASE_Y))
		_kit.prop(world, "wall-north", "WallEast%d" % (i + 1), Vector2(1984.0 + i * width + pivot_x, BASE_Y))
	var nw_x: float = 320.0 - (_kit.size("wall-corner-nw").x - _kit.pivot("wall-corner-nw").x)
	_kit.prop(world, "wall-corner-nw", "WallCornerNW", Vector2(nw_x, BASE_Y))
	_kit.prop(world, "wall-corner-ne", "WallCornerNE", Vector2(1984.0 + 2 * width + _kit.pivot("wall-corner-ne").x, BASE_Y))

	_kit.prop(world, "crypt-barracks", "Crypt", Vector2(1536, 560))
	_kit.prop(world, "gargoyle-plinth", "GargoyleWest", Vector2(1290, 700))
	_kit.prop(world, "gargoyle-plinth", "GargoyleEast", Vector2(1782, 700))


## Iron fence along the south edge with the gate gap over the path.
func _build_fence(world: Node2D) -> void:
	var width: float = _kit.size("iron-fence").x
	var pivot_x: float = _kit.pivot("iron-fence").x
	var west_count: int = floori((GATE_LEFT - 96.0) / width)
	for i: int in west_count:
		var x: float = GATE_LEFT - (i + 1) * width + pivot_x
		_kit.prop(world, "iron-fence", "FenceWest%d" % (i + 1), Vector2(x, FENCE_Y))
	var east_count: int = floori((MAP_TILES.x * TILE - 96.0 - GATE_RIGHT) / width)
	for i: int in east_count:
		var x: float = GATE_RIGHT + i * width + pivot_x
		_kit.prop(world, "iron-fence", "FenceEast%d" % (i + 1), Vector2(x, FENCE_Y))


## Two grave fields either side of the path: rows of headstones and mounds with a fixed jitter.
func _build_graves(world: Node2D) -> void:
	const KINDS: Array[String] = ["headstone-cross", "headstone-round", "grave-mound", "headstone-round"]
	const ROWS: Array[float] = [1150.0, 1450.0, 1750.0, 2050.0]
	const WEST_COLUMNS: Array[float] = [400.0, 580.0, 760.0, 940.0]
	const EAST_COLUMNS: Array[float] = [2130.0, 2310.0, 2490.0, 2670.0]
	var count: int = 0
	for row: int in ROWS.size():
		for column: int in WEST_COLUMNS.size():
			for side: int in 2:
				var x: float = WEST_COLUMNS[column] if side == 0 else EAST_COLUMNS[column]
				# Gaps for the burial cart and a little irregularity.
				if (row + column + side) % 5 == 4:
					continue
				var jitter: Vector2 = Vector2(((count * 37) % 41) - 20, ((count * 53) % 31) - 15)
				var kind: String = KINDS[(row + column * 3 + side) % KINDS.size()]
				count += 1
				var grave: Node2D = _kit.prop(world, kind, "Grave%02d" % count, Vector2(x, ROWS[row]) + jitter)
				# Phase 10: the old soldier's grave (west field) and the fresh mound (east field).
				if count == 12:
					var soldier: Interactable = _kit.interactable(grave, "Examine", &"examine_grave_soldier", Vector2(0, 8), 60.0, 150.0)
					_kit.quest_target(soldier, QUEST_PATH, 0, &"grave_soldier_searched")
				elif count == 23:
					var fresh: Interactable = _kit.interactable(grave, "Examine", &"examine_grave_fresh", Vector2(0, 8), 72.0, 120.0)
					_kit.quest_target(fresh, QUEST_PATH, 0, &"grave_fresh_searched")

	# The one that can be examined from the start: by the path, on the west side (the widow's grave).
	var headstone: Node2D = _kit.prop(world, "headstone-round", "HeadstoneWeathered", Vector2(1250, 1500))
	var widow: Interactable = _kit.interactable(headstone, "Examine", &"examine_headstone", Vector2(0, 8), 60.0, 150.0)
	_kit.quest_target(widow, QUEST_PATH, 0, &"grave_widow_searched")


func _build_setpieces(world: Node2D) -> void:
	var pyre: Node2D = _kit.scene(world, PYRE, "BonePyre", Vector2(1150, 900))
	# Phase 7 assets: smoke rising from the pyre and embers swirling over its flames.
	_kit.ambient_fx(pyre, "Smoke", "smoke_column", Vector2(0, -360), 0.85, Color(1, 1, 1, 0.85))
	_kit.ambient_fx(pyre, "Embers", "ember_swirl", Vector2(0, -190), 0.6)
	_kit.interactable(pyre, "Examine", &"examine_bone_pyre", Vector2(0, 8), 80.0, 230.0)
	var sarcophagus: Node2D = _kit.scene(world, SARCOPHAGUS, "Sarcophagus", Vector2(1850, 1250))
	_kit.interactable(sarcophagus, "Examine", &"examine_sarcophagus", Vector2(0, 8), 72.0, 140.0)

	_kit.prop(world, "lantern-post", "LanternWest1", Vector2(1350, 1300))
	_kit.prop(world, "lantern-post", "LanternEast", Vector2(1722, 1700))
	_kit.prop(world, "lantern-post", "LanternWest2", Vector2(1350, 2150))
	_kit.prop(world, "small-obelisk", "Obelisk", Vector2(2400, 900))
	_kit.prop(world, "dead-stump", "DeadStump", Vector2(700, 880))
	_kit.prop(world, "burial-cart", "BurialCart", Vector2(1960, 2200))
	_kit.scene(world, BONE_PILE, "BonePile", Vector2(2120, 820))
	# Phase 8: the Hexblade studies the crypt ward at the far end of the graveyard, and joins when asked.
	_kit.recruit(world, "Hexblade", Vector2(1700, 920), &"hexblade_meet", "SW", "res://data/characters/hexblade.tres",
			&"hexblade_joined", &"hexblade_agreed")
	# Phase 9: two supply crates left by the gravediggers.
	_kit.chest(world, "ChestSoulGem", Vector2(2620, 960), &"soul_gem", 1, &"chest_graveyard_soul_gem")
	_kit.chest(world, "ChestCoins", Vector2(2300, 2260), &"gold_coins", 2, &"chest_graveyard_coins")
	# Phase 10: a crate the Skull Key (from the fresh grave) opens, and the boss behind the crypt door.
	var crypt_chest: Chest = _kit.chest(world, "ChestCrypt", Vector2(1900, 640), &"pilgrims_chalice", 1, &"chest_graveyard_crypt")
	crypt_chest.required_key = _kit.item(&"skull_key")
	var door: BossTrigger = _kit.boss_trigger(world, "CryptDoor", Vector2(1536, 600), BOSS_PATH, &"crypt_door_open",
			&"crypt_door_sealed", &"crypt_door_silent")
	_kit.quest_target(door, QUEST_PATH, 1, &"blade_assassin_defeated")

	var trees: Array[Vector2] = [Vector2(240, 820), Vector2(2860, 880), Vector2(260, 2240), Vector2(2830, 2230)]
	for i: int in trees.size():
		_kit.scene(world, TREE_SWAY, "GnarledTree%d" % (i + 1), trees[i])
	_kit.prop(world, "gnarled-tree", "GnarledTreeStill", Vector2(2200, 1420))


## One entry from the village: `from_village`, up the path from the gate, clear of the exit
## trigger, facing away from the gate.
func _build_spawns_and_exits(world: Node2D) -> void:
	var spawns: Node2D = _kit.node(Node2D.new(), "Spawns", _kit.root)
	var entry: SpawnPoint = _kit.spawn(spawns, "FromVillage", &"from_village", "N", Vector2(1536, 2240))
	_kit.player(world, entry.position)

	var transitions: Node2D = _kit.node(Node2D.new(), "Transitions", _kit.root)
	_kit.transition(transitions, "ToVillage", VILLAGE_PATH, &"from_graveyard",
		Rect2(GATE_LEFT, FENCE_Y + 60.0, GATE_RIGHT - GATE_LEFT, 140))


## Random encounters on the whole walkable ground inside the boundary, from the crypt wall down to
## the fence. The grace steps after arriving keep the gate itself quiet.
func _build_encounter_zones() -> void:
	var encounters: Node2D = _kit.node(Node2D.new(), "Encounters", _kit.root)
	var margin: float = MapBuildKit.BOUNDARY_MARGIN
	var right: float = MAP_TILES.x * TILE - margin
	_kit.encounter_zone(encounters, "GraveyardOutskirts", ENCOUNTERS_PATH, PackedVector2Array([
		Vector2(margin, 420.0), Vector2(right, 420.0),
		Vector2(right, FENCE_Y + 40.0), Vector2(margin, FENCE_Y + 40.0),
	]))


func _build_mood() -> void:
	var lamps: Dictionary[String, Vector2] = {
		"LanternWest1": Vector2(1350, 1150), "LanternEast": Vector2(1722, 1550),
		"LanternWest2": Vector2(1350, 2000),
	}
	_kit.lights(lamps, Color(1.0, 0.75, 0.45), 2.2, 1.0)
	var pyre_light: PointLight2D = _kit.node(PointLight2D.new(), "PyreLight", _kit.root.get_node(^"Lights"))
	pyre_light.texture = load(MapBuildKit.LIGHT_TEXTURE) as Texture2D
	pyre_light.texture_scale = 3.5
	pyre_light.energy = 1.5
	pyre_light.color = Color(1.0, 0.55, 0.28)
	pyre_light.position = Vector2(1150, 820)
	_kit.mood("night", Color(0.74, 0.78, 0.86, 0.65), 0.75)
