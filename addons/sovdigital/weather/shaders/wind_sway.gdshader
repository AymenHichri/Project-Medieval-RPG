shader_type canvas_item;
// WIND SWAY (trees, bushes, grass, reeds, flowers, hanging moss)
// The plant bends in the wind while its base stays planted: the top moves most, the roots not at all.
// Every plant gets its own rhythm from its position, and slow gusts roll across the map.
// Use: put a ShaderMaterial with this shader on a Sprite2D / AnimatedSprite2D / tile. The quad is widened by
// margin_px so the swaying top is never cut off. For sprite sheets (AtlasTexture SpriteFrames) add
// scripts/sprite_shader_region.gd as a child so region_uv follows the current frame.

uniform float sway_px : hint_range(0.0, 48.0) = 6.0;        // how far the top moves, in texture pixels
uniform float bend : hint_range(0.5, 4.0) = 1.6;            // 1 = straight lean; 2+ = the tips bend more than the middle
uniform float rooted : hint_range(0.0, 0.9) = 0.12;         // lowest share of the height that never moves (roots, trunk base)
uniform float speed : hint_range(0.0, 4.0) = 0.5;           // sways per second
uniform float wind_direction : hint_range(-1.0, 1.0) = 1.0; // +1 wind blows to the right, -1 to the left
uniform float lean : hint_range(0.0, 1.0) = 0.3;            // steady lean with the wind (0 = swings evenly around upright)
uniform float gust_strength : hint_range(0.0, 1.0) = 0.35;  // slow gusts that roll across the map
uniform float gust_speed : hint_range(0.0, 1.0) = 0.15;     // gust waves per second
uniform float gust_length_px : hint_range(100.0, 4000.0) = 900.0; // distance between gusts on the map
uniform float flutter_px : hint_range(0.0, 6.0) = 0.6;      // small leaf / blade shimmer on top of the sway
uniform float flutter_scale_px : hint_range(4.0, 120.0) = 26.0;
uniform float flutter_speed : hint_range(0.0, 8.0) = 2.5;
uniform float phase_offset = 0.0;                           // extra rhythm offset for this plant
uniform float margin_px : hint_range(0.0, 64.0) = 16.0;     // widen the drawn quad left and right by this many pixels
uniform vec4 region_uv = vec4(0.0, 0.0, 1.0, 1.0);          // set by sprite_shader_region.gd

varying vec2 world_pos;
varying float plant_phase;
varying vec4 tint;

void vertex() {
	tint = COLOR;
	// Widen the quad so the top can move outside the original rectangle.
	float side = UV.x < region_uv.x + region_uv.z * 0.5 ? -1.0 : 1.0;
	VERTEX.x += side * margin_px;
	UV.x += side * margin_px * TEXTURE_PIXEL_SIZE.x;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	vec2 origin = MODEL_MATRIX[3].xy;
	plant_phase = fract(sin(dot(origin, vec2(12.9898, 78.233))) * 43758.5453) * 6.2832 + phase_offset;
}

void fragment() {
	float v = clamp((UV.y - region_uv.y) / region_uv.w, 0.0, 1.0);   // 0 top .. 1 bottom
	float h = clamp(((1.0 - v) - rooted) / max(1.0 - rooted, 0.001), 0.0, 1.0);
	float w = pow(h, bend);
	float gust = gust_strength * (0.5 + 0.5 * sin(TIME * gust_speed * 6.2832 - world_pos.x / gust_length_px * 6.2832));
	float swing = sin(TIME * speed * 6.2832 + plant_phase) + 0.25 * sin(TIME * speed * 15.7 + plant_phase * 1.7);
	float dx = sway_px * w * (1.0 + gust) * (lean * wind_direction + (1.0 - 0.5 * lean) * swing * 0.8);
	vec2 q = world_pos / flutter_scale_px;
	float fl = sin(q.x * 1.7 + TIME * flutter_speed + plant_phase) * sin(q.y * 2.3 - TIME * flutter_speed * 1.31);
	dx += flutter_px * h * fl;
	float dy = -0.5 * dx * dx / max(region_uv.w / TEXTURE_PIXEL_SIZE.y, 1.0) * w;   // a leaning top dips a little
	vec2 uv = UV - vec2(dx * TEXTURE_PIXEL_SIZE.x, dy * TEXTURE_PIXEL_SIZE.y);
	float inside = step(region_uv.x, uv.x) * step(uv.x, region_uv.x + region_uv.z)
		* step(region_uv.y, uv.y) * step(uv.y, region_uv.y + region_uv.w);
	vec4 c = texture(TEXTURE, uv);
	COLOR = c * tint * inside;
}
