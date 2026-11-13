extends Node
## Keeps a shader's `region_uv` uniform in step with the frame an AnimatedSprite2D (or Sprite2D) is showing.
##
## Why: SpriteFrames made from sprite sheets use AtlasTexture regions, so in the shader UV covers the whole
## sheet. Shaders that look at neighbouring pixels (outline, glow, silhouette, status edge) or use the frame
## height (spawn-in, dissolve vertical_bias, ghost waver) need the current frame's rectangle.
##
## Use: add this node as a child of the sprite. It updates on every frame and animation change.
## Each sprite needs its own ShaderMaterial (region_uv is per sprite); make_material_unique does that for you.

@export var target: CanvasItem                 ## the sprite; empty = the parent node
@export var make_material_unique := true       ## duplicate a shared material on start so sprites don't fight

func _ready() -> void:
	if target == null:
		target = get_parent() as CanvasItem
	if target == null:
		push_warning("SpriteShaderRegion: no sprite to follow")
		return
	if make_material_unique and target.material is ShaderMaterial:
		target.material = target.material.duplicate()
	if target is AnimatedSprite2D:
		target.frame_changed.connect(update_region)
		target.animation_changed.connect(update_region)
		target.sprite_frames_changed.connect(update_region)
	elif target is Sprite2D:
		target.texture_changed.connect(update_region)
		target.frame_changed.connect(update_region)
	update_region()


func _process(_delta: float) -> void:
	# Sprite2D with region_enabled or manual frame changes: cheap check every frame.
	if target is Sprite2D:
		update_region()


## Call this after you swap the material yourself.
func update_region() -> void:
	if target == null:
		target = get_parent() as CanvasItem
	if target == null:
		return
	var mat := target.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("region_uv", region_of(target))


## The current frame's rectangle inside its texture, as (x, y, w, h) in 0..1 UV.
static func region_of(sprite: CanvasItem) -> Vector4:
	var tex: Texture2D = null
	var rect := Rect2()
	if sprite is AnimatedSprite2D:
		var a := sprite as AnimatedSprite2D
		if a.sprite_frames == null or not a.sprite_frames.has_animation(a.animation):
			return Vector4(0, 0, 1, 1)
		tex = a.sprite_frames.get_frame_texture(a.animation, a.frame)
	elif sprite is Sprite2D:
		var s := sprite as Sprite2D
		tex = s.texture
		if tex != null and s.region_enabled:
			rect = s.region_rect
		elif tex != null and (s.hframes > 1 or s.vframes > 1):
			var size := tex.get_size() / Vector2(s.hframes, s.vframes)
			rect = Rect2(Vector2(s.frame_coords) * size, size)
	if tex == null:
		return Vector4(0, 0, 1, 1)
	var full := tex.get_size()
	while tex is AtlasTexture and (tex as AtlasTexture).atlas != null:
		var at := tex as AtlasTexture
		var r := at.region
		rect = Rect2(rect.position + r.position, rect.size) if rect.size != Vector2.ZERO else r
		tex = at.atlas
		full = tex.get_size()
	if rect.size == Vector2.ZERO:
		return Vector4(0, 0, 1, 1)
	return Vector4(rect.position.x / full.x, rect.position.y / full.y, rect.size.x / full.x, rect.size.y / full.y)
