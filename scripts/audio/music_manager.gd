class_name MusicManager
extends Node
## Plays music on the "Music" bus with a crossfading pair of players.
## Phase 1: players exist and the API is defined. Behaviour (crossfade, push/pop, jingles) arrives in Phase 6.

signal jingle_finished

const BUS: StringName = &"Music"

var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var current_track: MusicTrack


func _init() -> void:
	name = "MusicManager"
	player_a = _make_player("PlayerA")
	player_b = _make_player("PlayerB")


## Crossfade to `track`. Implemented in Phase 6.
func play(track: MusicTrack, _fade: float = 1.0) -> void:
	current_track = track


## Interrupt the current track (e.g. for a battle), remembering its position. Implemented in Phase 6.
func push(track: MusicTrack, _fade: float = 0.4) -> void:
	current_track = track


## Return to the track that was interrupted by `push()`. Implemented in Phase 6.
func pop(_fade: float = 1.5) -> void:
	pass


## Play a non-looping jingle, then emit `jingle_finished`. Implemented in Phase 6.
func play_jingle(_stream: AudioStream) -> void:
	jingle_finished.emit()


func stop(_fade: float = 1.0) -> void:
	current_track = null


func _make_player(player_name: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = BUS
	add_child(player)
	return player
