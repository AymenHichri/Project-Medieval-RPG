class_name BattleFx
extends AnimatedSprite2D
## A one-shot effect on the battlefield (FxSpec): plays its animation once and frees itself.
## A looping animation is stopped after one cycle.


## Spawns `spec` under `parent` at `at` (canvas position). `mirror` flips it horizontally.
## Returns null when the spec is unusable.
static func spawn(parent: Node, spec: FxSpec, at: Vector2, mirror: bool = false) -> BattleFx:
	if parent == null or spec == null or not spec.is_valid():
		return null
	var fx: BattleFx = BattleFx.new()
	fx.sprite_frames = spec.frames
	fx.position = at + Vector2(-spec.offset.x if mirror else spec.offset.x, spec.offset.y)
	fx.scale = Vector2(-spec.scale if mirror else spec.scale, spec.scale)
	fx.modulate = spec.tint
	fx.speed_scale = spec.speed
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(fx)
	fx.animation_finished.connect(fx.queue_free)
	fx.animation_looped.connect(fx.queue_free)
	fx.play(spec.animation)
	return fx
