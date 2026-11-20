class_name BattlePresenter
extends Node
## Plays the BattleEngine's events on the battlefield and the battle UI (PROJECT_PLAN.md §4.6).
## `await play(events)` returns when everything they describe has been shown. The engine has
## already applied every event when it hands them over, so the presenter keeps its own "shown"
## HP/MP per combatant and moves it event by event: bars and numbers change on each hit.
##
## Effects (FxSpec, SovDigital effect packs) play on each target as damage or healing lands: the
## skill's or item's `impact_fx`, else the target's own `hit_fx` for a physical blow. Status ticks
## play none.
##
## Sounds (SfxSet) follow the same rules (`choose_sfx`): the skill's or item's `impact_sfx`, else the
## target's `hit_sfx` for a physical blow; a critical hit or a miss uses the shared `crit` / `miss`
## sets of the SfxLibrary instead. Swings, casts, cries and deaths come from the CombatantVisual,
## the skill or the item. Status ticks are silent. Sounds play positioned at the combatant.
##
## One action's events are played as a unit: the actor's message, the step forward and the attack
## animation, then the effects (damage, statuses, defeats…) together on the hit frame, then the
## step back. Every BattleEvent.Type has a handler (`has_handler`), checked by a test.
## In `instant` mode nothing animates or waits (headless tests, a future fast-forward option).

signal _handlers_done

const POPUP_SCENE: PackedScene = preload("res://scenes/battle/ui/damage_popup.tscn")
const PALETTE: UIPalette = preload("res://scenes/ui/theme/ui_palette.tres")

# --- timing (seconds) ---------------------------------------------------------------------
## How long a message line is read before the action goes on.
const MESSAGE_SECONDS: float = 0.8
## Time to read the popups after an impact.
const IMPACT_SECONDS: float = 0.55
## Delay between the popups of successive hits on the same target.
const HIT_STAGGER_SECONDS: float = 0.12
## Pause for a status tick / regen popup at round end.
const TICK_SECONDS: float = 0.5
## The battle intro message and the enemies fading in.
const INTRO_SECONDS: float = 1.4
const FADE_IN_SECONDS: float = 0.6
## Victory / defeat message before the battle hands over.
const END_SECONDS: float = 1.5
## Escaping: how far and how fast the party runs off.
const FLEE_RUN_DISTANCE: float = 900.0
const FLEE_RUN_SECONDS: float = 0.8

# --- layout -------------------------------------------------------------------------------
## Popups start this far above the head; each further popup on the same target stacks higher.
const POPUP_HEAD_GAP: float = 24.0
const POPUP_STACK: float = 40.0

const ACTION_FAILED_TEXT: Dictionary[StringName, String] = {
	&"not_enough_mp": "Not enough MP!",
	&"no_item": "There are none left!",
	&"cannot_flee": "There is no escape!",
	&"no_target": "There is nothing left to strike.",
}

var instant: bool = false
var sprites: Dictionary[Combatant, BattleSprite] = {}
var hud: BattleHud
var message: BattleMessage
var popup_layer: Control
## Where battle effects are added (above the battlers). Null = no effects.
var fx_layer: Node2D
## Effects spawned so far (tests; counted in instant mode too, where nothing is shown).
var fx_count: int = 0
## Sounds started so far (tests; counted in instant mode too, where nothing plays).
var sfx_count: int = 0
## Shared battle sounds (crit, miss, defend, flee): the SfxLibrary's `battle` sets.
var shared_sfx: Dictionary[StringName, SfxSet] = {}
## The action being shown (its skill or item picks the impact effect).
var _action: BattleAction

var _handlers: Dictionary[BattleEvent.Type, Callable] = {}
var _shown_hp: Dictionary[Combatant, int] = {}
var _shown_mp: Dictionary[Combatant, int] = {}
var _popup_stack: Dictionary[Combatant, int] = {}
var _running: int = 0


