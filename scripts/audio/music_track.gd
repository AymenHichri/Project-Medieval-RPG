class_name MusicTrack
extends Resource
## A piece of music played by MusicManager. Looping is configured on the stream's import settings.

@export var stream: AudioStream
@export_range(-40.0, 6.0, 0.5) var volume_db: float = 0.0
## When this track is interrupted by `MusicManager.push()` (e.g. a battle), resume where it stopped.
@export var resume_on_return: bool = true
@export_range(0.0, 10.0, 0.05) var fade_in: float = 1.0
@export_range(0.0, 10.0, 0.05) var fade_out: float = 1.0
