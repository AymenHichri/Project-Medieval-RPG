extends TestCase
## AmbientAudioManager with fades of 0: shared layers survive a profile change, the others go;
## seeded one-shots respect `oneshot_interval`; ducking lowers every layer.

const MusicTest: GDScript = preload("res://tests/unit/test_music_manager.gd")

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _ambience: AmbientAudioManager


func before_each() -> void:
	_ambience = AmbientAudioManager.new()
	_ambience.set_process(false)
	_tree.root.add_child(_ambience)


func after_each() -> void:
	_tree.root.remove_child(_ambience)
	_ambience.free()


func _layer(stream: AudioStream, volume: float = -6.0) -> AmbienceLayer:
	var layer: AmbienceLayer = AmbienceLayer.new()
	layer.stream = stream
	layer.volume_db = volume
	return layer


func _profile(layers: Array[AmbienceLayer]) -> AmbienceProfile:
	var profile: AmbienceProfile = AmbienceProfile.new()
	profile.layers = layers
	return profile


func test_shared_layers_keep_playing_and_others_are_removed() -> void:
	var wind: AudioStream = MusicTest.silent_stream(10.0)
	var crows: AudioStream = MusicTest.silent_stream(10.0)
	var hearth: AudioStream = MusicTest.silent_stream(10.0)
	var graveyard: AmbienceProfile = _profile([_layer(wind), _layer(crows)])
	var village: AmbienceProfile = _profile([_layer(wind, -9.0), _layer(hearth)])
	_ambience.set_profile(graveyard, 0.0)
	assert_eq(_ambience.active_layers().size(), 2)
	var wind_player: AudioStreamPlayer = _ambience.player_for(graveyard.layers[0])
	wind_player.seek(3.0)
	_ambience.set_profile(village, 0.0)
	var streams: Array[AudioStream] = []
	for layer: AmbienceLayer in _ambience.active_layers():
		streams.append(layer.stream)
	assert_eq(streams.size(), 2, "two layers in the village")
	assert_true(wind in streams and hearth in streams and not crows in streams, "wind + hearth")
	assert_eq(_ambience.player_for(village.layers[0]), wind_player, "wind kept its player")
	assert_true(wind_player.playing, "wind still playing")
	assert_almost_eq(wind_player.get_playback_position(), 3.0, 0.25, "wind was not restarted")
	assert_almost_eq(wind_player.volume_db, -9.0, 0.01, "at the new layer volume")
	var playing: int = 0
	for player: AudioStreamPlayer in _ambience.layer_players:
		if player.playing:
			playing += 1
	assert_eq(playing, 2, "the crows player stopped")
	_ambience.set_profile(null, 0.0)
	assert_eq(_ambience.active_layers().size(), 0, "null = silence")


func test_oneshots_respect_interval() -> void:
	var layer: AmbienceLayer = _layer(null)
	layer.random_oneshots = [MusicTest.silent_stream(0.5, false), MusicTest.silent_stream(0.5, false)]
	layer.oneshot_interval = Vector2(8.0, 20.0)
	_ambience.rng.seed = 99
	var times: Array[float] = []
	var clock: Array[float] = [0.0]
	_ambience.oneshot_played.connect(func(_l: AmbienceLayer, _s: AudioStream) -> void: times.append(clock[0]))
	_ambience.set_profile(_profile([layer]), 0.0)
	const STEP: float = 0.1
	for i: int in 6000:  # 600 s
		clock[0] += STEP
		_ambience.advance(STEP)
	assert_true(times.size() >= 600.0 / 20.0 - 1 and times.size() <= 600.0 / 8.0 + 1,
		"%d one-shots in 600 s" % times.size())
	assert_true(times[0] >= 8.0 - STEP and times[0] <= 20.0 + STEP, "first after %f s" % times[0])
	for i: int in range(1, times.size()):
		var gap: float = times[i] - times[i - 1]
		assert_true(gap >= 8.0 - STEP - 0.001 and gap <= 20.0 + STEP + 0.001, "gap %f s" % gap)
	var rng: RandomNumberGenerator = BattleFixtures.rng(5)
	for i: int in 1000:
		var delay: float = AmbientAudioManager.next_oneshot_delay(layer, rng)
		assert_true(delay >= 8.0 and delay <= 20.0, "delay %f" % delay)
		if failures.size() > 0:
			return


func test_same_seed_same_oneshot_times() -> void:
	var layer: AmbienceLayer = _layer(null)
	layer.random_oneshots = [MusicTest.silent_stream(0.5, false)]
	var a: Array[float] = []
	var b: Array[float] = []
	for run: Array[float] in [a, b]:
		var random: RandomNumberGenerator = BattleFixtures.rng(1234)
		for i: int in 20:
			run.append(AmbientAudioManager.next_oneshot_delay(layer, random))
	assert_eq(a, b)


func test_duck_lowers_every_layer_and_restores() -> void:
	var profile: AmbienceProfile = _profile([_layer(MusicTest.silent_stream(5.0), -6.0)])
	_ambience.set_profile(profile, 0.0)
	var player: AudioStreamPlayer = _ambience.player_for(profile.layers[0])
	_ambience.set_duck(AmbientAudioManager.BATTLE_DUCK_DB, 0.0)
	assert_almost_eq(player.volume_db, -18.0, 0.01, "−12 dB in battle")
	_ambience.set_duck(0.0, 0.0)
	assert_almost_eq(player.volume_db, -6.0, 0.01, "restored")
