extends TestCase
## Audio bus layout and AudioManager composition (AUDIO_GUIDELINES.md §5).


func test_buses_exist_and_route_to_master() -> void:
	assert_eq(AudioServer.get_bus_name(0), "Master")
	for bus: String in ["Music", "Ambience", "SFX", "UI"]:
		var index: int = AudioServer.get_bus_index(bus)
		assert_true(index > 0, "bus %s missing" % bus)
		if index > 0:
			assert_eq(AudioServer.get_bus_send(index), &"Master", "bus %s send" % bus)


func test_audio_manager_composes_three_managers() -> void:
	var manager: Node = Engine.get_main_loop().root.get_node_or_null(^"AudioManager")
	assert_not_null(manager, "AudioManager autoload missing")
	if manager == null:
		return
	assert_true(manager.get_node_or_null(^"MusicManager") is MusicManager)
	assert_true(manager.get_node_or_null(^"SFXManager") is SFXManager)
	assert_true(manager.get_node_or_null(^"AmbientAudioManager") is AmbientAudioManager)


func test_pools_are_created_on_correct_buses() -> void:
	var sfx: SFXManager = SFXManager.new()
	assert_eq(sfx.ui_pool.size(), SFXManager.UI_POOL_SIZE)
	assert_eq(sfx.world_pool.size(), SFXManager.WORLD_POOL_SIZE)
	assert_eq(sfx.ui_pool[0].bus, &"UI")
	assert_eq(sfx.world_pool[0].bus, &"SFX")
	sfx.free()
	var music: MusicManager = MusicManager.new()
	assert_eq(music.player_a.bus, &"Music")
	music.free()
	var ambience: AmbientAudioManager = AmbientAudioManager.new()
	assert_eq(ambience.layer_players.size(), AmbientAudioManager.MAX_LAYERS)
	assert_eq(ambience.layer_players[0].bus, &"Ambience")
	ambience.free()


func test_bus_volume_roundtrip() -> void:
	var manager: Node = Engine.get_main_loop().root.get_node_or_null(^"AudioManager")
	if manager == null:
		fail("AudioManager autoload missing")
		return
	manager.call(&"set_bus_volume", &"Music", 0.5)
	assert_almost_eq(manager.call(&"get_bus_volume", &"Music") as float, 0.5, 0.001)
	manager.call(&"set_bus_volume", &"Music", 1.0)
