class_name EncounterZone
extends Area2D
## A region where random encounters happen (PROJECT_PLAN.md §6.2), using `table`. Zones may
## overlap: the player's EncounterTracker uses the innermost (last entered) one.
## Physics layer 5 `triggers`, watching layer 3 `player`. Put zones under the map's `Encounters`.

const GROUP: StringName = &"encounter_zones"

@export var table: EncounterTable
## Zone outline in local coordinates (copied to the child CollisionPolygon2D on ready).
@export var polygon: PackedVector2Array = PackedVector2Array()

@onready var _shape: CollisionPolygon2D = %Shape


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if not polygon.is_empty():
		_shape.polygon = polygon
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Name shown by the debug overlay: the table id, or the node name without a table.
func zone_id() -> StringName:
	return table.id if table != null and not table.id.is_empty() else StringName(name)


## True when a global point lies inside the zone outline.
func contains_point(global_point: Vector2) -> bool:
	var outline: PackedVector2Array = polygon if not polygon.is_empty() else _shape.polygon
	if outline.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(global_transform.affine_inverse() * global_point, outline)


func _on_body_entered(body: Node2D) -> void:
	var tracker: EncounterTracker = _tracker_of(body)
	if tracker != null:
		tracker.enter_zone(self)


func _on_body_exited(body: Node2D) -> void:
	var tracker: EncounterTracker = _tracker_of(body)
	if tracker != null:
		tracker.exit_zone(self)


func _tracker_of(body: Node2D) -> EncounterTracker:
	var player: PlayerController = body as PlayerController
	return player.encounter_tracker if player != null else null
