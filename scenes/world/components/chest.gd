class_name Chest
extends Interactable
## A container the player opens once (PROJECT_PLAN.md Phase 9): gives its `item` × `count` and/or
## `gold`, then sets `opened_flag` in GameState.flags, so it stays open after leaving the map (and,
## from Phase 11, after loading a save). A chest with a `required_key` stays shut until the party
## holds that key item. Shows "Found …" lines through DialogueManager.say().
## Placeholder art: the castle-courtyard supply crate (`intact` = shut, `broken` = opened); the
## kits have no chest sprite yet (missing-asset list).

## Emitted after the contents were taken.
signal opened

## What it holds (null = gold only).
@export var item: ItemData
@export_range(1, 99) var count: int = 1
@export_range(0, 99999) var gold: int = 0
## GameState flag set once it is opened (required, unique per chest: `chest_<map>_<what>`).
@export var opened_flag: StringName = &""
## A key item the party must hold to open it (null = not locked).
@export var required_key: ItemData

@onready var sprite: AnimatedSprite2D = %Sprite


func _ready() -> void:
	super._ready()
	_show_state()


func is_opened() -> bool:
	return not opened_flag.is_empty() and GameState.get_flag(opened_flag) as bool


func is_locked() -> bool:
	return required_key != null and not GameState.inventory.has(required_key.id)


func interact(by: Node) -> void:
	interacted.emit(by)
	if is_opened():
		await DialogueManager.say(["It's empty."], &"chest_empty")
		return
	if is_locked():
		AudioManager.sfx.play_ui_named(&"chest_locked", &"denied")
		await DialogueManager.say(["It's locked fast. Some key must fit it."], &"chest_locked")
		return
	await DialogueManager.say(open_chest(), &"chest_opened")


## Takes the contents, sets the flag and returns the lines describing them. Does nothing (returns
## an empty list) when it is already open or locked.
func open_chest() -> PackedStringArray:
	var lines: PackedStringArray = []
	if is_opened() or is_locked():
		return lines
	AudioManager.sfx.play_ui_named(&"chest_open")
	if item != null:
		var added: int = GameState.add_item(item.id, count)
		if item.effect == ItemData.Effect.GOLD and not item.is_equipment():
			lines.append("Found %d gold." % (item.amount * count))
		elif added > 0:
			lines.append("Found %s." % _item_text(item, added))
		if added < count and item.effect != ItemData.Effect.GOLD:
			lines.append("You can't carry any more %s." % item.display_name)
	if gold > 0:
		GameState.add_gold(gold)
		lines.append("Found %d gold." % gold)
	if lines.is_empty():
		lines.append("It's empty.")
	elif gold > 0 or (item != null and item.effect == ItemData.Effect.GOLD):
		AudioManager.sfx.play_ui_named(&"reward_gold")
	else:
		AudioManager.sfx.play_ui_named(&"reward_item")
	if not opened_flag.is_empty():
		GameState.set_flag(opened_flag)
	_show_state()
	opened.emit()
	return lines


static func _item_text(found: ItemData, amount: int) -> String:
	return found.display_name if amount == 1 else "%d %s" % [amount, found.display_name]


func _show_state() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var state: StringName = &"broken" if is_opened() else &"intact"
	if sprite.sprite_frames.has_animation(state):
		sprite.play(state)
	set_prompt("Search" if is_opened() else "Open")
