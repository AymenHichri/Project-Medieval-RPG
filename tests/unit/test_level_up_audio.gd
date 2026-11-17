extends TestCase
## Level-up jingle (PROJECT_PLAN.md Phase 7A): a victory whose reward levels the Knight plays
## `SceneManager.level_up_jingle` after the victory jingle; a victory without a level-up doesn't.
## In-memory silent streams; SceneManager's handlers are driven directly (no battle scene).

const MusicTest: GDScript = preload("res://tests/unit/test_music_manager.gd")

var _saved_party: Party
var _saved: Array = []
var _victory: AudioStreamWAV
var _level_up: AudioStreamWAV


func before_each() -> void:
	_saved_party = GameState.party
	GameState.party = Party.new()
	GameState.ensure_party()
	_saved = [SceneManager.victory_jingle, SceneManager.level_up_jingle, SceneManager.in_battle]
	_victory = MusicTest.silent_stream(0.5, false)
	_level_up = MusicTest.silent_stream(0.3, false)
	SceneManager.victory_jingle = _victory
	SceneManager.level_up_jingle = _level_up
	SceneManager.in_battle = true


func after_each() -> void:
	AudioManager.music.stop_jingle()
	SceneManager.victory_jingle = _saved[0]
	SceneManager.level_up_jingle = _saved[1]
	SceneManager.in_battle = _saved[2]
	SceneManager._level_up_pending = false
	GameState.party = _saved_party


func _victory_result(xp: int) -> BattleResult:
	var result: BattleResult = BattleResult.new()
	result.outcome = BattleEngine.Outcome.VICTORY
	result.xp = xp
	result.xp_per_member = xp
	result.survivors = GameState.party.combatants()
	return result


func test_level_up_jingle_follows_the_victory_jingle() -> void:
	var result: BattleResult = _victory_result(10000)
	assert_false(GameState.preview_level_ups(result).is_empty(), "the reward levels the Knight")
	SceneManager._on_battle_victory(result)
	assert_eq(AudioManager.music.jingle_player.stream, _victory, "the victory jingle plays first")
	AudioManager.music.jingle_finished.emit()
	assert_eq(AudioManager.music.jingle_player.stream, _level_up, "then the level-up jingle")
	assert_false(SceneManager._level_up_pending)


func test_no_level_up_jingle_without_a_level_up() -> void:
	var result: BattleResult = _victory_result(1)
	assert_true(GameState.preview_level_ups(result).is_empty())
	SceneManager._on_battle_victory(result)
	AudioManager.music.jingle_finished.emit()
	assert_eq(AudioManager.music.jingle_player.stream, _victory, "only the victory jingle")


func test_level_up_jingle_alone_when_there_is_no_victory_jingle() -> void:
	SceneManager.victory_jingle = null
	SceneManager._on_battle_victory(_victory_result(10000))
	assert_eq(AudioManager.music.jingle_player.stream, _level_up)


func test_jingles_are_loaded_from_the_audio_data() -> void:
	if not ResourceLoader.exists(SceneManager.JINGLE_PATHS[&"victory"]):
		print("  skipped: audio not built (tools/import_audio.py, tools/build_audio.gd)")
		return
	assert_not_null(_saved[0], "victory jingle loaded")
	assert_not_null(_saved[1], "level-up jingle loaded")
	assert_not_null(SceneManager.game_over_jingle, "game over jingle loaded")
