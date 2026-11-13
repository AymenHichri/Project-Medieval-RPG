extends Node
## Autoload `SceneManager`: owns screen fades and scene flow (maps, battles, title, game over).
## Phase 3: fades, title flow and map changes. Battles arrive in Phase 6.

signal map_changed(map_path: String)
signal battle_started
signal battle_ended(result: Resource)

const FADE_OVERLAY: PackedScene = preload("res://scenes/ui/fade_overlay.tscn")
const TITLE_SCENE: String = "res://scenes/boot/main.tscn"

## Duration (s) of each half of a map-change fade.
const MAP_FADE_SECONDS: float = 0.35

## Skip fades (tests and debugging).
var instant_transitions: bool = false
## True while a map change runs; further change requests are ignored until it ends.
var is_transitioning: bool = false

var _fade: FadeOverlay


func _ready() -> void:
	_fade = FADE_OVERLAY.instantiate() as FadeOverlay
	add_child(_fade)


func fade_out(duration: float = 0.35) -> void:
	await _fade.fade_to(1.0, 0.0 if instant_transitions else duration)


func fade_in(duration: float = 0.35) -> void:
	await _fade.fade_to(0.0, 0.0 if instant_transitions else duration)


## Changes to a map scene and places its player at a spawn point (PROJECT_PLAN.md §6.1):
## fade out, free the current scene, instance the map, place the player (an unknown spawn
## falls back to the map's first spawn, with a warning), fade in. Player input is off for the
## whole transition. Must not be called inside a physics callback (use `call_deferred`).
func change_map(map_path: String, spawn_id: StringName) -> void:
	if is_transitioning:
		push_warning("SceneManager: change_map(%s) ignored, a transition is running" % map_path)
		return
	var packed: PackedScene = load(map_path) as PackedScene
	if packed == null:
		push_error("SceneManager: cannot load map %s" % map_path)
		return
	is_transitioning = true
	var tree: SceneTree = get_tree()
	_set_player_input(tree.current_scene, false)
	await fade_out(MAP_FADE_SECONDS)

	var old_scene: Node = tree.current_scene
	if old_scene != null:
		tree.root.remove_child(old_scene)
		old_scene.queue_free()
	var scene: Node = packed.instantiate()
	tree.root.add_child(scene)
	tree.current_scene = scene
	GameState.current_map = map_path
	var map: Map = scene as Map
	if map != null:
		map.place_player(spawn_id)
	_set_player_input(scene, false)
	map_changed.emit(map_path)

	await fade_in(MAP_FADE_SECONDS)
	_set_player_input(scene, true)
	is_transitioning = false


## Start a battle (argument becomes `BattleSetup` in Phase 4). Implemented in Phase 6.
func start_battle(_setup: Resource) -> void:
	battle_started.emit()


## Finish a battle and apply rewards (argument becomes `BattleResult`). Implemented in Phase 6.
func end_battle(result: Resource) -> void:
	battle_ended.emit(result)


func to_title() -> void:
	await fade_out()
	get_tree().change_scene_to_file(TITLE_SCENE)
	await fade_in()


## Implemented in Phase 7.
func game_over() -> void:
	pass


func _set_player_input(scene: Node, enabled: bool) -> void:
	var map: Map = scene as Map
	if map != null and is_instance_valid(map) and map.player != null:
		map.player.input_enabled = enabled
