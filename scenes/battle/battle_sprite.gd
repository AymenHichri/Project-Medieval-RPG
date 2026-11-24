class_name BattleSprite
extends Node2D
## One combatant on the battlefield (PROJECT_PLAN.md §6.3 "Presentation mapping"). Plays the
## logical animations of its CombatantVisual, reports the hit frame, and provides the stand-ins
## for poses the vendor sheets lack (cast glow, defend stance, victory). The node origin is the
## feet point; `home` is its slot position.
##
## Async use (BattlePresenter): `start_logical(anim)`, then `await wait_hit()` to show damage on
## the hit frame, then `await wait_finished()`. In `instant` mode nothing animates and every wait
## returns at once (headless tests).

signal hit_frame_reached
signal logical_finished

## Logical animations a visual may leave unmapped: BattleSprite or the presenter stand in for them.
const STAND_INS: Array[StringName] = [&"skill", &"cast", &"defend", &"victory", &"move"]

## Distance (px) of the step towards the enemy before a melee action.
const STEP_DISTANCE: float = 120.0
const STEP_SECONDS: float = 0.22
## Knockback (px) and duration when hit.
const KNOCKBACK: float = 12.0
const KNOCKBACK_SECONDS: float = 0.08
## White flash on a hit: brightness multiplier and fade time.
const FLASH_BRIGHTNESS: float = 2.6
const FLASH_SECONDS: float = 0.15
## Defend stand-in: blue-steel tint, small step back.
const DEFEND_TINT: Color = Color(0.72, 0.82, 1.0)
const DEFEND_STEP_BACK: float = 16.0
## Cast stand-in: glow pulse duration (the colour comes from the element).
const GLOW_SECONDS: float = 0.5
const GLOW_BRIGHTNESS: float = 1.8
## Fallen party members stay on the last death frame, desaturated; enemies fade out.
const FALLEN_TINT: Color = Color(0.5, 0.5, 0.55)
const DEATH_FADE_SECONDS: float = 0.6
## Victory stand-in: the hero rises slightly on the spot.
const VICTORY_RAISE: float = 8.0
const VICTORY_SECONDS: float = 0.4
## Enemy HP bar gap above the head (px).
const HP_BAR_GAP: float = 16.0
## Height used when the combatant has no visual (fixtures).
const DEFAULT_HEIGHT: float = 150.0

var combatant: Combatant
var visual: CombatantVisual
## Slot position (feet), set by `setup`.
var home: Vector2 = Vector2.ZERO
## Skip all animation and timing (tests).
var instant: bool = false

var _playing: StringName = &""
var _hit_pending: bool = false
var _hit_frame: int = 0
var _last_frame: int = -1
var _defending: bool = false
var _fallen: bool = false
var _base_modulate: Color = Color.WHITE

@onready var body: AnimatedSprite2D = %Body
@onready var shadow: Sprite2D = %Shadow
@onready var hp_bar: StatBar = %HpBar


func _ready() -> void:
	body.frame_changed.connect(_on_frame_changed)
	body.animation_finished.connect(_on_animation_finished)


## Binds the combatant and its visual (null = no sprite, e.g. fixtures) and stands on `slot`.
func setup(who: Combatant, look: CombatantVisual, slot: Vector2) -> void:
	combatant = who
	home = slot
	position = slot
	hp_bar.visible = who.side == Combatant.Team.ENEMY
	hp_bar.set_values(who.hp, who.max_hp())
	set_visual(look)


## Switches to another visual (a boss's second form keeps the same feet point).
func set_visual(look: CombatantVisual) -> void:
	visual = look
	var scale_factor: float = look.battle_scale if look != null else 1.0
	body.scale = Vector2.ONE * scale_factor
	body.offset = look.offset if look != null else Vector2.ZERO
	shadow.scale = Vector2.ONE * scale_factor
	hp_bar.position = Vector2(-hp_bar.custom_minimum_size.x / 2.0, -height() - HP_BAR_GAP - hp_bar.custom_minimum_size.y)
	_playing = &""
	_hit_pending = false
	rest()


