class_name FxSpec
extends Resource
## A one-shot visual effect (vendor SovDigital effect SpriteFrames): which animation, where on the
## target, how big, and an optional tint. Played by BattlePresenter through BattleFx; read-only.

enum Anchor {
	## The middle of the target's body (hits, impacts).
	BODY,
	## The target's feet (ground bursts).
	FEET,
	## Above the head (auras, falling effects).
	HEAD,
}

@export var frames: SpriteFrames
## Animation in `frames` (vendor effects use "effect", "impact", "cast", ...).
@export var animation: StringName = &"effect"
@export var anchor: Anchor = Anchor.BODY
## Extra offset from the anchor (px, before mirroring for left-facing targets).
@export var offset: Vector2 = Vector2.ZERO
@export_range(0.1, 4.0, 0.05) var scale: float = 1.0
## Multiplied into the effect's colours (white = as drawn).
@export var tint: Color = Color.WHITE
## Playback speed multiplier.
@export_range(0.1, 4.0, 0.05) var speed: float = 1.0
## Mirror the effect when the target faces left (directional splashes).
@export var mirror_for_facing: bool = false


func is_valid() -> bool:
	return frames != null and frames.has_animation(animation)
