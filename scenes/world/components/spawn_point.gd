@tool
class_name SpawnPoint
extends Marker2D
## Where the player appears when entering a map. `MapTransition`s (Phase 3) name a target
## spawn by `spawn_id`. Place it at the player's feet position.

const GROUP: StringName = &"spawn_points"

## Id used by `Map.get_spawn()` and by transitions (snake_case, unique per map).
@export var spawn_id: StringName = &"start"
## Direction the player faces on arrival: S, SE, E, NE, N, NW, W or SW.
@export_enum("S", "SE", "E", "NE", "N", "NW", "W", "SW") var facing: String = "S"


func _enter_tree() -> void:
	add_to_group(GROUP)
