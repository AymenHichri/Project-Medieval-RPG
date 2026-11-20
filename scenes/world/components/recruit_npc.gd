class_name RecruitNpc
extends Npc
## A recruitable character waiting in the world (PROJECT_PLAN.md Phase 8): an Npc that, once its
## dialogue ends, joins the party through `GameState.recruit()` (which sets `joined_flag`) and
## leaves the map. When `join_if_flag` is set, it only joins if the dialogue set that flag (the
## player accepted); otherwise it waits to be asked again. Already in the party → removed on load.
## Its sprite and portrait come from the character's battle visual and portrait.

## A member joined the party from this NPC.
signal recruited(member: PartyMember)

## Seconds the NPC takes to fade out once it has joined.
const LEAVE_SECONDS: float = 0.6

## The character who joins.
@export var character: CharacterData
## Flag set when the character joins (e.g. `warden_joined`).
@export var joined_flag: StringName = &""
## When set, the character joins only if this flag is set after the dialogue (a choice sets it).
@export var join_if_flag: StringName = &""


func _ready() -> void:
	if character != null:
		if character.visual != null and character.visual.sprite_frames != null:
			sprite.sprite_frames = character.visual.sprite_frames
		if portrait == null:
			portrait = character.portrait
	super._ready()
	if has_joined():
		queue_free()


## The character is already in the party, or the joined flag is set.
func has_joined() -> bool:
	if character != null and GameState.party.has_character(character.id):
		return true
	return not joined_flag.is_empty() and GameState.get_flag(joined_flag) as bool


func interact(by: Node) -> void:
	await super.interact(by)
	if not is_inside_tree() or has_joined():
		return
	if not join_if_flag.is_empty() and not (GameState.get_flag(join_if_flag) as bool):
		return
	var member: PartyMember = GameState.recruit(character, joined_flag)
	if member == null:
		return
	recruited.emit(member)
	_leave()


func _leave() -> void:
	set_focused(false)
	set_deferred(&"monitorable", false)
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, LEAVE_SECONDS)
	tween.tween_callback(queue_free)
