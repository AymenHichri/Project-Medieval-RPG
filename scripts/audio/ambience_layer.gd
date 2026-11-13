class_name AmbienceLayer
extends Resource
## One looping bed in an AmbienceProfile, plus optional random one-shots (crows, distant bells).

@export var stream: AudioStream
@export_range(-40.0, 6.0, 0.5) var volume_db: float = -6.0
@export var random_oneshots: Array[AudioStream] = []
## Seconds between one-shots (x = min, y = max).
@export var oneshot_interval: Vector2 = Vector2(8.0, 20.0)
