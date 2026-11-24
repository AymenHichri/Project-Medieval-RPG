class_name MusicManager
extends Node
## Plays music on the "Music" bus with a crossfading pair of players (AUDIO_GUIDELINES.md §5).
## `push()` interrupts the current track (a battle) and remembers where it was; `pop()` goes back
## to it at that position. Jingles (victory, level up) play on their own player.
## Every fade time of 0 is applied at once (tests). A negative fade time (the default of `play`
## and `stop`) uses the tracks' own `fade_in` / `fade_out`. Fades move the linear amplitude, not
## the dB value, so a fade is heard over its whole duration.

signal jingle_finished

const BUS: StringName = &"Music"
## Volume treated as silent; faded-out players stop.
const SILENT_DB: float = -80.0
## Fade applied to the music under a jingle.
const JINGLE_DUCK_FADE: float = 0.2

var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var jingle_player: AudioStreamPlayer
var current_track: MusicTrack

## The player of `current_track` (null when stopped).
var _active: AudioStreamPlayer
## Interrupted tracks: {"track": MusicTrack, "position": float}.
var _stack: Array[Dictionary] = []
var _tweens: Dictionary[AudioStreamPlayer, Tween] = {}
## Bumped by every jingle start/stop, so a stale finish never emits `jingle_finished`.
var _jingle_token: int = 0


func _init() -> void:
	name = "MusicManager"
	player_a = _make_player("PlayerA")
	player_b = _make_player("PlayerB")
	jingle_player = _make_player("Jingle")
	jingle_player.finished.connect(_on_jingle_player_finished)


## Releases the streams when leaving the tree (at shutdown), so a track still playing isn't
## reported as leaked.
func _exit_tree() -> void:
	for player: AudioStreamPlayer in [player_a, player_b, jingle_player]:
		player.stop()
		player.stream = null
	_active = null
	current_track = null


## Crossfades to `track`, starting at `from_position` seconds. The track already playing is
## not restarted. Null stops the music. `fade` < 0: the new track's `fade_in` and the old
## track's `fade_out`.
func play(track: MusicTrack, fade: float = -1.0, from_position: float = 0.0) -> void:
	if track == null:
		stop(fade)
		return
	if track == current_track and _active != null and _active.playing:
		return
	var outgoing: AudioStreamPlayer = _active
	var fade_in: float = track.fade_in if fade < 0.0 else fade
	var fade_out: float = (current_track.fade_out if current_track != null else fade_in) if fade < 0.0 else fade
	# Never take over a player that is still fading out (a `stop()` just before): it would cut.
	var incoming: AudioStreamPlayer = player_a
	if outgoing == player_a or (outgoing == null and player_a.playing and not player_b.playing):
		incoming = player_b
	current_track = track
	_active = incoming
	_kill_tween(incoming)
	incoming.stream = track.stream
	incoming.volume_db = SILENT_DB if fade_in > 0.0 else track.volume_db
	if track.stream != null:
		incoming.play(maxf(0.0, from_position))
	_fade(incoming, track.volume_db, fade_in, false)
	if outgoing != null:
		_fade(outgoing, SILENT_DB, fade_out, true)


## Interrupts the current track with `track` (e.g. battle music), remembering the current one
## and its position for `pop()`. Null silences the music until `pop()`.
func push(track: MusicTrack, fade: float = 0.4) -> void:
	_stack.append({"track": current_track, "position": current_position()})
	stop_jingle()
	if track == null:
		stop(fade)
	else:
		play(track, fade)


## Returns to the track interrupted by the last `push()`, at its stored position (or from the
## start when its `resume_on_return` is off). Stops a jingle that is still playing.
func pop(fade: float = 1.5) -> void:
	if _stack.is_empty():
		return
	stop_jingle()
	var entry: Dictionary = _stack.pop_back()
	var track: MusicTrack = entry["track"] as MusicTrack
	if track == null:
		stop(fade)
		return
	var position: float = float(entry["position"]) if track.resume_on_return else 0.0
	if track != current_track:
		play(track, fade, position)
	elif _active == null or not _active.playing:
		current_track = null
		play(track, fade, position)


## Plays a non-looping jingle, fading the music out over `music_fade` s, then emits
## `jingle_finished`. A null or empty stream finishes on the next frame.
func play_jingle(stream: AudioStream, music_fade: float = JINGLE_DUCK_FADE) -> void:
	_jingle_token += 1
	var token: int = _jingle_token
	if _active != null:
		_fade(_active, SILENT_DB, music_fade, true)
		_active = null
		current_track = null
	var length: float = stream.get_length() if stream != null else 0.0
	if stream == null or length <= 0.0:
		_finish_jingle.call_deferred(token)
		return
	jingle_player.stream = stream
	jingle_player.volume_db = 0.0
	jingle_player.play()
	# Fallback for audio drivers that don't mix (headless): finish after the stream's length.
	if is_inside_tree():
		get_tree().create_timer(length + 0.1).timeout.connect(_finish_jingle.bind(token))


## Stops a playing jingle without emitting `jingle_finished`.
func stop_jingle() -> void:
	_jingle_token += 1
	jingle_player.stop()


func is_jingle_playing() -> bool:
	return jingle_player.playing


## Fades the music out (`fade` < 0: the current track's `fade_out`).
func stop(fade: float = -1.0) -> void:
	if _active != null:
		var duration: float = fade if fade >= 0.0 else (current_track.fade_out if current_track != null else 1.0)
		_fade(_active, SILENT_DB, duration, true)
	_active = null
	current_track = null


## Playback position (s) of the current track; 0 when stopped.
func current_position() -> float:
	if _active == null or not _active.playing:
		return 0.0
	return _active.get_playback_position()


## The player of the current track (null when stopped).
func active_player() -> AudioStreamPlayer:
	return _active


## Tracks interrupted by `push()` and not popped yet.
func stack_depth() -> int:
	return _stack.size()


## Forgets every track waiting for a `pop()` (the scene they belong to is gone: Game Over).
func clear_stack() -> void:
	_stack.clear()


## Players currently audible (playing above SILENT_DB, jingle excluded).
func audible_players() -> Array[AudioStreamPlayer]:
	var out: Array[AudioStreamPlayer] = []
	for player: AudioStreamPlayer in [player_a, player_b]:
		if player.playing and player.volume_db > SILENT_DB + 0.1:
			out.append(player)
	return out


func _fade(player: AudioStreamPlayer, to_db: float, duration: float, stop_after: bool) -> void:
	_kill_tween(player)
	if duration <= 0.0 or not is_inside_tree():
		player.volume_db = to_db
		if stop_after:
			player.stop()
		return
	var tween: Tween = create_tween()
	tween.tween_method(_set_amplitude.bind(player), db_to_linear(player.volume_db), db_to_linear(to_db),
			duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if stop_after:
		tween.tween_callback(player.stop)
	_tweens[player] = tween


## Tween step: linear amplitude → volume_db (floored at SILENT_DB).
func _set_amplitude(amplitude: float, player: AudioStreamPlayer) -> void:
	player.volume_db = maxf(linear_to_db(maxf(amplitude, 0.0)), SILENT_DB)


func _kill_tween(player: AudioStreamPlayer) -> void:
	var tween: Tween = _tweens.get(player) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	_tweens.erase(player)


func _on_jingle_player_finished() -> void:
	_finish_jingle(_jingle_token)


func _finish_jingle(token: int) -> void:
	if token != _jingle_token:
		return
	_jingle_token += 1
	jingle_player.stop()
	jingle_finished.emit()


func _make_player(player_name: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = BUS
	add_child(player)
	return player