func _init() -> void:
	_handlers = {
		BattleEvent.Type.ACTION_STARTED: _on_action_started,
		BattleEvent.Type.ACTION_SKIPPED: _on_action_skipped,
		BattleEvent.Type.ACTION_FAILED: _on_action_failed,
		BattleEvent.Type.DEFENDING: _on_defending,
		BattleEvent.Type.GUARDING: _on_guarding,
		BattleEvent.Type.COVERED: _on_covered,
		BattleEvent.Type.NO_EFFECT: _on_no_effect,
		BattleEvent.Type.DAMAGE: _on_damage,
		BattleEvent.Type.HEAL: _on_heal,
		BattleEvent.Type.MP_CHANGED: _on_mp_changed,
		BattleEvent.Type.REVIVED: _on_revived,
		BattleEvent.Type.STATUS_APPLIED: _on_status_applied,
		BattleEvent.Type.STATUS_RESISTED: _on_status_resisted,
		BattleEvent.Type.STATUS_REMOVED: _on_status_removed,
		BattleEvent.Type.DEFEATED: _on_defeated,
		BattleEvent.Type.PHASE_CHANGE: _on_phase_change,
		BattleEvent.Type.FLEE_ATTEMPTED: _on_flee_attempted,
		BattleEvent.Type.MESSAGE: _on_message,
		BattleEvent.Type.ROUND_ENDED: _on_round_ended,
		BattleEvent.Type.BATTLE_ENDED: _on_battle_ended,
	}


func setup(battle_sprites: Dictionary[Combatant, BattleSprite], battle_hud: BattleHud,
		battle_message: BattleMessage, popups: Control, is_instant: bool) -> void:
	sprites = battle_sprites
	hud = battle_hud
	message = battle_message
	popup_layer = popups
	instant = is_instant
	shared_sfx = AudioManager.sfx.library.battle
	for c: Combatant in sprites:
		_shown_hp[c] = c.hp
		_shown_mp[c] = c.mp


func has_handler(type: BattleEvent.Type) -> bool:
	return _handlers.has(type)


## HP currently displayed for `c` (follows the events played so far).
func shown_hp(c: Combatant) -> int:
	return _shown_hp.get(c, c.hp) as int


## Battle intro: the enemies fade in under the intro line.
func intro(text: String) -> void:
	message.show_text(text)
	for c: Combatant in sprites:
		if c.side == Combatant.Team.ENEMY and sprites[c].visual != null:
			_play_sfx(sprites[c].visual.cry_sfx, c)
	if not instant:
		for c: Combatant in sprites:
			if c.side == Combatant.Team.ENEMY:
				var sprite: BattleSprite = sprites[c]
				sprite.modulate.a = 0.0
				sprite.create_tween().tween_property(sprite, ^"modulate:a", 1.0, FADE_IN_SECONDS)
	await _wait(INTRO_SECONDS)
	message.clear()


## Shows `events` (one `execute_next()` or `end_round()` batch).
func play(events: Array[BattleEvent]) -> void:
	var i: int = 0
	while i < events.size():
		var event: BattleEvent = events[i]
		_popup_stack.clear()
		if event.type == BattleEvent.Type.ACTION_STARTED:
			var effects: Array[BattleEvent] = []
			var j: int = i + 1
			while j < events.size() and not _ends_action(events[j].type):
				effects.append(events[j])
				j += 1
			await _play_action(event, effects)
			i = j
		else:
			await (_handlers[event.type] as Callable).call(event)
			i += 1


static func _ends_action(type: BattleEvent.Type) -> bool:
	return type in [BattleEvent.Type.ACTION_STARTED, BattleEvent.Type.ACTION_SKIPPED,
			BattleEvent.Type.PHASE_CHANGE, BattleEvent.Type.ROUND_ENDED, BattleEvent.Type.BATTLE_ENDED]


# --- one action -----------------------------------------------------------------------------

