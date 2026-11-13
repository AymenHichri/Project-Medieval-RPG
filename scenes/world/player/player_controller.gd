class_name PlayerController
extends CharacterBody2D
## Free 8-direction exploration movement (PROJECT_PLAN.md §6.1, decision D4).
## Picks `walk_<DIR>` / `idle_<DIR>` from the vendor Knight SpriteFrames using 45° sectors
## around the last non-zero input. The node origin is the feet point (Y-sort origin).
## Field movement uses the vendor `run_*` cycle: its legs alternate with a full stride, while
## the vendor `walk_*` cycle mostly moves one leg and reads as gliding.

## Direction names in sector order, clockwise from east (screen y points down).
const DIRECTIONS: Array[StringName] = [&"E", &"SE", &"S", &"SW", &"W", &"NW", &"N", &"NE"]
## Width of one direction sector in radians (360° / 8).
const SECTOR: float = TAU / 8.0
## Inputs shorter than this count as "no input" (keeps the last facing).
const MIN_INPUT_LENGTH: float = 0.01

## Animation used while moving (`<name>_<DIR>`).
const MOVE_ANIMATION: StringName = &"run"
## Ground speed (px/s) at which the move cycle plays at 1× without foot sliding, measured from
## the planted foot in the `run_*` frames at their 24 fps.
const MOVE_CYCLE_GROUND_SPEED: float = 200.0

## Walking speed in world pixels per second (full-scale art).
@export var walk_speed: float = 220.0
## Playback speed of the idle (breathing) loop; the vendor speed reads as panting.
@export_range(0.1, 2.0, 0.05) var idle_animation_speed: float = 0.5
## When false the player ignores movement input (dialogue, fades, menus).
@export var input_enabled: bool = true:
	set(value):
		input_enabled = value
		if not value:
			velocity = Vector2.ZERO

## Current facing: one of DIRECTIONS.
var facing: StringName = &"S"

@onready var sprite: AnimatedSprite2D = %Sprite
@onready var camera: FollowCamera = %Camera
@onready var probe: InteractionProbe = %InteractionProbe


func _ready() -> void:
	sprite.speed_scale = idle_animation_speed
	_play_animation(&"idle")


func _physics_process(_delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	if can_act():
		input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	move(input)


## Moves with the given input vector (length 0..1) and updates the animation.
## Split out of `_physics_process` so tests and cutscenes can drive the player.
func move(input: Vector2) -> void:
	var moving: bool = input.length() >= MIN_INPUT_LENGTH
	facing = dir_from_vector(input, facing)
	velocity = input.limit_length(1.0) * walk_speed if moving else Vector2.ZERO
	move_and_slide()
	_play_animation(MOVE_ANIMATION if moving else &"idle")
	# Legs follow the real ground speed (slower when sliding along a wall).
	if moving:
		sprite.speed_scale = maxf(get_real_velocity().length(), walk_speed * 0.5) / MOVE_CYCLE_GROUND_SPEED
	else:
		sprite.speed_scale = idle_animation_speed


## True when the player takes movement and interaction input: not during fades
## (`input_enabled` is false) or while a dialogue is open.
func can_act() -> bool:
	return input_enabled and not DialogueManager.is_active


## Turns the player to face a direction name (e.g. from a SpawnPoint).
func face(direction: StringName) -> void:
	if direction in DIRECTIONS:
		facing = direction
		_play_animation(&"idle")


## Maps a vector to one of 8 direction names using 45° sectors centred on each direction.
## A zero (or near-zero) vector returns `fallback`, i.e. keeps the last direction.
static func dir_from_vector(v: Vector2, fallback: StringName = &"S") -> StringName:
	if v.length() < MIN_INPUT_LENGTH:
		return fallback
	var sector: int = roundi(v.angle() / SECTOR)
	return DIRECTIONS[posmod(sector, DIRECTIONS.size())]


## Unit vector of a direction name (inverse of `dir_from_vector`); unknown names give ZERO.
static func vector_from_dir(direction: StringName) -> Vector2:
	var index: int = DIRECTIONS.find(direction)
	if index < 0:
		return Vector2.ZERO
	return Vector2.RIGHT.rotated(index * SECTOR)


func _play_animation(action: StringName) -> void:
	var animation: StringName = StringName("%s_%s" % [action, facing])
	if sprite.animation == animation and sprite.is_playing():
		return
	# Keep the stride when only the direction changes, so turning doesn't restart the cycle.
	var keep_phase: bool = String(sprite.animation).begins_with(String(action) + "_")
	var frame: int = sprite.frame
	var progress: float = sprite.frame_progress
	sprite.play(animation)
	if keep_phase and frame < sprite.sprite_frames.get_frame_count(animation):
		sprite.set_frame_and_progress(frame, progress)
