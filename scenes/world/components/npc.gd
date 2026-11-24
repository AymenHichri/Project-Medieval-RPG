class_name Npc
extends Interactable
## A character the player can talk to (PROJECT_PLAN.md Phase 7): an Interactable with an
## 8-direction idle sprite and a solid body. On talk it turns to face the player (idle_<DIR>),
## runs its dialogue with its portrait, then turns back to its resting facing.
## Placeholder art: the vendor Knight recolours (no villager sprites yet, risk R5).

## Idle facing when nobody is talking to it (one of PlayerController.DIRECTIONS).
@export_enum("E", "SE", "S", "SW", "W", "NW", "N", "NE") var facing: String = "S"
## Framed portrait shown beside its lines (null = none).
@export var portrait: Texture2D
## Its look (null = the scene's default, the Knight black recolour). Placeholders until villager
## sprites exist (risk R5).
@export var sprite_frames: SpriteFrames
## Playback speed of the idle loop (the vendor speed reads as panting).
@export_range(0.1, 2.0, 0.05) var idle_animation_speed: float = 0.5

var current_facing: StringName = &"S"

@onready var sprite: AnimatedSprite2D = %Sprite


func _ready() -> void:
	super._ready()
	if sprite_frames != null:
		sprite.sprite_frames = sprite_frames
	sprite.speed_scale = idle_animation_speed
	face(StringName(facing))
	if quest != null and quest_stage < 0:
		GameState.flag_changed.connect(_on_state_changed.unbind(2))
		GameState.quests_changed.connect(_on_state_changed.unbind(1))
		refresh_quest_icon()


## A quest giver shows the quest icon while it has a quest to give or is waiting for a report.
func refresh_quest_icon() -> void:
	set_icon(QUEST_ICON if is_quest_target() else null)


func _on_state_changed() -> void:
	refresh_quest_icon()


## Plays the idle of a direction name (unknown names are ignored).
func face(direction: StringName) -> void:
	if not direction in PlayerController.DIRECTIONS:
		return
	current_facing = direction
	var animation: StringName = StringName("idle_%s" % direction)
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation):
		sprite.play(animation)


## Turns towards a world position.
func face_towards(world_position: Vector2) -> void:
	face(PlayerController.dir_from_vector(world_position - global_position, current_facing))


func interact(by: Node) -> void:
	if by is Node2D:
		face_towards((by as Node2D).global_position)
	interacted.emit(by)
	if not dialogue_id.is_empty():
		await DialogueManager.start(dialogue_id, portrait)
	face(StringName(facing))
