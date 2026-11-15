class_name EncounterTable
extends Resource
## The random encounters of a region (PROJECT_PLAN.md §6.2). Assigned to EncounterZones.

@export var id: StringName = &""
@export var groups: Array[EncounterGroup] = []
## Chance of a battle per step (64 px walked) before rate modifiers. 0.04 ≈ one per 25 steps.
@export_range(0.0, 1.0, 0.005) var base_chance_per_step: float = 0.04
## Steps without any roll after entering a map, after a battle and after closing a dialogue.
@export_range(0, 100) var grace_steps: int = 6
## Battle background scene (null = the battle scene's default).
@export var background: PackedScene
## Battle music (null = none until real audio exists).
@export var music: MusicTrack
