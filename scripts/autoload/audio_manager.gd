extends Node
## Autoload `AudioManager`: a thin facade composing the three audio managers
## (see AUDIO_GUIDELINES.md §5). Game code calls `AudioManager.music`, `.sfx` and `.ambience`.

const BUSES: Array[StringName] = [&"Master", &"Music", &"Ambience", &"SFX", &"UI"]
## Low-pass cutoff on the Ambience bus while the pause menu is open (AUDIO_GUIDELINES.md §5).
const MUFFLE_CUTOFF_HZ: float = 900.0

var music: MusicManager
var sfx: SFXManager
var ambience: AmbientAudioManager


func _init() -> void:
	# Music and ambience keep playing in the pause menu (audio players pause with the tree).
	process_mode = Node.PROCESS_MODE_ALWAYS
	music = MusicManager.new()
	sfx = SFXManager.new()
	ambience = AmbientAudioManager.new()
	add_child(music)
	add_child(sfx)
	add_child(ambience)


func _ready() -> void:
	var bus: int = AudioServer.get_bus_index(&"Ambience")
	if bus >= 0 and _muffle_effect_index(bus) < 0:
		var low_pass: AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()
		low_pass.cutoff_hz = MUFFLE_CUTOFF_HZ
		AudioServer.add_bus_effect(bus, low_pass)
		AudioServer.set_bus_effect_enabled(bus, AudioServer.get_bus_effect_count(bus) - 1, false)


## Muffles the ambience (pause menu open) or restores it.
func set_ambience_muffled(muffled: bool) -> void:
	var bus: int = AudioServer.get_bus_index(&"Ambience")
	var index: int = _muffle_effect_index(bus) if bus >= 0 else -1
	if index >= 0:
		AudioServer.set_bus_effect_enabled(bus, index, muffled)


func is_ambience_muffled() -> bool:
	var bus: int = AudioServer.get_bus_index(&"Ambience")
	var index: int = _muffle_effect_index(bus) if bus >= 0 else -1
	return index >= 0 and AudioServer.is_bus_effect_enabled(bus, index)


func _muffle_effect_index(bus: int) -> int:
	for i: int in AudioServer.get_bus_effect_count(bus):
		if AudioServer.get_bus_effect(bus, i) is AudioEffectLowPassFilter:
			return i
	return -1


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
