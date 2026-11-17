class_name AmbientAudioManager
extends Node
## Plays layered looping ambience beds on the "Ambience" bus (AUDIO_GUIDELINES.md §5).
## `set_profile()` crossfades between places: a layer whose stream is in both profiles keeps
## playing, the others fade out or in. Each layer can fire random one-shots (crows, a distant
## bell) every `oneshot_interval` seconds. `set_duck()` lowers everything (battles: −12 dB).

## Emitted when a random one-shot starts.
signal oneshot_played(layer: AmbienceLayer, stream: AudioStream)

const MAX_LAYERS: int = 4
const BUS: StringName = &"Ambience"
const SILENT_DB: float = -80.0
## Ambience reduction while a battle runs.
const BATTLE_DUCK_DB: float = -12.0

var layer_players: Array[AudioStreamPlayer] = []
var oneshot_players: Array[AudioStreamPlayer] = []
var current_profile: AmbienceProfile
## Current reduction (dB, ≤ 0) applied on top of every layer's volume.
var duck_db: float = 0.0
## Drives the one-shot timing; seed it for deterministic tests.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## The layer each slot plays (null = free slot), parallel to `layer_players`.
var _layers: Array[AmbienceLayer] = []
## Seconds until each slot's next one-shot (INF = none).
var _oneshot_wait: Array[float] = []
var _tweens: Dictionary[AudioStreamPlayer, Tween] = {}


func _init() -> void:
	name = "AmbientAudioManager"
	rng.randomize()
	for i: int in MAX_LAYERS:
		layer_players.append(_make_player("Layer%d" % i))
		oneshot_players.append(_make_player("OneShot%d" % i))
		_layers.append(null)
		_oneshot_wait.append(INF)


func _process(delta: float) -> void:
	advance(delta)


## Crossfades to a new ambience profile (null = silence). Layers sharing a stream with the new
## profile keep playing without restarting; the rest fade out, and new layers fade in.
func set_profile(profile: AmbienceProfile, fade: float = 2.0) -> void:
	if profile == current_profile:
		return
	current_profile = profile
	var wanted: Array[AmbienceLayer] = []
	if profile != null:
		for layer: AmbienceLayer in profile.layers:
			if layer != null and wanted.size() < MAX_LAYERS:
				wanted.append(layer)
	var placed: Array[AmbienceLayer] = []
	for i: int in MAX_LAYERS:
		var old: AmbienceLayer = _layers[i]
		if old == null:
			continue
		var same: AmbienceLayer = _layer_with_stream(wanted, old.stream, placed)
		if same != null:
			_layers[i] = same
			placed.append(same)
			_fade(layer_players[i], same.volume_db + duck_db, fade, false)
			if same != old:
				_oneshot_wait[i] = next_oneshot_delay(same, rng)
		else:
			_layers[i] = null
			_oneshot_wait[i] = INF
			_fade(layer_players[i], SILENT_DB, fade, true)
	for layer: AmbienceLayer in wanted:
		if layer in placed:
			continue
		var slot: int = _layers.find(null)
		if slot < 0:
			break
		_start_layer(slot, layer, fade)
		placed.append(layer)


## Lowers (db < 0) or restores (0) the whole ambience.
func set_duck(db: float, fade: float = 0.5) -> void:
	duck_db = minf(0.0, db)
	for i: int in MAX_LAYERS:
		if _layers[i] != null:
			_fade(layer_players[i], _layers[i].volume_db + duck_db, fade, false)


## The layers playing now, in slot order.
func active_layers() -> Array[AmbienceLayer]:
	var out: Array[AmbienceLayer] = []
	for layer: AmbienceLayer in _layers:
		if layer != null:
			out.append(layer)
	return out


## The player of a layer of the current profile (null when it is not playing).
func player_for(layer: AmbienceLayer) -> AudioStreamPlayer:
	var slot: int = _layers.find(layer)
	return layer_players[slot] if slot >= 0 else null


## Moves the one-shot clocks forward by `delta` seconds, firing the one-shots that are due.
## Called every frame; tests call it directly.
func advance(delta: float) -> void:
	for i: int in MAX_LAYERS:
		var layer: AmbienceLayer = _layers[i]
		if layer == null or layer.random_oneshots.is_empty():
			continue
		_oneshot_wait[i] -= delta
		while _oneshot_wait[i] <= 0.0:
			_play_oneshot(i, layer)
			_oneshot_wait[i] += next_oneshot_delay(layer, rng)


## Seconds before a layer's next one-shot: uniform in `oneshot_interval` (INF without one-shots).
static func next_oneshot_delay(layer: AmbienceLayer, random: RandomNumberGenerator) -> float:
	if layer == null or layer.random_oneshots.is_empty():
		return INF
	var low: float = maxf(0.05, minf(layer.oneshot_interval.x, layer.oneshot_interval.y))
	var high: float = maxf(low, maxf(layer.oneshot_interval.x, layer.oneshot_interval.y))
	return random.randf_range(low, high)


## Set or clear the weather layer (rain, wind). Implemented in Phase 12.
func set_weather_layer(_stream: AudioStream) -> void:
	pass


func _start_layer(slot: int, layer: AmbienceLayer, fade: float) -> void:
	var player: AudioStreamPlayer = layer_players[slot]
	_kill_tween(player)
	_layers[slot] = layer
	player.stream = layer.stream
	player.volume_db = SILENT_DB if fade > 0.0 else layer.volume_db + duck_db
	if layer.stream != null:
		player.play()
	_fade(player, layer.volume_db + duck_db, fade, false)
	_oneshot_wait[slot] = next_oneshot_delay(layer, rng)


func _play_oneshot(slot: int, layer: AmbienceLayer) -> void:
	var stream: AudioStream = layer.random_oneshots[rng.randi_range(0, layer.random_oneshots.size() - 1)]
	var player: AudioStreamPlayer = oneshot_players[slot]
	player.stream = stream
	player.volume_db = layer.volume_db + duck_db
	if stream != null:
		player.play()
	oneshot_played.emit(layer, stream)


func _layer_with_stream(layers: Array[AmbienceLayer], stream: AudioStream,
		taken: Array[AmbienceLayer]) -> AmbienceLayer:
	if stream == null:
		return null
	for layer: AmbienceLayer in layers:
		if layer.stream == stream and not layer in taken:
			return layer
	return null


func _fade(player: AudioStreamPlayer, to_db: float, duration: float, stop_after: bool) -> void:
	_kill_tween(player)
	if duration <= 0.0 or not is_inside_tree():
		player.volume_db = to_db
		if stop_after:
			player.stop()
		return
	var tween: Tween = create_tween()
	# Linear amplitude (as MusicManager), so the fade is heard over its whole duration.
	tween.tween_method(_set_amplitude.bind(player), db_to_linear(player.volume_db), db_to_linear(to_db),
			duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if stop_after:
		tween.tween_callback(player.stop)
	_tweens[player] = tween


func _set_amplitude(amplitude: float, player: AudioStreamPlayer) -> void:
	player.volume_db = maxf(linear_to_db(maxf(amplitude, 0.0)), SILENT_DB)


func _kill_tween(player: AudioStreamPlayer) -> void:
	var tween: Tween = _tweens.get(player) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	_tweens.erase(player)


func _make_player(player_name: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = BUS
	add_child(player)
	return player
