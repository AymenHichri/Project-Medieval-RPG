class_name TargetSelector
extends Control
## Chooses the target(s) of an action (PROJECT_PLAN.md Phase 5): Gimble's gauntlet cursor
## (2×, turned to point down) bobs over the candidate's head; left/right (or up/down) cycles, accept
## confirms, cancel backs out. In ALL mode every candidate gets a cursor and accept takes them all.
##
##   var targets: Array[Combatant] = await selector.choose(sprites, false)   # [] = cancelled

signal confirmed(targets: Array[Combatant])

const CURSOR: Texture2D = preload("res://assets/vendor/gimbles/ui/2x/cursors/cursor_gauntlet_16.png")
const CURSOR_SIZE: Vector2 = Vector2(32, 32)
## Fingertip of the 2× cursor once turned to point down (vendor hotspot (5, 0) at 1×, rotated 180°).
const CURSOR_TIP: Vector2 = Vector2(22, 32)
## Project movement action → its built-in `ui_*` twin.
const MOVES: Dictionary[StringName, StringName] = {
	&"move_left": &"ui_left", &"move_right": &"ui_right", &"move_up": &"ui_up", &"move_down": &"ui_down",
}
## Gap (px) between the cursor tip and the head, and the bob amplitude / speed.
const CURSOR_GAP: float = 12.0
const BOB_PIXELS: float = 6.0
const BOB_SPEED: float = 6.0
## Gap between the cursor and the name label above it.
const NAME_GAP: float = 8.0

var _candidates: Array[BattleSprite] = []
var _all: bool = false
var _index: int = 0
var _active: bool = false
var _cursors: Array[TextureRect] = []
var _time: float = 0.0

@onready var _name: Label = %TargetName


func _ready() -> void:
	set_process(false)
	_name.visible = false


## Waits for the player to pick among `candidates` (all of them when `all`). Empty = cancelled.
func choose(candidates: Array[BattleSprite], all: bool, start: int = 0) -> Array[Combatant]:
	if candidates.is_empty():
		return []
	_candidates = candidates.duplicate()
	_all = all
	_index = clampi(start, 0, candidates.size() - 1)
	_active = true
	_build_cursors()
	set_process(true)
	_update()
	var targets: Array[Combatant] = await confirmed
	return targets


func is_active() -> bool:
	return _active


## The combatant under the cursor (ONE mode).
func current() -> Combatant:
	return _candidates[_index].combatant if _active and not _candidates.is_empty() else null


## Applies a selector action as if pressed (`move_left/right/up/down`, `accept`, `cancel`).
func press(action: StringName) -> void:
	if not _active:
		return
	match action:
		&"move_left", &"move_up":
			_index = posmod(_index - 1, _candidates.size())
			_update()
		&"move_right", &"move_down":
			_index = posmod(_index + 1, _candidates.size())
			_update()
		&"accept":
			var picked: Array[Combatant] = []
			if _all:
				for sprite: BattleSprite in _candidates:
					picked.append(sprite.combatant)
			else:
				picked.append(_candidates[_index].combatant)
			_close(picked)
		&"cancel":
			_close([])


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	var action: StringName = &""
	for move: StringName in MOVES:
		if event.is_action_pressed(move, true) or event.is_action_pressed(MOVES[move], true):
			action = move
	if event.is_action_pressed(&"accept") or event.is_action_pressed(&"ui_accept"):
		action = &"accept"
	elif event.is_action_pressed(&"cancel") or event.is_action_pressed(&"ui_cancel"):
		action = &"cancel"
	if action == &"":
		return
	get_viewport().set_input_as_handled()
	press(action)


func _process(delta: float) -> void:
	_time += delta
	_update()


func _close(targets: Array[Combatant]) -> void:
	_active = false
	set_process(false)
	for cursor: TextureRect in _cursors:
		cursor.queue_free()
	_cursors.clear()
	_name.visible = false
	confirmed.emit(targets)


func _build_cursors() -> void:
	var count: int = _candidates.size() if _all else 1
	for i: int in count:
		var cursor: TextureRect = TextureRect.new()
		cursor.texture = CURSOR
		cursor.size = CURSOR_SIZE
		cursor.pivot_offset = CURSOR_SIZE / 2.0
		cursor.rotation = PI  # the art points up; turned over it points down at the head
		cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cursor)
		_cursors.append(cursor)


func _update() -> void:
	var bob: float = sin(_time * BOB_SPEED) * BOB_PIXELS
	for i: int in _cursors.size():
		var sprite: BattleSprite = _candidates[i] if _all else _candidates[_index]
		var tip: Vector2 = sprite.head_position() - Vector2(0, CURSOR_GAP - bob)
		_cursors[i].position = tip - CURSOR_TIP
	var focus: BattleSprite = _candidates[_index]
	_name.text = "All" if _all else focus.combatant.display_name
	_name.visible = true
	_name.reset_size()
	var anchor: Vector2 = focus.head_position() if not _all else _centre_of_candidates()
	_name.position = anchor - Vector2(_name.size.x / 2.0, CURSOR_GAP + CURSOR_SIZE.y + NAME_GAP + _name.size.y)


func _centre_of_candidates() -> Vector2:
	var total: Vector2 = Vector2.ZERO
	var top: float = INF
	for sprite: BattleSprite in _candidates:
		total += sprite.head_position()
		top = minf(top, sprite.head_position().y)
	return Vector2(total.x / _candidates.size(), top)