func _play_action(start: BattleEvent, effects: Array[BattleEvent]) -> void:
	var actor: Combatant = start.get_value(&"actor") as Combatant
	var action: BattleAction = start.get_value(&"action") as BattleAction
	var sprite: BattleSprite = sprites.get(actor) as BattleSprite
	_action = action
	var impact: Array[BattleEvent] = []
	var failed: BattleEvent = null
	for e: BattleEvent in effects:
		if e.type == BattleEvent.Type.ACTION_FAILED:
			failed = e
		elif e.type == BattleEvent.Type.MP_CHANGED and e.subject() == actor and (e.get_value(&"amount") as int) < 0:
			_on_mp_changed(e)  # the cost is paid as the action starts
		else:
			impact.append(e)
	message.show_text(action_text(action))
	if failed != null:
		await _wait(MESSAGE_SECONDS)
		await _on_action_failed(failed)
		return
	match action.kind:
		BattleAction.Kind.DEFEND, BattleAction.Kind.FLEE:
			for e: BattleEvent in impact:
				await (_handlers[e.type] as Callable).call(e)
		BattleAction.Kind.ITEM:
			_play_sfx(action.item.cast_sfx if action.item != null else null, actor)
			await _wait(MESSAGE_SECONDS * 0.5)
			await _impact(impact)
		_:
			if action.kind == BattleAction.Kind.SKILL and _is_spell(action.skill):
				await _cast(sprite, action.skill, impact)
			else:
				await _melee(sprite, melee_anim(sprite, action), impact)


func _melee(sprite: BattleSprite, anim: StringName, impact: Array[BattleEvent]) -> void:
	if sprite == null:
		await _impact(impact)
		return
	await sprite.step_forward()
	if _action != null:
		var swing: SfxSet = _action.skill.cast_sfx if _action.skill != null else null
		if swing == null and sprite.visual != null:
			swing = sprite.visual.attack_sfx
		_play_sfx(swing, _action.actor)
	if sprite.start_logical(anim):
		await sprite.wait_hit()
	await _impact(impact)
	await sprite.wait_finished()
	await sprite.step_back()


func _cast(sprite: BattleSprite, skill: SkillData, impact: Array[BattleEvent]) -> void:
	_play_sfx(skill.cast_sfx, _action.actor if _action != null else null)
	if sprite != null:
		sprite.glow(spell_color(skill))
		# Stances (Provoke, Guard) are shown by the glow alone, without a swing.
		var stance: bool = skill.category == SkillData.Category.SKILL and not skill.is_offensive()
		var anim: StringName = &"" if stance else cast_anim(sprite)
		if anim != &"" and sprite.start_logical(anim):
			await sprite.wait_hit()
		else:
			await _wait(BattleSprite.GLOW_SECONDS)
	await _impact(impact)
	if sprite != null:
		await sprite.wait_finished()


## Starts every effect's handler at once (hurt reactions, popups, deaths run together), then waits
## for the popups to be read and for every handler to finish.
func _impact(impact: Array[BattleEvent]) -> void:
	for e: BattleEvent in impact:
		_run_handler(e)
	await _wait(IMPACT_SECONDS)
	if _running > 0:
		await _handlers_done


func _run_handler(e: BattleEvent) -> void:
	_running += 1
	await (_handlers[e.type] as Callable).call(e)
	_running -= 1
	if _running == 0:
		_handlers_done.emit()


## Logical animation of a melee action: the skill's own move, else the generic skill, else attack.
static func melee_anim(sprite: BattleSprite, action: BattleAction) -> StringName:
	if action.kind != BattleAction.Kind.SKILL or sprite == null:
		return &"attack"
	if sprite.has_logical(action.skill.anim_key):
		return action.skill.anim_key
	return &"skill" if sprite.has_logical(&"skill") else &"attack"


## Animation for casting: `cast`, else the generic skill, else attack (with the glow stand-in).
static func cast_anim(sprite: BattleSprite) -> StringName:
	for anim: StringName in [&"cast", &"skill", &"attack"]:
		if sprite.has_logical(anim):
			return anim
	return &""


## Spells and support skills (heal, buff, cure, guard) are shown in place with a glow; only
## damaging techniques step forward.
static func _is_spell(skill: SkillData) -> bool:
	return skill.category == SkillData.Category.MAGIC or not skill.is_offensive()


