extends SceneTree
## Generates the audio Resources from the files in res://assets/audio/ (PROJECT_PLAN.md Phase 7A):
##   godot --headless --path <project> -s res://tools/build_audio.gd
## - data/audio/music/<id>.tres: a MusicTrack per music file or jingle (assets/audio/music/<id>.ogg).
## - data/audio/sfx/<id>.tres: an SfxSet per sound, its variants grouped by the `_01.._nn` suffix.
## - data/audio/sfx_library.tres: the named UI sounds, footsteps by surface and shared battle sounds.
## The tables below hold the per-ID tuning (volume, pitch, cooldown). An ID whose files don't exist
## is skipped (no placeholder tones), so the tool can run at any time; the files come from
## tools/import_audio.py. Source of truth: re-running it overwrites the generated Resources.

const AUDIO_DIR: String = "res://assets/audio"
const MUSIC_OUT: String = "res://data/audio/music"
const SFX_OUT: String = "res://data/audio/sfx"
const LIBRARY_PATH: String = "res://data/audio/sfx_library.tres"

## Music and jingles: id → volume_db, fade_in, fade_out, resume_on_return (the loudness is set
## in the files by import_audio.py, so volume_db is only for balancing by ear). The fades are used
## on map changes and on the title (`MusicManager.play`/`stop` with their default fade).
const MUSIC: Dictionary = {
	&"mus_menu": [0.0, 3.0, 2.0, true],
	# Starts mid-phrase at full density: a long fade-in and 3 dB under the others.
	&"mus_town_hamlet": [-3.0, 4.0, 2.5, true],
	&"mus_dungeon_graveyard": [0.0, 4.0, 2.5, true],
	&"mus_battle": [0.0, 0.4, 1.0, false],
	&"jng_victory": [0.0, 0.0, 0.0, false],
	&"jng_gameover": [0.0, 0.0, 0.0, false],
	&"jng_levelup": [0.0, 0.0, 0.0, false],
}

## SFX sets: id (file prefix under assets/audio/sfx/<category>/) → volume_db, pitch min, pitch max,
## cooldown_ms, bus. The Kenney UI sounds are darkened in the files (pitched down, low-passed, a
## short room echo: `filters` in tools/audio_sources.csv), so only a small pitch spread is left here.
const SFX: Dictionary = {
	&"sfx_ui_focus": [-12.0, 0.96, 1.04, 40, "UI"],
	&"sfx_ui_confirm": [-10.0, 0.97, 1.03, 60, "UI"],
	&"sfx_ui_cancel": [-10.0, 0.96, 1.04, 60, "UI"],
	&"sfx_ui_tick": [-20.0, 0.95, 1.05, 30, "UI"],
	&"sfx_ui_open": [-8.0, 0.97, 1.03, 120, "UI"],
	&"sfx_ui_denied": [-12.0, 0.97, 1.03, 120, "UI"],
	&"sfx_reward_gold": [-8.0, 0.96, 1.04, 100, "UI"],
	&"sfx_reward_item": [-10.0, 0.96, 1.04, 100, "UI"],
	&"sfx_progress_levelup": [-6.0, 1.0, 1.0, 200, "UI"],
	&"sfx_progress_rest": [-8.0, 1.0, 1.0, 500, "UI"],
	# Footsteps by surface and battle sounds: no source yet (docs/AUDIO_REQUIREMENTS.md), so these
	# are skipped until their files exist.
	&"sfx_footsteps_stone": [-16.0, 0.92, 1.08, 60, "SFX"],
	&"sfx_footsteps_grass": [-16.0, 0.92, 1.08, 60, "SFX"],
	&"sfx_footsteps_mud": [-16.0, 0.92, 1.08, 60, "SFX"],
	&"sfx_footsteps_ash": [-16.0, 0.92, 1.08, 60, "SFX"],
	&"sfx_combat_crit": [-6.0, 0.95, 1.05, 40, "SFX"],
	&"sfx_combat_miss": [-8.0, 0.9, 1.1, 40, "SFX"],
	&"sfx_combat_defend": [-8.0, 0.95, 1.05, 80, "SFX"],
	&"sfx_battle_flee": [-8.0, 0.95, 1.05, 200, "SFX"],
}

