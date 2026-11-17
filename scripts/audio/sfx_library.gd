class_name SfxLibrary
extends Resource
## The named sound sets SFXManager plays without being handed one: UI sounds and footsteps by
## TileSet `surface` (AUDIO_GUIDELINES.md §3–5). `data/audio/sfx_library.tres`; a set with no
## streams is silent, so the game runs before the audio is sourced.

## UI sounds by name: focus, confirm, cancel, tick (typewriter), denied.
@export var ui: Dictionary[StringName, SfxSet] = {}
## Footstep sets by surface (grass, mud, stone, ...). `stone` is the fallback.
@export var footsteps: Dictionary[StringName, SfxSet] = {}
