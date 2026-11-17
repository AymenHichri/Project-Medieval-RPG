extends TestCase
## The generated audio data (PROJECT_PLAN.md Phase 7A, tools/build_audio.gd): every Resource under
## data/audio loads; every SfxSet has a stream and frequent sets vary (≥ 3 variants or ≥ ±5 %
## pitch); music and ambience loop and jingles don't; every file under assets/audio is used.

const DATA_DIR: String = "res://data/audio"
const AUDIO_DIR: String = "res://assets/audio"
## Sets played often enough that repeats must not sound mechanical (AUDIO_GUIDELINES.md §4).
const FREQUENT_PREFIXES: Array[String] = ["sfx_ui_focus", "sfx_ui_tick", "sfx_footsteps_", "sfx_combat_hit"]


func _files(dir_path: String, extensions: Array[String], out: Array[String]) -> Array[String]:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return out
	for file: String in dir.get_files():
		if file.get_extension() in extensions:
			out.append(dir_path.path_join(file))
	for sub: String in dir.get_directories():
		_files(dir_path.path_join(sub), extensions, out)
	return out


func _resources() -> Array[Resource]:
	var out: Array[Resource] = []
	for path: String in _files(DATA_DIR, ["tres"], []):
		out.append(load(path))
	return out


func test_every_resource_loads() -> void:
	for path: String in _files(DATA_DIR, ["tres"], []):
		assert_not_null(load(path), path)


func test_sfx_sets_have_streams_and_vary() -> void:
	for res: Resource in _resources():
		var sfx: SfxSet = res as SfxSet
		if sfx == null:
			continue
		var id: String = sfx.resource_path.get_file().get_basename()
		assert_true(sfx.streams.size() >= 1, "%s has a stream" % id)
		for stream: AudioStream in sfx.streams:
			assert_not_null(stream, "%s: every variant loads" % id)
		assert_true(sfx.pitch_range.x <= sfx.pitch_range.y, "%s: pitch range ordered" % id)
		for prefix: String in FREQUENT_PREFIXES:
			if id.begins_with(prefix):
				var spread: float = (sfx.pitch_range.y - sfx.pitch_range.x) / (sfx.pitch_range.y + sfx.pitch_range.x)
				assert_true(sfx.streams.size() >= 3 or spread >= 0.05,
						"%s: ≥ 3 variants or ±5 %% pitch (%d, ±%.1f %%)" % [id, sfx.streams.size(), spread * 100.0])


func test_music_loops_and_jingles_do_not() -> void:
	for res: Resource in _resources():
		var track: MusicTrack = res as MusicTrack
		if track == null:
			continue
		var id: String = track.resource_path.get_file().get_basename()
		assert_not_null(track.stream, "%s has a stream" % id)
		var ogg: AudioStreamOggVorbis = track.stream as AudioStreamOggVorbis
		if ogg == null:
			continue
		if id.begins_with("jng_"):
			assert_false(ogg.loop, "%s is a one-shot" % id)
			assert_true(ogg.get_length() <= 10.5, "%s ≤ 10 s (%.1f s)" % [id, ogg.get_length()])
		else:
			assert_true(ogg.loop, "%s loops" % id)
			assert_true(ogg.loop_offset < ogg.get_length(), "%s: loop offset inside the track" % id)
	for res: Resource in _resources():
		var profile: AmbienceProfile = res as AmbienceProfile
		if profile != null:
			for layer: AmbienceLayer in profile.layers:
				var bed: AudioStreamOggVorbis = layer.stream as AudioStreamOggVorbis
				if bed != null:
					assert_true(bed.loop, "%s: ambience beds loop" % profile.resource_path)


func test_battle_music_is_long_enough() -> void:
	var path: String = DATA_DIR.path_join("music/mus_battle.tres")
	if not ResourceLoader.exists(path):
		return
	var track: MusicTrack = load(path) as MusicTrack
	assert_true(track.stream.get_length() >= 60.0, "battle loop ≥ 60 s (AUDIO_GUIDELINES.md §4)")


func test_no_orphan_audio_files() -> void:
	var used: Dictionary[String, bool] = {}
	for path: String in _files(DATA_DIR, ["tres"], []):
		for dep: String in ResourceLoader.get_dependencies(path):
			used[dep.get_slice("::", dep.get_slice_count("::") - 1)] = true
	for file: String in _files(AUDIO_DIR, ["ogg", "wav"], []):
		assert_true(used.has(file), "%s is used by a Resource in data/audio" % file)
