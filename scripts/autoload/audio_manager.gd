extends Node
## Autoload `AudioManager`: a thin facade composing the three audio managers
## (see AUDIO_GUIDELINES.md §5). Game code calls `AudioManager.music`, `.sfx` and `.ambience`.

const BUSES: Array[StringName] = [&"Master", &"Music", &"Ambience", &"SFX", &"UI"]

var music: MusicManager
var sfx: SFXManager
var ambience: AmbientAudioManager


func _init() -> void:
	music = MusicManager.new()
	sfx = SFXManager.new()
	ambience = AmbientAudioManager.new()
	add_child(music)
	add_child(sfx)
	add_child(ambience)


## Set a bus volume from a linear 0..1 slider value.
func set_bus_volume(bus_name: StringName, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_warning("AudioManager: unknown bus %s" % bus_name)
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(clampf(linear, 0.0, 1.0)))


## Linear 0..1 volume of a bus.
func get_bus_volume(bus_name: StringName) -> float:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))
