class_name BossTrigger
extends Interactable
## A fixed boss fight in the world (PROJECT_PLAN.md §6.2 "Bosses", Phase 10): the crypt door.
## While its BossEncounter's `required_flags` are missing it is sealed (43_locked icon, `sealed_dialogue`).
## Once they are set, interacting plays `dialogue_id` (the boss's taunt) and starts the fight
## through SceneManager (no fleeing). Winning sets the encounter's `defeated_flag` (applied by
## SceneManager.end_battle with the rewards); from then on only `after_dialogue` plays and the fight
## never starts again. A lost fight is a Game Over, as for any battle.

## The fight began (the battle is starting).
signal fight_started(setup: BattleSetup)

@export var encounter: BossEncounter
## Played while the required flags are missing (empty = a default line).
@export var sealed_dialogue: StringName = &""
## Played once the boss is defeated (empty = a default line).
@export var after_dialogue: StringName = &""

const SEALED_TEXT: String = "It will not open."
const AFTER_TEXT: String = "All is silent now."

## Fights started from this trigger (tests: it fires once per availability).
var fights_started: int = 0


func _ready() -> void:
	super._ready()
	GameState.flag_changed.connect(_on_flag_changed)
	refresh()


## The required flags are set and the boss has not been defeated.
func is_available() -> bool:
	return encounter != null and encounter.is_available(GameState.flags)


func is_defeated() -> bool:
	return encounter != null and not encounter.defeated_flag.is_empty() \
			and GameState.get_flag(encounter.defeated_flag) as bool


## Sealed icon while the fight is not available yet.
func refresh() -> void:
	set_icon(LOCKED_ICON if not is_available() and not is_defeated() else null)


func interact(by: Node) -> void:
	interacted.emit(by)
	if is_defeated():
		await _say(after_dialogue, AFTER_TEXT)
		return
	if not is_available():
		AudioManager.sfx.play_ui_named(&"chest_locked", &"denied")
		await _say(sealed_dialogue, SEALED_TEXT)
		return
	if not dialogue_id.is_empty():
		await DialogueManager.start(dialogue_id)
	start_fight()


## Starts the boss battle (deferred: not from inside a physics or input callback). Returns false
## when it is not available or a battle or transition is already running.
func start_fight() -> bool:
	if not is_available() or SceneManager.in_battle or SceneManager.is_transitioning:
		return false
	var setup: BattleSetup = encounter.make_setup()
	fights_started += 1
	fight_started.emit(setup)
	SceneManager.start_battle.call_deferred(setup)
	return true


func _say(dialogue: StringName, fallback: String) -> void:
	if dialogue.is_empty():
		await DialogueManager.say([fallback], &"boss_trigger")
	else:
		await DialogueManager.start(dialogue)


func _on_flag_changed(_flag: StringName, _value: Variant) -> void:
	refresh()