## Glow colour of a spell: healing green, else its element.
static func spell_color(skill: SkillData) -> Color:
	match skill.effect:
		SkillData.Effect.HEAL:
			return PALETTE.heal
		SkillData.Effect.CURE:
			return PALETTE.parchment_light
		SkillData.Effect.STATUS, SkillData.Effect.GUARD:
			if skill.element == Elements.Element.PHYSICAL:
				return PALETTE.gold
	match skill.element:
		Elements.Element.FIRE:
			return PALETTE.ember
		Elements.Element.FROST:
			return PALETTE.mana.lightened(0.4)
		Elements.Element.LIGHTNING:
			return PALETTE.gold
		Elements.Element.HOLY:
			return PALETTE.parchment_light
		Elements.Element.SHADOW:
			return PALETTE.arcane
	return PALETTE.parchment


static func action_text(action: BattleAction) -> String:
	var who: String = action.actor.display_name
	match action.kind:
		BattleAction.Kind.ATTACK:
			return "%s attacks!" % who
		BattleAction.Kind.SKILL:
			var verb: String = "casts" if action.skill.category == SkillData.Category.MAGIC else "uses"
			return "%s %s %s!" % [who, verb, action.skill.display_name]
		BattleAction.Kind.ITEM:
			return "%s uses a %s!" % [who, action.item.display_name]
		BattleAction.Kind.DEFEND:
			return "%s defends." % who
		BattleAction.Kind.FLEE:
			return "The party tries to flee…"
	return ""


# --- event handlers -------------------------------------------------------------------------

func _on_action_started(e: BattleEvent) -> void:
	await _play_action(e, [])


func _on_action_skipped(e: BattleEvent) -> void:
	var who: String = e.subject().display_name
	var status: StatusEffectData = e.get_value(&"status") as StatusEffectData
	var text: String = "%s cannot move!" % who
	if status != null:
		match status.kind:
			StatusEffectData.Kind.SLEEP:
				text = "%s is fast asleep." % who
			StatusEffectData.Kind.STUN:
				text = "%s is stunned and cannot act!" % who
	message.show_text(text)
	await _wait(MESSAGE_SECONDS)


func _on_action_failed(e: BattleEvent) -> void:
	message.show_text(ACTION_FAILED_TEXT.get(e.get_value(&"reason"), "Nothing happens.") as String)
	await _wait(MESSAGE_SECONDS)


func _on_defending(e: BattleEvent) -> void:
	var sprite: BattleSprite = sprites.get(e.subject()) as BattleSprite
	message.show_text("%s braces for the blows." % e.subject().display_name)
	_play_sfx(shared_sfx.get(&"defend") as SfxSet, e.subject())
	if sprite != null:
		sprite.set_defending(true)
	await _wait(MESSAGE_SECONDS)


func _on_guarding(e: BattleEvent) -> void:
	var actor: Combatant = e.get_value(&"actor") as Combatant
	var ward: Combatant = e.subject()
	var sprite: BattleSprite = sprites.get(actor) as BattleSprite
	if ward != null and ward != actor:
		message.show_text("%s stands guard over %s." % [actor.display_name, ward.display_name])
	else:
		message.show_text("%s braces for the blows." % actor.display_name)
	_play_sfx(shared_sfx.get(&"defend") as SfxSet, actor)
	if sprite != null:
		sprite.set_defending(true)
	await _wait(MESSAGE_SECONDS)


## A guardian steps in front of the blow: a popup over it (the damage follows on it).
func _on_covered(e: BattleEvent) -> void:
	var guardian: Combatant = e.subject()
	var ward: Combatant = e.get_value(&"protected") as Combatant
	_popup(guardian, "Covers %s" % ward.display_name if ward != null else "Cover", DamagePopup.Kind.INFO,
			_next_stack(guardian))


func _on_no_effect(e: BattleEvent) -> void:
	_popup(e.subject(), "No effect", DamagePopup.Kind.INFO, _next_stack(e.subject()))


