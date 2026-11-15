class_name DebugOverlay
extends CanvasLayer
## F3 debug overlay for exploration maps (debug builds only; `Map` adds it).
## Shows FPS, the player's position, the current map / encounter zone and the step counter.
## F4 turns random encounters on/off, F5 forces an encounter in the current zone.

## Shown when the player is in no encounter zone.
const NO_ZONE: String = "none"

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
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_F3:
			_panel.visible = not _panel.visible
		KEY_F4:
			EncounterTracker.encounters_enabled = not EncounterTracker.encounters_enabled
			print("debug: random encounters %s" % ("on" if EncounterTracker.encounters_enabled else "off"))
		KEY_F5:
			var tracker: EncounterTracker = _tracker()
			if tracker == null or not _map.player.can_act() or not tracker.force_encounter():
				print("debug: no encounter here (not in an encounter zone, or busy)")
		_:
			return
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
	var tracker: EncounterTracker = _tracker()
	var zone: EncounterZone = tracker.current_zone() if tracker != null else null
	lines.append("Zone %s" % (NO_ZONE if zone == null else String(zone.zone_id())))
	if tracker != null:
		lines.append("Steps %d (since battle %d)  encounters %s  rate ×%.2f" % [tracker.total_steps,
			tracker.steps_since_last, "on" if EncounterTracker.encounters_enabled else "off",
			GameState.get_encounter_multiplier()])
	return "\n".join(lines)


func _tracker() -> EncounterTracker:
	if _map == null or _map.player == null:
		return null
	return _map.player.encounter_tracker
