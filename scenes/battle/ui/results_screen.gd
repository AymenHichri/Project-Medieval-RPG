class_name ResultsScreen
extends Control
## Victory summary (PROJECT_PLAN.md §6.5): experience, gold and the items found. Level-ups are
## listed once Progression exists (Phase 7). `await show_result(result)` returns on `accept`.

signal continued

## Ignore `accept` for this long after opening, so a held key doesn't skip the screen.
const INPUT_DELAY_SECONDS: float = 0.4

var _opened_at: int = 0

@onready var _xp: Label = %Experience
@onready var _gold: Label = %Gold
@onready var _drops: Label = %Drops


func _ready() -> void:
	visible = false


## Fills the panel from `result`. `instant` skips waiting for the player.
func show_result(result: BattleResult, instant: bool = false) -> void:
	_xp.text = "Experience  +%d" % result.xp
	_gold.text = "Gold  +%d" % result.gold
	_drops.text = drops_text(result.drops)
	_drops.visible = not _drops.text.is_empty()
	visible = true
	if instant:
		return
	_opened_at = Time.get_ticks_msec()
	await continued


func experience_text() -> String:
	return _xp.text


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