## SfxLibrary entries: dictionary → key → SfxSet id.
const LIBRARY_UI: Dictionary = {
	&"focus": &"sfx_ui_focus", &"confirm": &"sfx_ui_confirm", &"cancel": &"sfx_ui_cancel",
	&"tick": &"sfx_ui_tick", &"open": &"sfx_ui_open", &"denied": &"sfx_ui_denied",
	&"reward_gold": &"sfx_reward_gold", &"reward_item": &"sfx_reward_item",
	&"levelup": &"sfx_progress_levelup", &"rest": &"sfx_progress_rest",
}
const LIBRARY_FOOTSTEPS: Dictionary = {
	&"stone": &"sfx_footsteps_stone", &"grass": &"sfx_footsteps_grass",
	&"mud": &"sfx_footsteps_mud", &"ash": &"sfx_footsteps_ash",
}
const LIBRARY_BATTLE: Dictionary = {
	&"crit": &"sfx_combat_crit", &"miss": &"sfx_combat_miss",
	&"defend": &"sfx_combat_defend", &"flee": &"sfx_battle_flee",
}

var _failed: bool = false
## Every audio file under AUDIO_DIR (res:// paths), filled once.
var _files: PackedStringArray = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(MUSIC_OUT)
	DirAccess.make_dir_recursive_absolute(SFX_OUT)
	_collect(AUDIO_DIR)
	var music_count: int = 0
	for id: StringName in MUSIC:
		if _build_music(id):
			music_count += 1
	var sets: Dictionary[StringName, SfxSet] = {}
	for id: StringName in SFX:
		var sfx: SfxSet = _build_sfx(id)
		if sfx != null:
			sets[id] = sfx
	_build_library(sets)
	print("audio resources %s: %d music, %d sfx sets" % ["FAILED" if _failed else "written", music_count, sets.size()])
	quit(1 if _failed else 0)


func _build_music(id: StringName) -> bool:
	var path: String = AUDIO_DIR.path_join("music/%s.ogg" % id)
	if not path in _files:
		print("  skip %s (no file)" % id)
		return false
	var settings: Array = MUSIC[id]
	var track: MusicTrack = MusicTrack.new()
	track.stream = load(path) as AudioStream
	track.volume_db = settings[0]
	track.fade_in = settings[1]
	track.fade_out = settings[2]
	track.resume_on_return = settings[3]
	_save(track, MUSIC_OUT.path_join("%s.tres" % id))
	return true


## The set's variants: every file named <id>_<nn>.wav (or <id>.wav) under assets/audio/sfx/.
func _build_sfx(id: StringName) -> SfxSet:
	var variants: PackedStringArray = []
	var pattern: RegEx = RegEx.create_from_string("^%s(_\\d+)?\\.(wav|ogg)$" % String(id))
	for file: String in _files:
		if file.begins_with(AUDIO_DIR.path_join("sfx")) and pattern.search(file.get_file()) != null:
			variants.append(file)
	if variants.is_empty():
		return null
	variants.sort()
	var settings: Array = SFX[id]
	var sfx: SfxSet = SfxSet.new()
	for file: String in variants:
		sfx.streams.append(load(file) as AudioStream)
	sfx.volume_db = settings[0]
	sfx.pitch_range = Vector2(settings[1], settings[2])
	sfx.cooldown_ms = settings[3]
	sfx.bus = settings[4]
	var out: String = SFX_OUT.path_join("%s.tres" % id)
	_save(sfx, out)
	return load(out) as SfxSet


func _build_library(sets: Dictionary[StringName, SfxSet]) -> void:
	var library: SfxLibrary = SfxLibrary.new()
	for key: StringName in LIBRARY_UI:
		if sets.has(LIBRARY_UI[key]):
			library.ui[key] = sets[LIBRARY_UI[key]]
	for key: StringName in LIBRARY_FOOTSTEPS:
		if sets.has(LIBRARY_FOOTSTEPS[key]):
			library.footsteps[key] = sets[LIBRARY_FOOTSTEPS[key]]
	for key: StringName in LIBRARY_BATTLE:
		if sets.has(LIBRARY_BATTLE[key]):
			library.battle[key] = sets[LIBRARY_BATTLE[key]]
	_save(library, LIBRARY_PATH)


func _collect(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	for file: String in dir.get_files():
		if file.get_extension() in ["wav", "ogg"]:
			_files.append(dir_path.path_join(file))
	for sub: String in dir.get_directories():
		_collect(dir_path.path_join(sub))


func _save(res: Resource, path: String) -> void:
	var err: Error = ResourceSaver.save(res, path)
	if err != OK:
		push_error("could not save %s: %s" % [path, error_string(err)])
		_failed = true