## Visible height above the feet, in battlefield px.
func height() -> float:
	if visual == null:
		return DEFAULT_HEIGHT
	return visual.height * visual.battle_scale


## Top of the head in canvas coordinates (popups, target cursor).
func head_position() -> Vector2:
	return global_position + Vector2(0, -height())


## +1 when facing right (party), -1 when facing left (enemies).
func facing_sign() -> float:
	if visual != null:
		return 1.0 if visual.facing == &"E" else -1.0
	return 1.0 if combatant != null and combatant.side == Combatant.Team.PARTY else -1.0


func has_logical(anim: StringName) -> bool:
	return visual != null and visual.has_animation(anim)


func is_playing() -> bool:
	return _playing != &""


## Starts one-shot logical animation `anim`. Returns false (and plays nothing) when the visual
## has no such animation; the caller then uses a stand-in.
func start_logical(anim: StringName) -> bool:
	if not has_logical(anim):
		return false
	_playing = anim
	_hit_pending = true
	_hit_frame = visual.hit_frame_for(anim)
	_last_frame = visual.last_frames.get(anim, -1) as int
	if instant:
		_hit_pending = false
		_finish()
		return true
	_show(anim)
	return true


## Waits for the hit frame of the animation in progress (returns at once if there is none).
func wait_hit() -> void:
	if _hit_pending and not instant:
		await hit_frame_reached


## Waits for the one-shot animation in progress to end.
func wait_finished() -> void:
	if _playing != &"" and not instant:
		await logical_finished


## Plays `anim` to its end (false if the visual lacks it).
func play_logical(anim: StringName) -> bool:
	if not start_logical(anim):
		return false
	await wait_finished()
	return true


## Back to the resting pose: idle, the defend stance, or the fallen pose.
func rest() -> void:
	if body == null:
		return
	if _fallen:
		return
	if _defending:
		_hold_first_frame(&"idle")
		return
	var idle: StringName = resting_anim()
	if has_logical(idle) and not instant:
		_show(idle)
	elif has_logical(idle):
		body.sprite_frames = visual.frames_for(idle)
		body.animation = visual.animation_for(idle)


## The animation `rest()` shows: a status's `rest_anim` (Staggered), else the idle for the
## combatant's HP (`CombatantVisual.idle_for`: injured idles), else `idle`.
func resting_anim() -> StringName:
	if visual == null:
		return &"idle"
	if combatant != null:
		for status: ActiveStatus in combatant.statuses:
			if status.data.rest_anim != &"" and has_logical(status.data.rest_anim):
				return status.data.rest_anim
		return visual.idle_for(combatant.hp_ratio())
	return &"idle"


## Runs towards the enemy side (melee wind-up).
func step_forward() -> void:
	if has_logical(&"move") and not instant:
		_show(&"move")
	await _move_to(home + Vector2(STEP_DISTANCE * facing_sign(), 0), STEP_SECONDS)
	rest()


## Returns to the slot.
func step_back() -> void:
	await _move_to(home, STEP_SECONDS)
	rest()


## Hit reaction: white flash, knockback and the hurt animation (unless the hit was fatal).
func hurt(fatal: bool = false) -> void:
	flash()
	var back: Vector2 = Vector2(-KNOCKBACK * facing_sign(), 0)
	if not fatal and not _defending and has_logical(&"hurt"):
		start_logical(&"hurt")
	await _move_to(position + back, KNOCKBACK_SECONDS)
	await _move_to(_rest_position(), KNOCKBACK_SECONDS)
	await wait_finished()


func flash() -> void:
	if instant:
		return
	body.self_modulate = Color(FLASH_BRIGHTNESS, FLASH_BRIGHTNESS, FLASH_BRIGHTNESS)
	create_tween().tween_property(body, ^"self_modulate", _base_modulate, FLASH_SECONDS)


