extends TestCase
## SFXManager (Phase 7, AUDIO_GUIDELINES.md §5): pools never grow, world sounds never take a UI
## voice, cooldowns suppress duplicates, pitch stays in range, footsteps fall back to stone.

const MusicTest: GDScript = preload("res://tests/unit/test_music_manager.gd")

var _sfx: SFXManager
var _now: Array[int] = [100000]
var _saved_clock: Callable
var _saved_library: SfxLibrary


func before_each() -> void:
	_sfx = AudioManager.sfx
	_sfx.stop_all()
	_saved_clock = _sfx.clock
	_saved_library = _sfx.library
	_now[0] = 100000
	_sfx.clock = func() -> int: return _now[0]
	_sfx.rng.seed = 4


func after_each() -> void:
	_sfx.stop_all()
	_sfx.clock = _saved_clock
	_sfx.library = _saved_library


func _make_set(variants: int = 2, cooldown_ms: int = 0, pitch: Vector2 = Vector2(0.9, 1.1)) -> SfxSet:
	var sfx: SfxSet = SfxSet.new()
	for i: int in variants:
		sfx.streams.append(MusicTest.silent_stream(5.0, false))
	sfx.cooldown_ms = cooldown_ms
	sfx.pitch_range = pitch
	return sfx


func test_world_pool_never_exceeds_its_size() -> void:
	var sfx: SfxSet = _make_set()
	for i: int in SFXManager.WORLD_POOL_SIZE * 3:
		_now[0] += 1
		assert_not_null(_sfx.play_at(sfx, Vector2(i, 0)), "play %d gets a voice (stealing when full)" % i)
	assert_eq(_sfx.world_pool.size(), SFXManager.WORLD_POOL_SIZE)
	assert_true(_sfx.busy_count(_sfx.world_pool) <= SFXManager.WORLD_POOL_SIZE)
	assert_eq(_sfx.get_child_count(), SFXManager.WORLD_POOL_SIZE + SFXManager.UI_POOL_SIZE, "no extra players")


func test_full_world_pool_steals_the_oldest_voice() -> void:
	var sfx: SfxSet = _make_set()
	var first: AudioStreamPlayer2D = null
	for i: int in SFXManager.WORLD_POOL_SIZE:
		_now[0] += 10
		var voice: AudioStreamPlayer2D = _sfx.play_at(sfx, Vector2.ZERO)
		if i == 0:
			first = voice
	_now[0] += 10
	assert_eq(_sfx.play_at(sfx, Vector2.ZERO), first, "the oldest voice is reused")


func test_ui_voices_are_never_stolen_by_world_sounds() -> void:
	var ui: SfxSet = _make_set()
	var world: SfxSet = _make_set()
	var ui_voices: Array[AudioStreamPlayer] = []
	for i: int in SFXManager.UI_POOL_SIZE:
		_now[0] += 1
		ui_voices.append(_sfx.play_ui(ui))
	for i: int in SFXManager.WORLD_POOL_SIZE * 2:
		_now[0] += 1
		var voice: Node = _sfx.play_at(world, Vector2.ZERO)
		assert_false(_sfx.ui_pool.any(func(p: AudioStreamPlayer) -> bool: return p == voice), "a world sound took a UI voice")
	for voice: AudioStreamPlayer in ui_voices:
		assert_true(voice.playing, "UI voice still playing")
		assert_eq(voice.bus, &"UI")
	_now[0] += 1
	assert_not_null(_sfx.play_ui(ui), "a UI sound is never dropped, even with a full UI pool")


func test_cooldown_suppresses_duplicates() -> void:
	var sfx: SfxSet = _make_set(1, 100)
	assert_not_null(_sfx.play_ui(sfx))
	_now[0] += 40
	assert_null(_sfx.play_ui(sfx), "within cooldown_ms")
	_now[0] += 61
	assert_not_null(_sfx.play_ui(sfx), "after cooldown_ms")
	var other: SfxSet = _make_set(1, 100)
	assert_not_null(_sfx.play_ui(other), "cooldowns are per set")


func test_pitch_stays_in_range_and_variants_vary() -> void:
	var sfx: SfxSet = _make_set(3, 0, Vector2(0.8, 1.2))
	var streams_seen: Array[AudioStream] = []
	for i: int in 200:
		_now[0] += 1
		var voice: AudioStreamPlayer2D = _sfx.play_at(sfx, Vector2.ZERO)
		assert_true(voice.pitch_scale >= 0.8 and voice.pitch_scale <= 1.2, "pitch %f" % voice.pitch_scale)
		if not voice.stream in streams_seen:
			streams_seen.append(voice.stream)
	assert_eq(streams_seen.size(), 3, "every variant is used")


func test_unknown_surface_falls_back_to_stone() -> void:
	var library: SfxLibrary = SfxLibrary.new()
	var stone: SfxSet = _make_set()
	var grass: SfxSet = _make_set()
	library.footsteps = {&"stone": stone, &"grass": grass}
	_sfx.library = library
	assert_eq(_sfx.footstep_set_for(&"grass"), grass)
	assert_eq(_sfx.footstep_set_for(&"lava"), stone, "unknown surface → stone")
	assert_eq(_sfx.footstep_set_for(&""), stone, "no surface → stone")
	assert_not_null(_sfx.play_footstep(&"lava", Vector2(5, 5)))


func test_empty_sets_are_silent() -> void:
	assert_null(_sfx.play_ui(null))
	assert_null(_sfx.play_ui(SfxSet.new()), "a set without streams plays nothing")
	_sfx.library = SfxLibrary.new()
	assert_null(_sfx.play_ui_named(&"confirm"), "no library entry")
	assert_null(_sfx.play_footstep(&"grass", Vector2.ZERO))
