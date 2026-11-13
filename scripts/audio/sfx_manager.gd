class_name SFXManager
extends Node
## Plays sound effects from two fixed pools: non-positional UI voices and positional world voices.
## Phase 1: pools exist and the API is defined. Variant/pitch/cooldown/voice stealing arrive in Phase 7.

const UI_POOL_SIZE: int = 6
const WORLD_POOL_SIZE: int = 12

var ui_pool: Array[AudioStreamPlayer] = []
var world_pool: Array[AudioStreamPlayer2D] = []


func _init() -> void:
	name = "SFXManager"
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


## Play a UI sound. Implemented in Phase 7.
func play_ui(_sfx: SfxSet) -> void:
	pass


## Play a positional sound at a world position. Implemented in Phase 7.
func play_at(_sfx: SfxSet, _world_position: Vector2) -> void:
	pass


## Play the footstep set for a TileSet `surface` value. Implemented in Phase 7.
func play_footstep(_surface: StringName, _world_position: Vector2) -> void:
	pass
