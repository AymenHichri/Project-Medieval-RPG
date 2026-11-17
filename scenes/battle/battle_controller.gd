class_name BattleController
extends Node2D
## Root of battle_scene.tscn: runs one battle (PROJECT_PLAN.md §6.3 flow). Builds the engine and
## the battlers, then loops: collect the party's commands (CommandMenu → TargetSelector, or
## auto-attacks), `engine.begin_round`, present each `execute_next()` batch, present `end_round()`,
## until the battle ends. Victory shows the results screen. Emits `finished(result)`; applying
## rewards is `SceneManager.end_battle()`'s job, never this scene's.
##
##   var battle: BattleController = BATTLE_SCENE.instantiate()
##   add_child(battle)
##   battle.start(setup, party)          # async; or listen to `finished`

signal finished(result: BattleResult)
## The battle is won, just before the results screen opens (SceneManager plays the jingle).
signal victory(result: BattleResult)

const SPRITE_SCENE: PackedScene = preload("res://scenes/battle/battle_sprite.tscn")
const DEFAULT_BACKGROUND: PackedScene = preload("res://scenes/battle/backgrounds/graveyard_bg.tscn")

## Party members auto-attack the first living enemy (tests, demos). No menus are shown.
@export var auto_battle: bool = false
## Skip every animation and wait (tests). Each round still takes at least one frame.
@export var instant: bool = false
## Optional `func(result: BattleResult) -> PackedStringArray`: the level-up lines shown on the
## results screen (SceneManager passes `GameState.preview_level_ups`; the battle itself never
## touches the party's progress).
var level_up_preview: Callable

var engine: BattleEngine
## Battle items and their counts. Using one spends it (through the engine's item callback).
var items: Dictionary[ItemData, int] = {}
var sprites: Dictionary[Combatant, BattleSprite] = {}
var result: BattleResult

## Last command each member chose: the menu opens on it next round.
var _last_command: Dictionary[Combatant, StringName] = {}
var _running: bool = false

@onready var _background_slot: Node2D = %Background
@onready var _battlers: Node2D = %Battlers
@onready var _party_slots: Node2D = %PartySlots
@onready var _enemy_slots: Node2D = %EnemySlots
@onready var presenter: BattlePresenter = %Presenter
@onready var hud: BattleHud = %BattleHud
@onready var message: BattleMessage = %BattleMessage
@onready var command_menu: CommandMenu = %CommandMenu
@onready var target_selector: TargetSelector = %TargetSelector
@onready var results_screen: ResultsScreen = %ResultsScreen
@onready var _popups: Control = %Popups
@onready var _fx: Node2D = %Fx


## Runs the whole battle and returns its result (also emitted as `finished`).
## `battle_items`: what the party can use (copied; counts go down as items are used).
func start(setup: BattleSetup, party: Array[Combatant], rng: RandomNumberGenerator = null,
		battle_items: Dictionary[ItemData, int] = {}) -> BattleResult:
	assert(not _running, "a BattleController runs one battle")
	_running = true
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	items = battle_items.duplicate()
	engine = BattleEngine.new()
	engine.setup(setup, party, rng, _consume_item)
	_add_background(setup.background if setup.background != null else DEFAULT_BACKGROUND)
	_spawn_sprites()
	hud.bind(engine.party)
	presenter.setup(sprites, hud, message, _popups, instant)
	presenter.fx_layer = _fx

	await presenter.intro(setup.intro_text if not setup.intro_text.is_empty() else intro_text(engine.enemies))
	while engine.outcome() == BattleEngine.Outcome.ONGOING:
		var actions: Array[BattleAction] = await _collect_commands()
		hud.set_active(null)
		engine.begin_round(actions)
		while engine.has_next_action():
			await presenter.play(engine.execute_next())
		await presenter.play(engine.end_round())
		if instant:
			await get_tree().process_frame

	result = engine.compute_rewards()
	if result.is_victory():
		victory.emit(result)
		var level_lines: PackedStringArray = []
		if level_up_preview.is_valid():
			level_lines = level_up_preview.call(result) as PackedStringArray
		await results_screen.show_result(result, instant or auto_battle, level_lines)
	finished.emit(result)
	return result


## "A Wolf appears!" / "Wolf A, Wolf B and Goblin Scout appear!"
static func intro_text(enemies: Array[Combatant]) -> String:
	if enemies.is_empty():
		return ""
	if enemies.size() == 1:
		return "A %s appears!" % enemies[0].display_name
	var names: PackedStringArray = []
	for enemy: Combatant in enemies:
		names.append(enemy.display_name)
	var last: String = names[names.size() - 1]
	names.remove_at(names.size() - 1)
	return "%s and %s appear!" % [", ".join(names), last]


func sprite_of(c: Combatant) -> BattleSprite:
	return sprites.get(c) as BattleSprite


# --- setup ----------------------------------------------------------------------------------

func _add_background(scene: PackedScene) -> void:
	for child: Node in _background_slot.get_children():
		child.queue_free()
	_background_slot.add_child(scene.instantiate())


