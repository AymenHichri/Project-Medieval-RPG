class_name Map
extends Node2D
## Base script for every exploration map (PROJECT_PLAN.md §6.1, map scene template).
## Expected children: `Ground`, `Terrain`, `Decals`, `World` (y-sorted, holds props and the
## player), `Spawns` (SpawnPoint markers), `Lights`, `Ambience` (vendor ambience controller)
## and `CameraBounds` (ReferenceRect). On ready it clamps the player's camera to the bounds,
## applies the visual mood, starts the map's music and ambience, adds the exploration HUD and the
## pause menu (`menu` action), and, in debug builds, the F3 debug overlay. Random encounters: the player's EncounterTracker reports one, and the map
## turns it into a BattleSetup for `SceneManager.start_battle()` (§4.5).

## Loaded at runtime, not preloaded: the overlay script refers to `Map`, so a preload would
## make a load cycle.
const DEBUG_OVERLAY_PATH: String = "res://scenes/ui/debug/debug_overlay.tscn"
const HUD_PATH: String = "res://scenes/ui/exploration_hud.tscn"
const PAUSE_MENU_PATH: String = "res://scenes/ui/pause_menu.tscn"

## Unique id of this map (snake_case, matches the scene file name).
@export var map_id: StringName = &""
## Name shown to the player (map screen, location banner).
@export var display_name: String = ""
## Exploration music, played on ready (null = silence). Resumes after a battle.
@export var music: MusicTrack
## Ambient sound layers, played on ready (null = silence).
@export var ambience: AmbienceProfile
## Visual mood passed to the vendor ambience controller: day, golden_hour, dusk, night,
## storm, fog or blood_moon. Empty keeps the controller's own preset.
@export var ambience_preset: StringName = &"dusk"
## Scenery only (the title screen's live background): the player is removed, and the map plays
## no music or ambience, has no encounters and no debug overlay. Set before adding to the tree.
@export var backdrop: bool = false

## The player inside this map, if any (found on ready).
var player: PlayerController
## The exploration HUD and pause menu (added on ready; null on a backdrop).
var hud: ExplorationHud
var pause_menu: PauseMenu

@onready var _camera_bounds: ReferenceRect = %CameraBounds


func _ready() -> void:
	player = _find_player(self)
	_apply_ambience_preset()
	if backdrop:
		if player != null:
			player.get_parent().remove_child(player)
			player.free()
			player = null
		return
	GameState.ensure_party()
	if player != null:
		player.camera.apply_bounds(get_camera_bounds())
		player.encounter_tracker.encounter_triggered.connect(_on_encounter_triggered)
		player.footstep.connect(_on_player_footstep)
	AudioManager.music.play(music)
	AudioManager.ambience.set_profile(ambience)
	pause_menu = (load(PAUSE_MENU_PATH) as PackedScene).instantiate() as PauseMenu
	add_child(pause_menu)
	hud = (load(HUD_PATH) as PackedScene).instantiate() as ExplorationHud
	add_child(hud)
	hud.menu_pressed.connect(open_pause_menu)
	if OS.is_debug_build():
		var overlay: DebugOverlay = (load(DEBUG_OVERLAY_PATH) as PackedScene).instantiate() as DebugOverlay
		overlay.setup(self)
		add_child(overlay)


## Opens the pause menu when the player is free to act (not in a dialogue, fade or battle).
## Returns true when it opened.
func open_pause_menu() -> bool:
	if pause_menu == null or pause_menu.is_open() or SceneManager.is_transitioning:
		return false
	if player != null and not player.can_act():
		return false
	pause_menu.open()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu") and not event.is_echo() and open_pause_menu():
		get_viewport().set_input_as_handled()


## Returns the spawn point with this id, or null (with a warning) if the map has none.
func get_spawn(id: StringName) -> SpawnPoint:
	for spawn: SpawnPoint in get_spawns():
		if spawn.spawn_id == id:
			return spawn
	push_warning("Map %s has no spawn '%s'" % [map_id, id])
	return null


## All spawn points of this map, in scene order (the first one is the fallback spawn).
func get_spawns() -> Array[SpawnPoint]:
	var spawns: Array[SpawnPoint] = []
	_collect_spawns(self, spawns)
	return spawns


## Moves the player to a spawn point, turns it to the spawn's facing and snaps the camera.
## An unknown id falls back to the first spawn (after `get_spawn`'s warning). Returns the
## spawn used, or null when the map has no spawns.
func place_player(spawn_id: StringName) -> SpawnPoint:
	var spawn: SpawnPoint = get_spawn(spawn_id)
	if spawn == null:
		var spawns: Array[SpawnPoint] = get_spawns()
		spawn = spawns[0] if not spawns.is_empty() else null
	if spawn == null or player == null:
		return spawn
	player.global_position = spawn.global_position
	player.face(StringName(spawn.facing))
	player.reset_physics_interpolation()
	player.camera.apply_bounds(get_camera_bounds())
	return spawn


## The world-space rectangle the camera must stay inside.
func get_camera_bounds() -> Rect2:
	return _camera_bounds.get_global_transform() * Rect2(Vector2.ZERO, _camera_bounds.size)


## The TileSet custom data `surface` (grass, mud, stone, ash, ...) under a world position: the
## topmost tile layer with a surface there wins. Empty when no layer has one.
func surface_at(world_position: Vector2) -> StringName:
	var layers: Array[Node] = find_children("*", "TileMapLayer", true, false)
	for i: int in range(layers.size() - 1, -1, -1):
		var layer: TileMapLayer = layers[i] as TileMapLayer
		if layer.tile_set == null or layer.tile_set.get_custom_data_layer_by_name("surface") < 0:
			continue
		var data: TileData = layer.get_cell_tile_data(layer.local_to_map(layer.to_local(world_position)))
		if data == null:
			continue
		var surface: String = str(data.get_custom_data("surface"))
		if not surface.is_empty():
			return StringName(surface)
	return &""


## All encounter zones of this map.
func get_encounter_zones() -> Array[EncounterZone]:
	var zones: Array[EncounterZone] = []
	for node: Node in find_children("*", "Area2D", true, false):
		if node is EncounterZone:
			zones.append(node as EncounterZone)
	return zones


func _on_encounter_triggered(group: EncounterGroup, table: EncounterTable) -> void:
	# Deferred: the tracker reports from inside the physics step, and the battle detaches this map.
	SceneManager.start_battle.call_deferred(EncounterRoller.make_setup(group, table))


func _on_player_footstep(at: Vector2) -> void:
	AudioManager.sfx.play_footstep(surface_at(at), at)


func _apply_ambience_preset() -> void:
	var controller: Node = get_node_or_null(^"Ambience")
	if controller == null or ambience_preset.is_empty():
		return
	if controller.has_method(&"set_preset"):
		controller.call(&"set_preset", String(ambience_preset), 0.0)


func _collect_spawns(root: Node, into: Array[SpawnPoint]) -> void:
	for child: Node in root.get_children():
		if child is SpawnPoint:
			into.append(child as SpawnPoint)
		_collect_spawns(child, into)


func _find_player(root: Node) -> PlayerController:
	for child: Node in root.get_children():
		if child is PlayerController:
			return child as PlayerController
		var found: PlayerController = _find_player(child)
		if found != null:
			return found
	return null