func _on_damage(e: BattleEvent) -> void:
	var target: Combatant = e.subject()
	var amount: int = e.get_value(&"amount") as int
	var stack: int = _next_stack(target)
	await _wait(stack * HIT_STAGGER_SECONDS)
	_shown_hp[target] = maxi(0, shown_hp(target) - amount)
	_show_bars(target)
	if e.get_value(&"immune") as bool:
		_popup(target, "Immune", DamagePopup.Kind.INFO, stack)
	else:
		var critical: bool = e.get_value(&"critical") as bool
		_popup(target, str(amount) + ("!" if critical else ""),
				DamagePopup.Kind.CRITICAL if critical else DamagePopup.Kind.DAMAGE, stack)
		if e.get_value(&"weak") as bool:
			_popup(target, "WEAK!", DamagePopup.Kind.WEAK, _next_stack(target))
		elif e.get_value(&"resisted") as bool:
			_popup(target, "Resist", DamagePopup.Kind.INFO, _next_stack(target))
	var sprite: BattleSprite = sprites.get(target) as BattleSprite
	_play_sfx(choose_sfx(_action, e, sprite.visual if sprite != null else null, shared_sfx), target)
	if amount > 0:
		_play_fx(choose_fx(_action, e, sprite.visual if sprite != null else null), target)
	if sprite != null and amount > 0:
		await sprite.hurt(_shown_hp[target] == 0)
	if e.get_value(&"source") is StatusEffectData:
		await _wait(TICK_SECONDS)


func _on_heal(e: BattleEvent) -> void:
	var target: Combatant = e.subject()
	var amount: int = e.get_value(&"amount") as int
	_shown_hp[target] = mini(target.max_hp(), shown_hp(target) + amount)
	_show_bars(target)
	_play_fx(choose_fx(_action, e, null), target)
	_play_sfx(choose_sfx(_action, e, null, shared_sfx), target)
	_popup(target, str(amount), DamagePopup.Kind.HEAL, _next_stack(target))
	if e.get_value(&"source") is StatusEffectData:
		await _wait(TICK_SECONDS)


func _on_mp_changed(e: BattleEvent) -> void:
	var target: Combatant = e.subject()
	_shown_mp[target] = e.get_value(&"mp") as int
	_show_bars(target)
	var amount: int = e.get_value(&"amount") as int
	if amount > 0:
		_popup(target, "+%d MP" % amount, DamagePopup.Kind.MP, _next_stack(target))


func _on_revived(e: BattleEvent) -> void:
	var target: Combatant = e.subject()
	_shown_hp[target] = e.get_value(&"amount") as int
	_show_bars(target)
	var sprite: BattleSprite = sprites.get(target) as BattleSprite
	if sprite != null:
		sprite.revive()
	_popup(target, "Revived", DamagePopup.Kind.HEAL, _next_stack(target))


func _on_status_applied(e: BattleEvent) -> void:
	var target: Combatant = e.subject()
	var status: StatusEffectData = e.get_value(&"status") as StatusEffectData
	_popup(target, status.display_name, DamagePopup.Kind.INFO, _next_stack(target), status.tag_color)
	if hud != null:
		hud.refresh_statuses(target)


func _on_status_resisted(e: BattleEvent) -> void:
	var status: StatusEffectData = e.get_value(&"status") as StatusEffectData
	_popup(e.subject(), "%s: no effect" % status.display_name, DamagePopup.Kind.INFO, _next_stack(e.subject()))


func _on_status_removed(e: BattleEvent) -> void:
	var target: Combatant = e.subject()
	var status: StatusEffectData = e.get_value(&"status") as StatusEffectData
	if hud != null:
		hud.refresh_statuses(target)
	if e.get_value(&"reason") == &"expired" and target.is_alive():
		_popup(target, "%s fades" % status.display_name, DamagePopup.Kind.INFO, _next_stack(target))
		await _wait(TICK_SECONDS * 0.5)