func _spawn_sprites() -> void:
	var party_slots: Array[Node] = _party_slots.get_children()
	var enemy_slots: Array[Node] = _enemy_slots.get_children()
	assert(engine.party.size() <= party_slots.size(), "more party members than PartySlots")
	assert(engine.enemies.size() <= enemy_slots.size(), "more enemies than EnemySlots")
	for i: int in engine.party.size():
		var member: Combatant = engine.party[i]
		var look: CombatantVisual = member.character_data.visual if member.character_data != null else null
		_spawn(member, look, (party_slots[i] as Node2D).position)
	for i: int in engine.enemies.size():
		var enemy: Combatant = engine.enemies[i]
		_spawn(enemy, enemy.enemy_data.visual, (enemy_slots[i] as Node2D).position)


func _spawn(c: Combatant, look: CombatantVisual, slot: Vector2) -> void:
	var sprite: BattleSprite = SPRITE_SCENE.instantiate() as BattleSprite
	sprite.instant = instant
	sprite.name = c.display_name.to_pascal_case()
	_battlers.add_child(sprite)
	sprite.setup(c, look, slot)
	if not c.is_alive():
		sprite.die()
	sprites[c] = sprite


# --- commands -------------------------------------------------------------------------------

## One action per able party member, in party order. Cancel steps back to the previous member;
## Flee ends the round's choices at once (the whole party runs).
func _collect_commands() -> Array[BattleAction]:
	if auto_battle:
		return _auto_attacks()
	var members: Array[Combatant] = []
	for member: Combatant in engine.party:
		if member.can_act():
			members.append(member)
	var actions: Array[BattleAction] = []
	var i: int = 0
	while i < members.size():
		hud.set_active(members[i])
		var action: BattleAction = await _choose_action(members[i], i > 0)
		if action == null:
			i -= 1
			actions.resize(i)
			continue
		if action.kind == BattleAction.Kind.FLEE:
			command_menu.close()
			return [action]
		actions.resize(i)
		actions.append(action)
		i += 1
	command_menu.close()
	return actions


func _auto_attacks() -> Array[BattleAction]:
	var actions: Array[BattleAction] = []
	var targets: Array[Combatant] = ActionResolver.living(engine.enemies)
	for member: Combatant in engine.party:
		if member.can_act() and not targets.is_empty():
			actions.append(BattleAction.attack(member, targets[0]))
	return actions


## The member's action, or null to go back to the previous member.
func _choose_action(member: Combatant, allow_back: bool) -> BattleAction:
	while true:
		var command: StringName = await command_menu.choose_command(member, engine.flee_chance() > 0.0,
				_has_items(), allow_back, _last_command.get(member, &"attack") as StringName)
		if command == &"":
			return null
		_last_command[member] = command
		var action: BattleAction = await _complete_command(member, command)
		if action != null:
			return action
	return null


## Fills in the details of `command` (skill, item, targets). Null when the player backs out.
func _complete_command(member: Combatant, command: StringName) -> BattleAction:
	match command:
		&"attack":
			var targets: Array[Combatant] = await _choose_targets(member, Targeting.Mode.ONE_ENEMY)
			return BattleAction.attack(member, targets[0]) if not targets.is_empty() else null
		&"skills", &"magic":
			var category: SkillData.Category = SkillData.Category.SKILL if command == &"skills" else SkillData.Category.MAGIC
			while true:
				var skill: SkillData = await command_menu.choose_skill(member, category)
				if skill == null:
					return null
				var targets: Array[Combatant] = await _choose_targets(member, skill.target_mode)
				if not targets.is_empty():
					return BattleAction.use_skill(member, skill, targets)
		&"items":
			while true:
				var item: ItemData = await command_menu.choose_item(items)
				if item == null:
					return null
				var targets: Array[Combatant] = await _choose_targets(member, item.target_mode,
						item.effect == ItemData.Effect.REVIVE)
				if not targets.is_empty():
					return BattleAction.use_item(member, item, targets)
		&"defend":
			return BattleAction.defend(member)
		&"flee":
			return BattleAction.flee(member)
	return null


## Lets the player pick targets for `mode` ([] = cancelled). `fallen` lists defeated allies (Revive).
func _choose_targets(user: Combatant, mode: Targeting.Mode, fallen: bool = false) -> Array[Combatant]:
	if mode == Targeting.Mode.SELF:
		return [user]
	var side: Array[Combatant] = engine.enemies if Targeting.targets_opponents(mode) else engine.party
	var candidates: Array[BattleSprite] = []
	for c: Combatant in side:
		if c.is_alive() != fallen:
			candidates.append(sprites[c])
	var all: bool = mode == Targeting.Mode.ALL_ENEMIES or mode == Targeting.Mode.ALL_ALLIES
	var start: int = maxi(0, candidates.find(sprites.get(user))) if not Targeting.targets_opponents(mode) else 0
	return await target_selector.choose(candidates, all, start)


func _has_items() -> bool:
	for item: ItemData in items:
		if items[item] > 0 and item.usable_in_battle:
			return true
	return false


## Engine callback: spends one `item`; false when none is left.
func _consume_item(item: ItemData) -> bool:
	var count: int = items.get(item, 0) as int
	if count <= 0:
		return false
	items[item] = count - 1
	return true
