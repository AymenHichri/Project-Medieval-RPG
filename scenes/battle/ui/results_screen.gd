class_name ResultsScreen
extends Control
## Victory summary (PROJECT_PLAN.md §6.5): experience, gold, the items found and the level-ups.
## `await show_result(result)` returns on `accept`.

signal continued

## Ignore `accept` for this long after opening, so a held key doesn't skip the screen.
const INPUT_DELAY_SECONDS: float = 0.4
const REWARD_SOUND_GAP_SECONDS: float = 0.3

var _opened_at: int = 0

@onready var _xp: Label = %Experience
@onready var _gold: Label = %Gold
@onready var _drops: Label = %Drops
@onready var _level_ups: Label = %LevelUps


func _ready() -> void:
	visible = false


## Fills the panel from `result`; `level_lines` are the level-up messages ("Knight reached
## level 2!"). `instant` skips waiting for the player.
func show_result(result: BattleResult, instant: bool = false, level_lines: PackedStringArray = []) -> void:
	_xp.text = "Experience  +%d" % result.xp
	_gold.text = "Gold  +%d" % result.gold
	_drops.text = drops_text(result.drops)
	_drops.visible = not _drops.text.is_empty()
	_level_ups.text = "\n".join(level_lines)
	_level_ups.visible = not level_lines.is_empty()
	visible = true
	if instant:
		return
	_play_reward_sounds(result, not level_lines.is_empty())
	_opened_at = Time.get_ticks_msec()
	await continued


## Gold, then any items, then the level-up accent, a beat apart (UI sounds; silent when missing).
func _play_reward_sounds(result: BattleResult, leveled: bool) -> void:
	var sounds: Array[StringName] = []
	if result.gold > 0:
		sounds.append(&"reward_gold")
	if not result.drops.is_empty():
		sounds.append(&"reward_item")
	if leveled:
		sounds.append(&"levelup")
	for i: int in sounds.size():
		if i > 0:
			await get_tree().create_timer(REWARD_SOUND_GAP_SECONDS).timeout
		if not visible:
			return
		AudioManager.sfx.play_ui_named(sounds[i])


func experience_text() -> String:
	return _xp.text


func level_up_text() -> String:
	return _level_ups.text


## "Found: Minor Potion ×2, …" (empty when nothing dropped).
static func drops_text(drops: Array[ItemData]) -> String:
	if drops.is_empty():
		return ""
	var counts: Dictionary[String, int] = {}
	for item: ItemData in drops:
		counts[item.display_name] = counts.get(item.display_name, 0) + 1
	var parts: PackedStringArray = []
	for item_name: String in counts:
		parts.append("%s ×%d" % [item_name, counts[item_name]])
	return "Found: " + ", ".join(parts)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event.is_action_pressed(&"accept") or event.is_action_pressed(&"ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if Time.get_ticks_msec() - _opened_at >= INPUT_DELAY_SECONDS * 1000.0:
		continued.emit()
