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

## Prompt marker in front of the verb.
const PROMPT_MARK: String = "▲ "

@onready var _shape: CollisionShape2D = %Shape
@onready var _prompt: Label = %Prompt


func _ready() -> void:
	(_shape.shape as CircleShape2D).radius = radius
	_prompt.text = PROMPT_MARK + prompt_text
	_prompt.position = prompt_offset - Vector2(_prompt.size.x / 2.0, _prompt.size.y)
	set_focused(false)


## Shows or hides the prompt (called by the InteractionProbe).
func set_focused(focused: bool) -> void:
	_prompt.visible = focused


func is_focused() -> bool:
	return _prompt.visible


func interact(by: Node) -> void:
	interacted.emit(by)
	if not dialogue_id.is_empty():
		DialogueManager.start(dialogue_id)
