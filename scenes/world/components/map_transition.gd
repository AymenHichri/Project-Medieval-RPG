class_name MapTransition
extends Area2D
## Trigger area at a map exit that sends the player to a spawn point in another map
## (PROJECT_PLAN.md §6.1). The target spawn must sit clear of the target map's own exits, so
## arriving never re-triggers a transition (checked by tests/smoke/test_map_links.gd).
## Physics layer 5 `triggers`, watching layer 3 `player`.

const GROUP: StringName = &"map_transitions"

## Scene path of the map to load.
@export_file("*.tscn") var target_map: String = ""
## `SpawnPoint.spawn_id` in the target map.
@export var target_spawn: StringName = &""
## Size of the trigger rectangle (px), centred on this node.
@export var size: Vector2 = Vector2(256, 96)
## Named SFX library sound played as the player goes through (Phase 9: `door` for doors and
## gates; empty = none, e.g. an open road).
@export var sound: StringName = &""

@onready var _shape: CollisionShape2D = %Shape


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	(_shape.shape as RectangleShape2D).size = size
	body_entered.connect(_on_body_entered)


## The trigger rectangle in global coordinates.
func get_global_rect() -> Rect2:
	return Rect2(global_position - size / 2.0, size)


func _on_body_entered(body: Node2D) -> void:
	var player: PlayerController = body as PlayerController
	if player == null or not player.input_enabled or SceneManager.is_transitioning:
		return
	if not sound.is_empty():
		AudioManager.sfx.play_ui_named(sound)
	# Deferred: the old map is freed during the change, which is not allowed inside a
	# physics callback such as body_entered.
	SceneManager.change_map.call_deferred(target_map, target_spawn)
