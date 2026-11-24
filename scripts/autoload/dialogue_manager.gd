extends Node
## Autoload `DialogueManager`: runs JSON dialogues (`data/dialogue/*.json`) through a
## DialogueRunner and drives the dialogue box. Any node can call `start(id)`; the player can't move
## or interact while `is_active` is true (see `PlayerController.can_act()`).
## Supports multi-line text, speaker names, an optional portrait (passed by the NPC), choices,
## `goto`, `set_flag`, `give_item` and conditional entry (`conditions.if_flag` → `use`).
## `say(lines)` shows plain lines without a JSON file (Phase 9: chests, "Found 2 Minor Potion!").
## Phase 10: a line's `portrait` replaces the NPC's portrait for that line, and its `music` cue
## (`mus_story_*`) is pushed over the map music until the dialogue closes, then the map music
## returns. `start_quest`, `require_item` and `take_item` are run by the DialogueRunner.

signal dialogue_started(dialogue_id: StringName)
signal dialogue_finished(dialogue_id: StringName)
## Emitted when the box asks for the next line.
signal _advanced
## Emitted when a choice is picked.
signal _chosen(index: int)

const DIALOGUE_BOX: PackedScene = preload("res://scenes/ui/dialogue_box.tscn")

var is_active: bool = false
## The runner of the open dialogue (null when none).
var runner: DialogueRunner

var _box: DialogueBox
## True while a `music` cue of the open dialogue is pushed over the map music.
var _music_pushed: bool = false


func _ready() -> void:
	_box = DIALOGUE_BOX.instantiate() as DialogueBox
	add_child(_box)
	_box.advance_requested.connect(advance)
	_box.choice_selected.connect(choose)


## Runs a dialogue by id and returns when it is closed. Ignored while another one runs.
## `portrait` is shown beside every line that has a speaker.
func start(dialogue_id: StringName, portrait: Texture2D = null) -> void:
	if is_active:
		push_warning("DialogueManager: '%s' ignored, a dialogue is already open" % dialogue_id)
		return
	var opened: DialogueRunner = DialogueRunner.open(dialogue_id, GameState)
	if opened == null:
		return
	await _run(opened, portrait)


## Shows plain lines (no speaker) one after another and returns when they are closed. Ignored while
## another dialogue runs. `id` is what `dialogue_started`/`dialogue_finished` report.
func say(lines: PackedStringArray, id: StringName = &"message") -> void:
	if is_active:
		push_warning("DialogueManager: say() ignored, a dialogue is already open")
		return
	var entries: Array = []
	for line: String in lines:
		entries.append({"text": line})
	await _run(DialogueRunner.from_data({"id": String(id), "lines": entries}, GameState), null)


func _run(opened: DialogueRunner, portrait: Texture2D) -> void:
	runner = opened
	is_active = true
	dialogue_started.emit(runner.dialogue_id)
	while not runner.is_finished():
		var speaker: String = runner.speaker()
		var choices: PackedStringArray = runner.choices()
		_play_cue(runner.music_id())
		_box.show_line(speaker, runner.text(), line_portrait(runner, portrait), choices)
		if choices.is_empty():
			await _advanced
			runner.advance()
		else:
			var index: int = await _chosen
			runner.choose(index)
	var played: StringName = runner.dialogue_id
	runner = null
	_end_cue()
	_box.close()
	is_active = false
	dialogue_finished.emit(played)


## The portrait beside the runner's current line: its own `portrait` key, else `fallback` (the
## NPC's) when the line has a speaker, else none.
static func line_portrait(on: DialogueRunner, fallback: Texture2D) -> Texture2D:
	var portrait_id: String = on.portrait_id()
	if not portrait_id.is_empty():
		var path: String = DialogueData.portrait_path(portrait_id)
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return fallback if not on.speaker().is_empty() else null


## Plays a line's `music` cue over the map music (pushed once per dialogue; later cues replace it).
func _play_cue(cue: String) -> void:
	if cue.is_empty():
		return
	var track: MusicTrack = null
	if cue != DialogueData.MUSIC_STOP and ResourceLoader.exists(DialogueData.music_path(cue)):
		track = load(DialogueData.music_path(cue)) as MusicTrack
	if _music_pushed:
		AudioManager.music.play(track)
	else:
		AudioManager.music.push(track, track.fade_in if track != null else 0.4)
		_music_pushed = true


## Back to the music that played before the dialogue's cue.
func _end_cue() -> void:
	if _music_pushed:
		_music_pushed = false
		AudioManager.music.pop()


## True while a `music` cue of the open dialogue plays over the map music (tests).
func is_cue_playing() -> bool:
	return _music_pushed


## Moves past the current line (the box calls this on `accept`; tests call it directly).
## Ignored on a line with choices.
func advance() -> void:
	if is_active and runner != null and not runner.has_choices():
		_advanced.emit()


## Picks a choice of the current line (the box's buttons call this; tests call it directly).
func choose(index: int) -> void:
	if is_active and runner != null and runner.has_choices():
		_chosen.emit(index)


## The dialogue box (read-only use: tests and debugging).
func get_box() -> DialogueBox:
	return _box
