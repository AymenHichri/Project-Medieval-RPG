shader_type canvas_item;
// SNOW COVER (snow settling on roofs, walls, trees, props and grounds)
// Snow gathers on the tops of the art first (roof ridges, wall tops, branch and leaf tops, the upper side of every bump)
// and spreads as `amount` rises; the rest of the scene takes a cold winter light. Tween `amount` 0 -> 1 for snow settling,
// back to 0 for a thaw. With a baked snowy version of the same piece (use_snow_texture), that version is revealed instead,
// top first with a ragged edge. Works without extra files; a normal map (use_normal_map) places the snow more precisely.
// For sprite sheets add scripts/sprite_shader_region.gd as a child (region_uv).
// 1.2.1: ground patches are placed in world space (ground_world_space), so neighbouring ground tiles and TileMapLayer cells
// join up into one snowfield while the snow builds up, instead of showing square tile edges.

uniform float amount : hint_range(0.0, 1.0) = 0.7;              // 0 = no snow, 1 = heavy snow
uniform vec4 snow_color : source_color = vec4(0.95, 0.97, 1.0, 1.0);
uniform vec4 snow_shadow : source_color = vec4(0.66, 0.74, 0.88, 1.0);
uniform float cap_px : hint_range(0.0, 60.0) = 24.0;            // thickness of the snow cap on top edges at amount 1
uniform float up_threshold : hint_range(-0.5, 0.9) = 0.18;      // how upward a bump must face to hold snow
uniform float coverage : hint_range(0.0, 1.0) = 0.6;            // how much of the art fills up at amount 1
uniform float top_bias : hint_range(0.0, 1.0) = 0.7;            // snow gathers on the upper part of a piece first (roofs, crowns)
uniform float ragged : hint_range(0.0, 1.0) = 0.6;              // ragged, patchy snow edges
uniform float noise_px : hint_range(2.0, 64.0) = 9.0;           // size of the patches
uniform float cold_light : hint_range(0.0, 1.0) = 0.25;         // cool, paler light on everything not covered
uniform vec2 light_from = vec2(-0.55, 0.75);
uniform bool use_normal_map = false;
uniform sampler2D normal_map : hint_normal, filter_linear;
uniform float bump_from_art : hint_range(0.0, 12.0) = 2.0;
uniform bool ground_mode = false;                              // floors, streets, grass: snow lies in soft patches that join up
uniform float ground_patch_px : hint_range(8.0, 256.0) = 60.0;
uniform bool ground_world_space = true;                         // ground patches follow world position (tiles join up)
uniform bool use_snow_texture = false;
uniform sampler2D snow_texture : filter_linear;                 // the same piece with snow already on it
uniform vec4 region_uv = vec4(0.0, 0.0, 1.0, 1.0);

varying vec4 tint;
varying vec2 world_pos;

void vertex() {
	tint = COLOR;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
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

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec2 l = (UV - region_uv.xy) / region_uv.zw;
	vec2 p = l * region_uv.zw / px;                                   // texture pixels inside the frame
	float nz = vnoise(p / noise_px) * 0.65 + vnoise(p / (noise_px * 0.37)) * 0.35;
	vec3 n;
	if (use_normal_map) {
		n = normalize(texture(normal_map, l).rgb * 2.0 - 1.0);
	} else {
		float lx = lum(texture(TEXTURE, UV + vec2(px.x, 0.0)).rgb) - lum(texture(TEXTURE, UV - vec2(px.x, 0.0)).rgb);
		float ly = lum(texture(TEXTURE, UV - vec2(0.0, px.y)).rgb) - lum(texture(TEXTURE, UV + vec2(0.0, px.y)).rgb);
		n = normalize(vec3(-lx * bump_from_art, -ly * bump_from_art, 1.0));
	}
	float a = amount;
	vec3 base = tex.rgb * tint.rgb;
	vec3 cold = mix(base, vec3(lum(base)) * vec3(0.86, 0.92, 1.0) + 0.06, cold_light * a);
	// Distance to the nearest transparent pixel straight above (top edges of the silhouette).
	float cap = cap_px * a * (1.0 - ragged * 0.6 + ragged * 0.6 * nz);
	float top = 0.0;
	if (cap > 0.5) {
		for (int i = 1; i <= 10; i++) {
			float d = cap * float(i) / 10.0;
			vec2 uv = UV - vec2(0.0, d * px.y);
			float inside = step(region_uv.y, uv.y);
			float above = texture(TEXTURE, uv).a * inside;
			if (above < 0.35) {
				top = max(top, 1.0 - float(i - 1) / 10.0);
				break;
			}
		}
	}
	// Where snow lands first: upward-facing bumps, the upper part of the piece (roofs, crowns) and random patches.
	float field = (nz - 0.5) * ragged * 0.7 + (1.0 - l.y) * top_bias + clamp(n.y - up_threshold, -0.3, 0.6) * 0.9;
	float thresh = 1.15 - coverage * a * 1.6;
	float fill = smoothstep(thresh, thresh + 0.12, field);
	float snow = clamp(max(top, fill), 0.0, 1.0) * step(0.02, a);
	if (ground_mode) {
		vec2 gp = (ground_world_space ? world_pos : p) / ground_patch_px;
		float gn = vnoise(gp) * 0.6 + vnoise(gp * 2.3) * 0.25 + vnoise(gp * 7.0) * 0.15;
		float gt = 1.02 - a * 1.0;
		snow = smoothstep(gt - 0.12, gt + 0.18, gn) * step(0.02, a) * 0.9;
		n = vec3(0.0, 0.0, 1.0);
	}
	vec3 L = normalize(vec3(light_from, 0.9));
	float lit = clamp(0.55 + 0.6 * dot(n, L), 0.0, 1.0);
	vec3 snow_rgb = mix(snow_shadow.rgb, snow_color.rgb, lit);
	if (ground_mode) {
		snow_rgb *= 0.8 + 0.45 * lum(base);                           // the ground's own texture still shows through the snow
	}
	vec3 col = mix(cold, snow_rgb, snow);
	if (use_snow_texture) {
		vec4 st = texture(snow_texture, l);
		float order = (1.0 - l.y) * 0.45 + nz * 0.55;                 // tops and patches first
		float reveal = smoothstep(1.0 - a * 1.15, 1.0 - a * 1.15 + 0.12, order);
		col = mix(cold, st.rgb * tint.rgb, reveal * st.a);
	}
	COLOR = vec4(col, tex.a * tint.a);
}
