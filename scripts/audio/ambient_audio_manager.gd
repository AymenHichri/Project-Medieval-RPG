class_name AmbientAudioManager
extends Node
## Plays layered looping ambience beds on the "Ambience" bus.
## Phase 1: layer players exist and the API is defined. Crossfades and one-shots arrive in Phase 6.

const MAX_LAYERS: int = 4

var layer_players: Array[AudioStreamPlayer] = []
var current_profile: AmbienceProfile


func _init() -> void:
	name = "AmbientAudioManager"
	for i: int in MAX_LAYERS:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Layer%d" % i
		player.bus = &"Ambience"
		add_child(player)
		layer_players.append(player)


## Crossfade to a new ambience profile (null = silence). Implemented in Phase 6.
func set_profile(profile: AmbienceProfile, _fade: float = 2.0) -> void:
	current_profile = profile


## Set or clear the weather layer (rain, wind). Implemented in Phase 12.
func set_weather_layer(_stream: AudioStream) -> void:
	pass
