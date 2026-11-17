extends TestCase
## Slice audio coverage (PROJECT_PLAN.md Phase 7A; extended to the full game in Phase 12): every
## hook-up point of AUDIO_CATALOG.md §D that has an approved source points to a real stream.
## Skipped with a notice while assets/audio is empty (a clone without the source zips).
## Not covered yet, because the supplied packs have no source for them: footsteps, combat and
## monster sounds, ambience beds (docs/AUDIO_REQUIREMENTS.md).

const AUDIO_DIR: String = "res://assets/audio/music"


func _built() -> bool:
	var dir: DirAccess = DirAccess.open(AUDIO_DIR)
	if dir == null or dir.get_files().is_empty():
		print("  skipped: assets/audio is empty (run tools/import_audio.py and tools/build_audio.gd)")
		return false
	return true


func _music_of_scene(path: String) -> MusicTrack:
	var scene: Node = (load(path) as PackedScene).instantiate()
	var track: MusicTrack = scene.get(&"music") as MusicTrack
	scene.free()
	return track


func _assert_track(track: MusicTrack, what: String) -> void:
	assert_not_null(track, "%s has music" % what)
	if track != null:
		assert_not_null(track.stream, "%s: the stream loads" % what)


func test_music_hooks() -> void:
	if not _built():
		return
	_assert_track(_music_of_scene("res://scenes/ui/title_screen.tscn"), "title screen")
	_assert_track(_music_of_scene("res://scenes/world/maps/village_01.tscn"), "village_01")
	_assert_track(_music_of_scene("res://scenes/world/maps/graveyard_01.tscn"), "graveyard_01")
	var table: EncounterTable = load("res://data/encounters/graveyard_outskirts.tres") as EncounterTable
	_assert_track(table.music, "graveyard encounters")
	assert_ne(table.music, _music_of_scene("res://scenes/world/maps/graveyard_01.tscn"), "battle has its own track")


func test_jingle_hooks() -> void:
	if not _built():
		return
	assert_not_null(SceneManager.victory_jingle, "victory jingle")
	assert_not_null(SceneManager.level_up_jingle, "level-up jingle")
	assert_not_null(SceneManager.game_over_jingle, "game over jingle")


func test_ui_and_field_sound_hooks() -> void:
	if not _built():
		return
	var library: SfxLibrary = AudioManager.sfx.library
	for sound: StringName in [&"focus", &"confirm", &"cancel", &"tick", &"open", &"reward_gold",
			&"reward_item", &"levelup", &"rest"]:
		var sfx: SfxSet = library.ui.get(sound) as SfxSet
		assert_true(sfx != null and not sfx.streams.is_empty(), "UI sound %s" % sound)
		if sfx != null:
			assert_eq(sfx.bus, "UI", "%s plays on the UI bus" % sound)


func test_pause_muffles_the_ambience() -> void:
	AudioManager.set_ambience_muffled(true)
	assert_true(AudioManager.is_ambience_muffled(), "low-pass on")
	AudioManager.set_ambience_muffled(false)
	assert_false(AudioManager.is_ambience_muffled(), "low-pass off")


func test_scene_music_is_read_without_instancing() -> void:
	var village: PackedScene = load("res://scenes/world/maps/village_01.tscn") as PackedScene
	assert_eq(SceneManager.scene_music(village), _music_of_scene("res://scenes/world/maps/village_01.tscn"))
	assert_null(SceneManager.scene_music(load("res://scenes/ui/game_over.tscn") as PackedScene), "no music property")
