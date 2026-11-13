class_name InteractionProbe
extends Area2D
## Area in front of the player's feet that finds Interactables (PROJECT_PLAN.md §6.1).
## Each physics frame it moves to the facing side, focuses the nearest overlapping
## Interactable (showing its prompt) and, on `accept`, interacts with it.
## Must be a child of the PlayerController. Watches physics layer 4 `interactables`.

## Distance (px) from the feet to the probe centre, along the facing direction.
const REACH: float = 56.0

## The focused Interactable, or null.
var target: Interactable

@onready var _player: PlayerController = get_parent() as PlayerController


func _physics_process(_delta: float) -> void:
	position = PlayerController.vector_from_dir(_player.facing) * REACH
	_set_target(_find_nearest() if _player.can_act() else null)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"accept") and not event.is_echo() and try_interact():
		get_viewport().set_input_as_handled()


## Interacts with the focused target. Returns false when there is none or the player can't act.
func try_interact() -> bool:
	if target == null or not is_instance_valid(target) or not _player.can_act():
		return false
	var current: Interactable = target
	_set_target(null)  # the prompt hides while the dialogue is open
	current.interact(_player)
	return true


func _find_nearest() -> Interactable:
	var best: Interactable = null
	var best_distance: float = INF
	for area: Area2D in get_overlapping_areas():
		var candidate: Interactable = area as Interactable
		if candidate == null:
			continue
		var distance: float = global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func _set_target(new_target: Interactable) -> void:
	if new_target == target:
		return
	if target != null and is_instance_valid(target):
		target.set_focused(false)
	target = new_target
	if target != null:
		target.set_focused(true)