func _on_defeated(e: BattleEvent) -> void:
	var target: Combatant = e.subject()
	_shown_hp[target] = 0
	_show_bars(target)
	if hud != null:
		hud.refresh_statuses(target)
	var sprite: BattleSprite = sprites.get(target) as BattleSprite
	if sprite != null and sprite.visual != null:
		_play_sfx(sprite.visual.death_sfx, target)
	if sprite != null:
		await sprite.die()


func _on_phase_change(e: BattleEvent) -> void:
	var target: Combatant = e.subject()
	var data: EnemyData = e.get_value(&"new_data") as EnemyData
	message.show_text("%s reveals its true form!" % target.display_name)
	var sprite: BattleSprite = sprites.get(target) as BattleSprite
	if sprite != null:
		sprite.flash()
		if data != null and data.visual != null:
			sprite.set_visual(data.visual)
		if sprite.visual != null:
			_play_sfx(sprite.visual.cry_sfx, target)
	_shown_hp[target] = target.hp
	_show_bars(target, false)
	await _wait(MESSAGE_SECONDS)


func _on_flee_attempted(e: BattleEvent) -> void:
	if not (e.get_value(&"success") as bool):
		message.show_text("But there is no way out!")
		await _wait(MESSAGE_SECONDS)
		return
	message.show_text("The party escapes!")
	_play_sfx(shared_sfx.get(&"flee") as SfxSet, e.subject())
	for c: Combatant in sprites:
		if c.side == Combatant.Team.PARTY:
			var sprite: BattleSprite = sprites[c]
			_run_handler_like(sprite.run_away.bind(FLEE_RUN_DISTANCE, FLEE_RUN_SECONDS))
	await _wait(FLEE_RUN_SECONDS)
	if _running > 0:
		await _handlers_done


func _on_message(e: BattleEvent) -> void:
	message.show_text(e.get_value(&"text") as String)
	await _wait(MESSAGE_SECONDS)


## Engine state is final at round end: drop the defend stances and resync the shown values.
func _on_round_ended(_e: BattleEvent) -> void:
	for c: Combatant in sprites:
		var sprite: BattleSprite = sprites[c]
		if sprite.is_defending() and not c.is_defending:
			sprite.set_defending(false)
		_shown_hp[c] = c.hp
		_shown_mp[c] = c.mp
		_show_bars(c, false)
		if hud != null:
			hud.refresh_statuses(c)
	message.clear()


func _on_battle_ended(e: BattleEvent) -> void:
	match e.get_value(&"outcome") as BattleEngine.Outcome:
		BattleEngine.Outcome.VICTORY:
			message.show_text("Victory!")
			for c: Combatant in sprites:
				if c.side == Combatant.Team.PARTY and c.is_alive():
					sprites[c].victory_pose()
		BattleEngine.Outcome.DEFEAT:
			message.show_text("The party has fallen…")
		BattleEngine.Outcome.FLED:
			pass
	await _wait(END_SECONDS)


# --- helpers ------------------------------------------------------------------------------

func _run_handler_like(work: Callable) -> void:
	_running += 1
	await work.call()
	_running -= 1
	if _running == 0:
		_handlers_done.emit()


func _show_bars(c: Combatant, animate: bool = true) -> void:
	var hp: int = shown_hp(c)
	var mp: int = _shown_mp.get(c, c.mp) as int
	if c.side == Combatant.Team.PARTY:
		if hud != null:
			hud.show_values(c, hp, mp, animate and not instant)
	elif sprites.has(c):
		sprites[c].set_hp_shown(hp, c.max_hp(), animate)


# --- effects --------------------------------------------------------------------------------

## The effect for one damage/heal event of `action` on a target with `target_visual`: the skill's
## or item's `impact_fx`; else, for physical damage (Attack or a non-spell skill), the target's
## `hit_fx`. Status ticks (event source = a StatusEffectData) and anything else get none.
static func choose_fx(action: BattleAction, e: BattleEvent, target_visual: CombatantVisual) -> FxSpec:
	if action == null or e.get_value(&"source") is StatusEffectData:
		return null
	if action.skill != null and action.skill.impact_fx != null:
		return action.skill.impact_fx
	if action.item != null and action.item.impact_fx != null:
		return action.item.impact_fx
	if e.type != BattleEvent.Type.DAMAGE or target_visual == null:
		return null
	var physical: bool = action.kind == BattleAction.Kind.ATTACK or (action.skill != null and not _is_spell(action.skill))
	return target_visual.hit_fx if physical else null


