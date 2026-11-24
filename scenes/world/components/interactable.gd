class_name Interactable
extends Area2D
## Something the player can examine or talk to (PROJECT_PLAN.md §6.1). Drop it as a child of a
## prop, at the prop's base. The player's InteractionProbe focuses the nearest one in front of
## the player, which shows the prompt; pressing `accept` calls `interact()`.
## Physics layer 4 `interactables` (monitorable only).

signal interacted(by: Node)

## Verb shown in the prompt ("Examine", "Read", "Talk").
@export var prompt_text: String = "Examine"
## Dialogue started on interaction (`data/dialogue/<id>.json`). Empty = only emit `interacted`.
@export var dialogue_id: StringName = &""
## Reach of the area (px). The probe in front of the player has to overlap it.
@export var radius: float = 64.0
## Where the prompt's bottom centre sits, relative to this node.
@export var prompt_offset: Vector2 = Vector2(0, -170)

@export_group("Quest")
## The quest this belongs to (Phase 10): the map page marks it while it is a target, and a giver
## NPC shows the quest icon. Null = none.
@export var quest: QuestData
## The stage at which this is the target; -1 = the quest giver (see QuestLog.is_target).
@export var quest_stage: int = -1
## No longer a target once this flag is set (a grave searched). Empty = while the stage lasts.
@export var quest_done_flag: StringName = &""
@export_group("")

## Prompt marker in front of the verb.
const PROMPT_MARK: String = "▲ "
## Gimble's HUD icons shown over interactables (Phase 10): quest givers and locked things.
const QUEST_ICON: Texture2D = preload("res://assets/vendor/gimbles/hud_icons/64px/51_quest.png")
const LOCKED_ICON: Texture2D = preload("res://assets/vendor/gimbles/hud_icons/64px/43_locked.png")
## Icons are drawn at an integer scale (pixel art) where the prompt appears; the prompt replaces
## the icon while the player is close.
const ICON_SCALE: float = 2.0

## The icon floating over this interactable (null until `set_icon` first shows one).
var icon: Sprite2D

@onready var _shape: CollisionShape2D = %Shape
@onready var _prompt: Label = %Prompt


func _ready() -> void:
	(_shape.shape as CircleShape2D).radius = radius
	_prompt.text = PROMPT_MARK + prompt_text
	_prompt.position = prompt_offset - Vector2(_prompt.size.x / 2.0, _prompt.size.y)
	set_focused(false)


## Changes the verb shown in the prompt ("Open" → "Search").
func set_prompt(text: String) -> void:
	prompt_text = text
	if _prompt == null:
		return
	_prompt.text = PROMPT_MARK + text
	_prompt.position = prompt_offset - Vector2(_prompt.size.x / 2.0, _prompt.size.y)


## Shows `texture` floating above the prompt (null hides it).
func set_icon(texture: Texture2D) -> void:
	if texture == null and icon == null:
		return
	if icon == null:
		icon = Sprite2D.new()
		icon.name = "Icon"
		icon.z_index = 50
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(icon)
	icon.texture = texture
	icon.scale = Vector2(ICON_SCALE, ICON_SCALE)
	icon.position = prompt_offset - Vector2(0, texture.get_height() * ICON_SCALE / 2.0) if texture != null else prompt_offset
	icon.visible = texture != null and not is_focused()


## The texture of the icon set (null when none), whether or not the prompt hides it right now.
func shown_icon() -> Texture2D:
	return icon.texture if icon != null else null


## True when the player should come here now for `quest` (QuestLog.is_target).
func is_quest_target() -> bool:
	return quest != null and GameState.quests.is_target(quest.id, quest_stage, quest_done_flag, GameState.flags)


## Shows or hides the prompt (called by the InteractionProbe).
func set_focused(focused: bool) -> void:
	_prompt.visible = focused
	if icon != null:
		icon.visible = icon.texture != null and not focused


func is_focused() -> bool:
	return _prompt.visible


func interact(by: Node) -> void:
	interacted.emit(by)
	if not dialogue_id.is_empty():
		DialogueManager.start(dialogue_id)
