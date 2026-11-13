class_name FollowCamera
extends Camera2D
## Exploration camera, a child of the player (PROJECT_PLAN.md §3 and §6.1).
## Smoothly follows its parent and never shows anything outside the map's camera bounds.
## `process_callback` is Physics in player.tscn: with physics interpolation on (project setting),
## player and camera then move in step and the Knight does not jitter against the background.

## Default exploration zoom (tunable 0.6–1.0): about 20×11 tiles at 1920×1080.
const DEFAULT_ZOOM: float = 0.75

## Exploration zoom (< 1 shows more of the map).
@export_range(0.6, 1.0, 0.05) var zoom_level: float = DEFAULT_ZOOM
## Follow smoothing speed (higher = snappier).
@export var follow_speed: float = 6.0


func _ready() -> void:
	zoom = Vector2(zoom_level, zoom_level)
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed
	make_current()


## Clamps the camera to a world-space rectangle (from `Map.get_camera_bounds()`) and snaps to
## the target so the first frame after a map load does not glide in from elsewhere.
func apply_bounds(bounds: Rect2) -> void:
	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)
	reset_smoothing()
	reset_physics_interpolation()
