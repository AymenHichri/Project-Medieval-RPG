class_name SFXManager
extends Node
## Plays sound effects from two fixed pools (AUDIO_GUIDELINES.md §5): non-positional UI voices
## (bus "UI") and positional world voices (bus "SFX").
## - Each play picks a random variant of the SfxSet and a random pitch inside its `pitch_range`.
## - A set played again within its `cooldown_ms` is skipped (no stacking).
## - A full world pool steals its oldest voice. UI sounds have their own pool, so world sounds
##   never take a UI voice; a full UI pool reuses its own oldest voice (UI sounds are never dropped).
## - Footsteps: `play_footstep(surface, pos)` uses the library's set for that TileSet `surface`,
##   falling back to `stone`.

const UI_POOL_SIZE: int = 6
const WORLD_POOL_SIZE: int = 12
const LIBRARY_PATH: String = "res://data/audio/sfx_library.tres"
const FALLBACK_SURFACE: StringName = &"stone"

var ui_pool: Array[AudioStreamPlayer] = []
var world_pool: Array[AudioStreamPlayer2D] = []
## Named UI sounds and footsteps (loaded from LIBRARY_PATH when it exists).
var library: SfxLibrary
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Returns the current time in ms (tests replace it to control cooldowns).
var clock: Callable = Time.get_ticks_msec

## SfxSet → the time (ms) it last played.
var _last_played: Dictionary[SfxSet, int] = {}
## Voice → the time (ms) it started, for stealing the oldest.
var _started: Dictionary[Node, int] = {}


func _init() -> void:
	name = "SFXManager"
	rng.randomize()
	for i: int in UI_POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Ui%d" % i
		player.bus = &"UI"
		add_child(player)
		ui_pool.append(player)
	for i: int in WORLD_POOL_SIZE:
		var player_2d: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		player_2d.name = "World%d" % i
		player_2d.bus = &"SFX"
		add_child(player_2d)
		world_pool.append(player_2d)
	if ResourceLoader.exists(LIBRARY_PATH):
		library = load(LIBRARY_PATH) as SfxLibrary
	if library == null:
		library = SfxLibrary.new()


## Plays a UI sound. Returns the voice used, or null when skipped (no streams, cooldown).
func play_ui(sfx: SfxSet) -> AudioStreamPlayer:
	var stream: AudioStream = _pick(sfx)
	if stream == null:
		return null
	var player: AudioStreamPlayer = _free_or_oldest(ui_pool) as AudioStreamPlayer
	_start(player, sfx, stream)
	player.play()
	return player


## Plays a named UI sound from the library ("focus", "confirm", "cancel", "tick", ...). When the
## library has no streams for it yet (not sourced), `fallback` plays instead (if given).
func play_ui_named(sound: StringName, fallback: StringName = &"") -> AudioStreamPlayer:
	if not fallback.is_empty() and not has_ui_sound(sound):
		sound = fallback
	return play_ui(library.ui.get(sound) as SfxSet)


## The library has at least one stream for this UI sound.
func has_ui_sound(sound: StringName) -> bool:
	var sfx: SfxSet = library.ui.get(sound) as SfxSet if library != null else null
	return sfx != null and not sfx.streams.is_empty()


## Plays a positional sound at a world position. Returns the voice used, or null when skipped.
func play_at(sfx: SfxSet, world_position: Vector2) -> AudioStreamPlayer2D:
	var stream: AudioStream = _pick(sfx)
	if stream == null:
		return null
	var player: AudioStreamPlayer2D = _free_or_oldest(world_pool) as AudioStreamPlayer2D
	_start(player, sfx, stream)
	player.global_position = world_position
	player.play()
	return player


## Plays the footstep set for a TileSet `surface` value (unknown → stone).
func play_footstep(surface: StringName, world_position: Vector2) -> AudioStreamPlayer2D:
	return play_at(footstep_set_for(surface), world_position)


func footstep_set_for(surface: StringName) -> SfxSet:
	var sfx: SfxSet = library.footsteps.get(surface) as SfxSet
	if sfx == null:
		sfx = library.footsteps.get(FALLBACK_SURFACE) as SfxSet
	return sfx


## Voices of a pool currently playing.
func busy_count(pool: Array) -> int:
	var n: int = 0
	for player: Node in pool:
		if player.get(&"playing"):
			n += 1
	return n


func stop_all() -> void:
	for player: AudioStreamPlayer in ui_pool:
		player.stop()
	for player_2d: AudioStreamPlayer2D in world_pool:
		player_2d.stop()
	_last_played.clear()
	_started.clear()


## A variant to play now, or null (no set, no streams, or still cooling down). Records the play.
func _pick(sfx: SfxSet) -> AudioStream:
	if sfx == null or sfx.streams.is_empty():
		return null
	var now: int = clock.call() as int
	if _last_played.has(sfx) and now - _last_played[sfx] < sfx.cooldown_ms:
		return null
	_last_played[sfx] = now
	return sfx.streams[rng.randi_range(0, sfx.streams.size() - 1)]


func _start(player: Node, sfx: SfxSet, stream: AudioStream) -> void:
	player.stop()
	player.set(&"stream", stream)
	player.set(&"volume_db", sfx.volume_db)
	var low: float = minf(sfx.pitch_range.x, sfx.pitch_range.y)
	var high: float = maxf(sfx.pitch_range.x, sfx.pitch_range.y)
	player.set(&"pitch_scale", maxf(0.01, rng.randf_range(low, high)))
	_started[player] = clock.call() as int


## The first idle voice, or else the one that started longest ago.
func _free_or_oldest(pool: Array) -> Node:
	var oldest: Node = pool[0]
	for player: Node in pool:
		if not player.get(&"playing"):
			return player
		if _started.get(player, 0) < _started.get(oldest, 0):
			oldest = player
	return oldest
