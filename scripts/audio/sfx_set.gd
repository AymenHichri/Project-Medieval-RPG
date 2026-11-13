class_name SfxSet
extends Resource
## A sound effect with variants. SFXManager picks a random variant and pitch on each play.

@export var streams: Array[AudioStream] = []
@export_range(-40.0, 6.0, 0.5) var volume_db: float = 0.0
## Random pitch scale range (x = min, y = max).
@export var pitch_range: Vector2 = Vector2(0.95, 1.05)
## Minimum milliseconds between two plays of this set (prevents stacking).
@export_range(0, 2000, 1) var cooldown_ms: int = 40
@export_enum("SFX", "UI") var bus: String = "SFX"
