extends TestCase
## MusicManager with fades of 0 and in-memory streams (no audio files): crossfade, push/pop,
## jingles, and not restarting the track already playing.

var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _music: MusicManager


func before_each() -> void:
	_music = MusicManager.new()
	_tree.root.add_child(_music)


func after_each() -> void:
	_tree.root.remove_child(_music)
	_music.free()


## A silent looping stream `seconds` long, built in memory.
static func silent_stream(seconds: float, loop: bool = true) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	wav.stereo = false
	var data: PackedByteArray = PackedByteArray()
	data.resize(int(seconds * wav.mix_rate))
	data.fill(0)
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = data.size()
	return wav


static func track(seconds: float = 30.0) -> MusicTrack:
	var t: MusicTrack = MusicTrack.new()
	t.stream = silent_stream(seconds)
	t.volume_db = -3.0
	return t


func test_one_player_audible_after_crossfade() -> void:
	var a: MusicTrack = track()
	var b: MusicTrack = track()
	_music.play(a, 0.0)
	assert_eq(_music.audible_players().size(), 1, "one player for the first track")
	_music.play(b, 0.0)
	var audible: Array[AudioStreamPlayer] = _music.audible_players()
	assert_eq(audible.size(), 1, "exactly one audible player after the crossfade")
	assert_eq(_music.current_track, b)
	if audible.size() == 1:
		assert_eq(audible[0].stream, b.stream)
		assert_almost_eq(audible[0].volume_db, -3.0, 0.01, "at the track volume")


func test_same_track_is_not_restarted() -> void:
	var a: MusicTrack = track()
	_music.play(a, 0.0)
	var player: AudioStreamPlayer = _music.active_player()
	player.seek(4.0)
	_music.play(a, 0.0)
	assert_eq(_music.active_player(), player, "same player")
	assert_almost_eq(_music.current_position(), 4.0, 0.25, "not restarted")


func test_push_pop_restores_track_and_position() -> void:
	var field: MusicTrack = track()
	var battle: MusicTrack = track()
	_music.play(field, 0.0)
	_music.active_player().seek(7.5)
	_music.push(battle, 0.0)
	assert_eq(_music.current_track, battle, "battle music during the push")
	assert_eq(_music.stack_depth(), 1)
	assert_eq(_music.audible_players().size(), 1)
	_music.pop(0.0)
	assert_eq(_music.current_track, field, "field music is back")
	assert_eq(_music.stack_depth(), 0)
	assert_almost_eq(_music.current_position(), 7.5, 0.25, "at the stored position")
	assert_eq(_music.audible_players().size(), 1)


func test_pop_from_start_without_resume() -> void:
	var field: MusicTrack = track()
	field.resume_on_return = false
	_music.play(field, 0.0)
	_music.active_player().seek(7.5)
	_music.push(track(), 0.0)
	_music.pop(0.0)
	assert_almost_eq(_music.current_position(), 0.0, 0.25, "restarted from the top")


func test_push_null_silences_and_pop_restores() -> void:
	var field: MusicTrack = track()
	_music.play(field, 0.0)
	_music.push(null, 0.0)
	assert_eq(_music.audible_players().size(), 0, "silent battle")
	_music.pop(0.0)
	assert_eq(_music.current_track, field)
	assert_eq(_music.audible_players().size(), 1)


func test_play_jingle_emits_jingle_finished() -> void:
	var done: Array[bool] = []
	_music.jingle_finished.connect(func() -> void: done.append(true))
	_music.play(track(), 0.0)
	_music.play_jingle(silent_stream(0.2, false), 0.0)
	assert_eq(_music.audible_players().size(), 0, "music is silenced under the jingle")
	var frames: int = 0
	while done.is_empty() and frames < 300:
		await _tree.process_frame
		frames += 1
	assert_eq(done.size(), 1, "jingle_finished emitted once")
	_music.play_jingle(null)
	await _tree.process_frame
	assert_eq(done.size(), 2, "a null jingle finishes on the next frame")


func test_pop_stops_a_running_jingle() -> void:
	var done: Array[bool] = []
	_music.jingle_finished.connect(func() -> void: done.append(true))
	var field: MusicTrack = track()
	_music.play(field, 0.0)
	_music.push(track(), 0.0)
	_music.play_jingle(silent_stream(5.0, false), 0.0)
	_music.pop(0.0)
	assert_false(_music.is_jingle_playing(), "jingle stopped")
	assert_eq(_music.current_track, field)
	await _tree.process_frame
	assert_eq(done.size(), 0, "a stopped jingle never reports finishing")


func test_play_null_stops() -> void:
	_music.play(track(), 0.0)
	_music.play(null, 0.0)
	assert_null(_music.current_track)
	assert_eq(_music.audible_players().size(), 0)


func test_default_fades_use_the_tracks_fade_times() -> void:
	var a: MusicTrack = track()
	a.fade_in = 4.0
	a.fade_out = 2.5
	_music.play(a)
	var player: AudioStreamPlayer = _music.active_player()
	var tween: Tween = _music._tweens.get(player) as Tween
	assert_not_null(tween, "fades in")
	tween.custom_step(2.0)
	assert_true(player.volume_db < a.volume_db - 1.0, "still fading in after 2 s of 4 s (%.1f dB)" % player.volume_db)
	tween.custom_step(2.1)
	assert_almost_eq(player.volume_db, a.volume_db, 0.01, "at the track volume after fade_in")
	_music.stop()
	var out: Tween = _music._tweens.get(player) as Tween
	out.custom_step(1.25)
	assert_true(player.playing, "still fading out halfway through fade_out")
	out.custom_step(1.3)
	assert_false(player.playing, "stopped after fade_out")


func test_fades_are_linear_in_amplitude() -> void:
	var a: MusicTrack = track()
	a.volume_db = 0.0
	_music.play(a, 2.0)
	var player: AudioStreamPlayer = _music.active_player()
	(_music._tweens.get(player) as Tween).custom_step(1.0)
	# Halfway through an amplitude fade is about -6 dB; a dB-linear fade from -80 would be -40.
	assert_true(player.volume_db > -12.0 and player.volume_db < -3.0, "audible halfway (%.1f dB)" % player.volume_db)


func test_new_track_never_takes_over_a_fading_out_player() -> void:
	var a: MusicTrack = track()
	_music.play(a, 0.0)
	var fading: AudioStreamPlayer = _music.active_player()
	_music.stop(2.0)
	_music.play(track(), 2.0)
	assert_ne(_music.active_player(), fading, "the new track uses the other player")
	assert_true(fading.playing, "the old track keeps fading out")