## Cast stand-in: a coloured glow pulse (played alongside the `cast` animation if any).
func glow(color: Color) -> void:
	if instant:
		return
	var bright: Color = Color(color.r * GLOW_BRIGHTNESS, color.g * GLOW_BRIGHTNESS, color.b * GLOW_BRIGHTNESS)
	var tween: Tween = create_tween()
	tween.tween_property(body, ^"self_modulate", bright, GLOW_SECONDS / 2.0)
	tween.tween_property(body, ^"self_modulate", _base_modulate, GLOW_SECONDS / 2.0)
	await tween.finished


## Defend stand-in: hold idle frame 0, blue-steel tint, step back a little. Off restores.
func set_defending(on: bool) -> void:
	if on == _defending or _fallen:
		return
	_defending = on
	_base_modulate = DEFEND_TINT if on else Color.WHITE
	body.self_modulate = _base_modulate
	await _move_to(_rest_position(), STEP_SECONDS)
	rest()


func is_defending() -> bool:
	return _defending


## Death: the death animation, then enemies fade out and party members stay down, desaturated.
func die() -> void:
	_defending = false
	_base_modulate = Color.WHITE
	await wait_finished()
	if has_logical(&"death") and not instant:
		_show(&"death")
		await body.animation_finished
	_fallen = true
	hp_bar.visible = false
	if combatant != null and combatant.side == Combatant.Team.ENEMY:
		if instant:
			modulate.a = 0.0
		else:
			var tween: Tween = create_tween()
			tween.tween_property(self, ^"modulate:a", 0.0, DEATH_FADE_SECONDS)
			await tween.finished
	else:
		body.self_modulate = FALLEN_TINT
		body.pause()


func is_fallen() -> bool:
	return _fallen


## Back on their feet (Revive).
func revive() -> void:
	_fallen = false
	modulate.a = 1.0
	body.self_modulate = Color.WHITE
	hp_bar.visible = combatant != null and combatant.side == Combatant.Team.ENEMY
	rest()


## Victory stand-in: idle and a slight raise.
func victory_pose() -> void:
	if _fallen:
		return
	_defending = false
	_base_modulate = Color.WHITE
	body.self_modulate = Color.WHITE
	rest()
	await _move_to(home + Vector2(0, -VICTORY_RAISE), VICTORY_SECONDS)


## Runs off the field away from the enemy (successful escape).
func run_away(distance: float, seconds: float) -> void:
	if not _fallen:
		if visual != null and not instant:
			var away: StringName = StringName("run_%s" % ("W" if facing_sign() > 0.0 else "E"))
			if visual.sprite_frames.has_animation(away):
				body.sprite_frames = visual.sprite_frames
				body.play(away)
		await _move_to(home - Vector2(distance * facing_sign(), 0), seconds)


func set_hp_shown(hp: int, max_hp: int, animate: bool) -> void:
	hp_bar.set_values(hp, max_hp, animate and not instant)


func _show(anim: StringName) -> void:
	body.sprite_frames = visual.frames_for(anim)
	body.play(visual.animation_for(anim))


func _hold_first_frame(anim: StringName) -> void:
	if not has_logical(anim):
		return
	body.sprite_frames = visual.frames_for(anim)
	body.animation = visual.animation_for(anim)
	body.frame = 0
	body.pause()


func _rest_position() -> Vector2:
	return home - Vector2(DEFEND_STEP_BACK * facing_sign(), 0) if _defending else home


func _move_to(target: Vector2, seconds: float) -> void:
	if instant or not is_inside_tree():
		position = target
		return
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"position", target, seconds)
	await tween.finished


func _on_frame_changed() -> void:
	if _playing == &"":
		return
	if _hit_pending and body.frame >= _hit_frame:
		_hit_pending = false
		hit_frame_reached.emit()
	if _last_frame >= 0 and body.frame >= _last_frame:
		body.pause()
		_finish()


func _on_animation_finished() -> void:
	if _playing != &"":
		_finish()


func _finish() -> void:
	if _hit_pending:
		_hit_pending = false
		hit_frame_reached.emit()
	_playing = &""
	logical_finished.emit()
	if not _fallen:
		rest()
