class_name DebugOverlay
extends CanvasLayer
## F3 debug overlay for exploration maps (debug builds only; `Map` adds it).
## Shows FPS, the player's position and the current map / encounter zone.

## Shown when no encounter zone is active (zones arrive in Phase 6).
const NO_ZONE: String = "none"

## Id of the encounter zone the player is in; set by the EncounterTracker from Phase 6.
var current_zone: StringName = &""

var _map: Map

@onready var _panel: PanelContainer = %Panel
@onready var _label: Label = %Info


## Injects the map whose player is shown.
func setup(map: Map) -> void:
	_map = map


func _ready() -> void:
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F3:
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _panel.visible:
		_label.text = build_text()


## The overlay text (public so tests can check it without rendering).
func build_text() -> String:
	var lines: PackedStringArray = ["FPS %d" % Engine.get_frames_per_second()]
	if _map != null:
		lines.append("Map %s" % _map.map_id)
		if _map.player != null:
			var pos: Vector2 = _map.player.global_position
			lines.append("Player %d, %d  facing %s" % [roundi(pos.x), roundi(pos.y), _map.player.facing])
	lines.append("Zone %s" % (NO_ZONE if current_zone.is_empty() else String(current_zone)))
	return "\n".join(lines)