## The sound for one damage/heal event of `action` on a target with `target_visual`, by the same
## rules as `choose_fx`: a miss (no damage, or immune) uses the shared `miss` set and a critical
## hit the shared `crit` set when they exist; then the skill's or item's `impact_sfx`; then, for
## physical damage, the target's `hit_sfx`. Status ticks and a null action get none.
static func choose_sfx(action: BattleAction, e: BattleEvent, target_visual: CombatantVisual,
		shared: Dictionary[StringName, SfxSet] = {}) -> SfxSet:
	if action == null or e.get_value(&"source") is StatusEffectData:
		return null
	if e.type == BattleEvent.Type.DAMAGE:
		var missed: bool = (e.get_value(&"amount") as int) <= 0 or (e.get_value(&"immune") as bool)
		if missed and shared.get(&"miss") != null:
			return shared[&"miss"]
		if (e.get_value(&"critical") as bool) and shared.get(&"crit") != null:
			return shared[&"crit"]
	if action.skill != null and action.skill.impact_sfx != null:
		return action.skill.impact_sfx
	if action.item != null and action.item.impact_sfx != null:
		return action.item.impact_sfx
	if e.type != BattleEvent.Type.DAMAGE or target_visual == null:
		return null
	var physical: bool = action.kind == BattleAction.Kind.ATTACK or (action.skill != null and not _is_spell(action.skill))
	return target_visual.hit_sfx if physical else null


## Canvas position of `spec` on `sprite` (by its anchor).
static func fx_position(sprite: BattleSprite, spec: FxSpec) -> Vector2:
	match spec.anchor:
		FxSpec.Anchor.FEET:
			return sprite.global_position
		FxSpec.Anchor.HEAD:
			return sprite.head_position()
		_:
			return sprite.global_position + Vector2(0, -sprite.height() * 0.5)


func _play_fx(spec: FxSpec, target: Combatant) -> void:
	var sprite: BattleSprite = sprites.get(target) as BattleSprite
	if spec == null or not spec.is_valid() or sprite == null:
		return
	fx_count += 1
	if instant or fx_layer == null:
		return
	BattleFx.spawn(fx_layer, spec, fx_position(sprite, spec), spec.mirror_for_facing and sprite.facing_sign() < 0.0)


## Plays `sfx` positioned at `who` (counted in instant mode, where nothing plays).
func _play_sfx(sfx: SfxSet, who: Combatant) -> void:
	if sfx == null or sfx.streams.is_empty():
		return
	sfx_count += 1
	if instant:
		return
	var sprite: BattleSprite = sprites.get(who) as BattleSprite
	if sprite != null:
		AudioManager.sfx.play_at(sfx, sprite.global_position)
	else:
		AudioManager.sfx.play_ui(sfx)


func _next_stack(target: Combatant) -> int:
	var n: int = _popup_stack.get(target, 0) as int
	_popup_stack[target] = n + 1
	return n


func _popup(target: Combatant, text: String, kind: DamagePopup.Kind, stack: int,
		color: Color = Color.TRANSPARENT) -> void:
	if instant or popup_layer == null or not sprites.has(target):
		return
	var popup: DamagePopup = POPUP_SCENE.instantiate() as DamagePopup
	popup_layer.add_child(popup)
	var at: Vector2 = sprites[target].head_position() - Vector2(0, POPUP_HEAD_GAP + stack * POPUP_STACK)
	popup.show_at(text, kind, at, color)


func _wait(seconds: float) -> void:
	if instant or seconds <= 0.0 or not is_inside_tree():
		return
	await get_tree().create_timer(seconds).timeout
