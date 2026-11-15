extends Node
## Autoload `SceneManager`: owns screen fades and scene flow (maps, battles, title, game over).
## Phase 6: map changes and the world ↔ battle hand-off (PROJECT_PLAN.md §4.5).

signal map_changed(map_path: String)
signal battle_started(setup: BattleSetup)
signal battle_ended(result: BattleResult)

const FADE_OVERLAY: PackedScene = preload("res://scenes/ui/fade_overlay.tscn")
## Loaded at runtime (not preloaded) so this autoload never pulls the battle scripts into a cycle.
const BATTLE_SCENE_PATH: String = "res://scenes/battle/battle_scene.tscn"
const TITLE_SCENE: String = "res://scenes/boot/main.tscn"

## Duration (s) of each half of a map-change fade.
const MAP_FADE_SECONDS: float = 0.35
## Battle intro: flashes, then a fade to black, then a fade into the battle.
const BATTLE_FLASHES: int = 2
const BATTLE_FLASH_SECONDS: float = 0.14
const BATTLE_FADE_OUT_SECONDS: float = 0.3
const BATTLE_FADE_IN_SECONDS: float = 0.35
const BATTLE_RETURN_FADE_SECONDS: float = 0.35
## Music fades around a battle.
const BATTLE_MUSIC_IN_SECONDS: float = 0.3
const BATTLE_MUSIC_OUT_SECONDS: float = 1.0

## Skip fades (tests and debugging).
var instant_transitions: bool = false
## Tests: battles skip every animation, and the party auto-attacks.
var instant_battles: bool = false
var auto_battles: bool = false
## Seeded RNG for the next battles (tests); null = a fresh random one per battle.
var battle_rng: RandomNumberGenerator
## Played when a battle is won (null until the slice audio exists, Phase 7).
var victory_jingle: AudioStream
## True while a map change or a battle transition runs; further requests are ignored.
var is_transitioning: bool = false
## True from `start_battle()` until the world is back.
var in_battle: bool = false

var _fade: FadeOverlay
## The map taken out of the tree during a battle (kept in memory, not freed).
var _detached_world: Node
var _battle: BattleController


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
	if is_transitioning or in_battle:
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


## Runs a battle from the current map (§4.5): pushes the battle music, flashes and fades, takes
## the map out of the tree (kept in memory, so the player's position and the map state survive),
## runs `battle_scene.tscn` with `GameState.party`, then hands the result to `end_battle()`.
## Returns the result, or null when the request was ignored. Not inside a physics callback.
func start_battle(setup: BattleSetup) -> BattleResult:
	if is_transitioning or in_battle or setup == null or setup.enemies.is_empty():
		push_warning("SceneManager: start_battle ignored (busy or empty setup)")
		return null
	is_transitioning = true
	in_battle = true
	var tree: SceneTree = get_tree()
	var world: Node = tree.current_scene
	_set_player_input(world, false)
	battle_started.emit(setup)
	AudioManager.music.push(setup.music, 0.0 if instant_transitions else BATTLE_MUSIC_IN_SECONDS)
	AudioManager.ambience.set_duck(AmbientAudioManager.BATTLE_DUCK_DB, 0.0 if instant_transitions else 0.5)
	if not instant_transitions:
		await _fade.flash(BATTLE_FLASHES, BATTLE_FLASH_SECONDS)
	await fade_out(BATTLE_FADE_OUT_SECONDS)

	if world != null:
		tree.root.remove_child(world)
	_detached_world = world
	GameState.ensure_party()
	_battle = (load(BATTLE_SCENE_PATH) as PackedScene).instantiate() as BattleController
	_battle.instant = instant_battles
	_battle.auto_battle = auto_battles
	_battle.victory.connect(_on_battle_victory)
	tree.root.add_child(_battle)
	tree.current_scene = _battle

	var rng: RandomNumberGenerator = battle_rng
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	is_transitioning = false
	# Not awaited: the battle's intro message plays while the screen fades in.
	fade_in(BATTLE_FADE_IN_SECONDS)
	var result: BattleResult = await _battle.start(setup, GameState.party, rng, GameState.battle_items())
	GameState.sync_battle_items(_battle.items)
	await end_battle(result)
	return result


## Finishes the running battle: applies a victory's rewards (the single place rewards are
## applied), frees the battle, puts the map back, returns to the map music and fades in.
## A defeat goes to `game_over()` instead.
func end_battle(result: BattleResult) -> void:
	if not in_battle:
		push_warning("SceneManager: end_battle without a battle")
		return
	is_transitioning = true
	if result != null and result.is_victory():
		GameState.apply_battle_rewards(result)
	GameState.settle_party_after_battle()
	if result != null and result.outcome == BattleEngine.Outcome.DEFEAT:
		await game_over()
		battle_ended.emit(result)
		return

	await fade_out(BATTLE_RETURN_FADE_SECONDS)
	var tree: SceneTree = get_tree()
	_free_battle()
	var world: Node = _detached_world
	_detached_world = null
	if world != null:
		tree.root.add_child(world)
		tree.current_scene = world
		_restore_player(world as Map)
	AudioManager.music.pop(0.0 if instant_transitions else BATTLE_MUSIC_OUT_SECONDS)
	AudioManager.ambience.set_duck(0.0, 0.0 if instant_transitions else 1.0)
	in_battle = false
	await fade_in(BATTLE_RETURN_FADE_SECONDS)
	_set_player_input(world, true)
	is_transitioning = false
	battle_ended.emit(result)


func to_title() -> void:
	await fade_out()
	get_tree().change_scene_to_file(TITLE_SCENE)
	await fade_in()


## The party has fallen. Phase 6 stand-in for the Game Over screen (Phase 7): fade out, drop the
## battle and the map it came from, and return to the title.
func game_over() -> void:
	is_transitioning = true
	await fade_out(BATTLE_RETURN_FADE_SECONDS)
	_free_battle()
	if _detached_world != null:
		_detached_world.free()
		_detached_world = null
	AudioManager.music.stop(0.0)
	AudioManager.ambience.set_duck(0.0, 0.0)
	AudioManager.ambience.set_profile(null, 0.0)
	in_battle = false
	GameState.current_map = ""
	var tree: SceneTree = get_tree()
	var title: Node = (load(TITLE_SCENE) as PackedScene).instantiate()
	tree.root.add_child(title)
	tree.current_scene = title
	await fade_in()
	is_transitioning = false


## The map waiting for the battle to end (null outside battles).
func detached_world() -> Node:
	return _detached_world


func _free_battle() -> void:
	if _battle == null:
		return
	var tree: SceneTree = get_tree()
	if _battle.get_parent() != null:
		_battle.get_parent().remove_child(_battle)
	if tree.current_scene == _battle:
		tree.current_scene = null
	_battle.queue_free()
	_battle = null


func _restore_player(map: Map) -> void:
	if map == null or map.player == null:
		return
	map.player.reset_physics_interpolation()
	map.player.camera.make_current()
	map.player.camera.reset_smoothing()
	map.player.encounter_tracker.reset_grace()


func _on_battle_victory(_result: BattleResult) -> void:
	if victory_jingle != null:
		AudioManager.music.play_jingle(victory_jingle)


func _set_player_input(scene: Node, enabled: bool) -> void:
	var map: Map = scene as Map
	if map != null and is_instance_valid(map) and map.player != null:
		map.player.input_enabled = enabled
