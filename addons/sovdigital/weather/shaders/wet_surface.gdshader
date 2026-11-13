shader_type canvas_item;
// WET SURFACE (rain on roofs, walls, streets, trees, props and characters)
// Makes the art look rain-soaked: darker and richer colours, a glossy sheen on the raised, upward-facing parts,
// a cool sky reflection, and optional water running down in thin streaks. Tween `wetness` 0 -> 1 when rain starts
// and back to 0 when it dries. Works without extra files (it reads the bumps from the art's own shading);
// a normal map (use_normal_map) gives a crisper sheen. Tiles: put the material on the TileMapLayer.
// For sprite sheets add scripts/sprite_shader_region.gd as a child (region_uv).

uniform float wetness : hint_range(0.0, 1.0) = 1.0;             // 0 = dry, 1 = soaked
uniform float darken : hint_range(0.0, 0.8) = 0.38;             // wet materials get darker
uniform float saturation : hint_range(0.0, 1.0) = 0.3;         // ... and their colours richer
uniform float gloss : hint_range(0.0, 2.0) = 0.45;              // strength of the wet sheen
uniform float gloss_tightness : hint_range(2.0, 64.0) = 20.0;   // higher = smaller, sharper highlights
uniform vec2 light_from = vec2(-0.55, 0.75);                    // where the light comes from (x right, y up): upper left
uniform vec4 sky_color : source_color = vec4(0.62, 0.70, 0.80, 1.0); // colour reflected on upward faces
uniform float sky_reflection : hint_range(0.0, 1.0) = 0.28;
uniform bool use_normal_map = false;
uniform sampler2D normal_map : hint_normal, filter_linear;      // same layout as the texture (green = up)
uniform float bump_from_art : hint_range(0.0, 12.0) = 1.5;      // bump strength read from the art when no normal map
uniform bool ground_mode = false;                              // floors, streets, grass: the whole surface faces the sky
uniform float puddles : hint_range(0.0, 1.0) = 0.35;            // ground_mode: shiny standing-water patches
uniform float puddle_size_px : hint_range(8.0, 256.0) = 70.0;
uniform float drips : hint_range(0.0, 1.0) = 0.0;               // water running down in thin streaks
uniform float drip_speed : hint_range(0.0, 3.0) = 0.6;
uniform float drip_spacing_px : hint_range(2.0, 40.0) = 9.0;
uniform vec4 region_uv = vec4(0.0, 0.0, 1.0, 1.0);

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

float lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

float hash(float n) {
	return fract(sin(n * 91.3458) * 47453.5453);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 n;
	if (use_normal_map) {
		vec2 l = (UV - region_uv.xy) / region_uv.zw;
		n = normalize(texture(normal_map, l).rgb * 2.0 - 1.0);
	} else {
		vec2 px = TEXTURE_PIXEL_SIZE * 2.0;   // read the bumps 2 px apart: smoother than single pixels
		float lx = lum(texture(TEXTURE, UV + vec2(px.x, 0.0)).rgb) - lum(texture(TEXTURE, UV - vec2(px.x, 0.0)).rgb);
		float ly = lum(texture(TEXTURE, UV - vec2(0.0, px.y)).rgb) - lum(texture(TEXTURE, UV + vec2(0.0, px.y)).rgb);
		float b = ground_mode ? bump_from_art * 0.5 : bump_from_art;
		n = normalize(vec3(-lx * b, -ly * b, 1.0));
	}
	float w = wetness;
	vec3 base = tex.rgb * tint.rgb;
	float g = lum(base);
	vec3 rich = mix(vec3(g), base, 1.0 + saturation * w);
	vec3 col = rich * (1.0 - darken * w);
	col = mix(col, col * col * 1.6, 0.25 * w);                     // deeper darks in the gaps
	// Sheen: a soft specular highlight from the light, strongest on bumps that face up toward the sky.
	vec3 L = normalize(vec3(light_from, 0.9));
	vec3 H = normalize(L + vec3(0.0, 0.35, 1.0));
	// Only bumps turned toward the light glint; a flat face gets none (so the art never washes out).
	float spec = max(pow(max(dot(n, H), 0.0), gloss_tightness) - pow(H.z, gloss_tightness), 0.0) * 1.5;
	float up = ground_mode ? 1.0 : clamp(0.5 + n.y * 2.0, 0.0, 1.0);
	col += vec3(1.0, 0.98, 0.94) * spec * gloss * w * (0.4 + 0.6 * up);
	col = mix(col, sky_color.rgb * (0.6 + 0.4 * g), sky_reflection * w * up * 0.6);
	if (ground_mode && puddles > 0.0) {
		vec2 pp = (UV - region_uv.xy) / TEXTURE_PIXEL_SIZE / puddle_size_px;
		float pn = vnoise(pp) * 0.7 + vnoise(pp * 2.7) * 0.3;
		float pud = smoothstep(1.0 - puddles * 0.75, 1.0 - puddles * 0.75 + 0.08, pn) * w;
		vec3 water = mix(col * 0.55, sky_color.rgb * 0.75, 0.45);
		col = mix(col, water, pud * 0.85);
	}
	// Drips: thin bright streaks running down, each column with its own timing.
	if (drips > 0.0) {
		vec2 p = (UV - region_uv.xy) / TEXTURE_PIXEL_SIZE;
		float colx = floor(p.x / drip_spacing_px);
		float on = step(0.55, hash(colx));
		float x_in = abs(fract(p.x / drip_spacing_px) - 0.5);
		float len = 18.0 + 30.0 * hash(colx + 7.0);
		float y = fract(p.y / len - TIME * drip_speed * (0.6 + 0.8 * hash(colx + 3.0)) + hash(colx + 11.0));
		float streak = on * (1.0 - smoothstep(0.04, 0.12, x_in)) * smoothstep(0.0, 0.25, y) * (1.0 - smoothstep(0.55, 1.0, y));
		col += vec3(0.85, 0.9, 1.0) * streak * drips * w * 0.35;
	}
	COLOR = vec4(col, tex.a * tint.a);
}
